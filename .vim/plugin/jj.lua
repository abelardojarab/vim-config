-- jj.lua -- Jujutsu + Critique + CloudCode for Neovim.
--
-- The counterpart to setup-jj.el / setup-cloudcode.el on the Emacs side, with
-- the same commands and the same guard rails.  Auto-sourced: ~/.config/nvim is
-- on the runtimepath, so plugin/*.lua loads without touching .vimrc.
--
--   ,jj  status      ,jl  log       ,jd  diff      ,js  show
--   ,jD  describe    ,jn  new       ,je  edit      ,jS  squash
--   ,ju  upload to Critique         ,jc  open CL   ,jp  presubmit
--   ,jo  operation log              ,jz  undo
--   ,cc  CloudCode terminal         ,ca  CloudCode question
--
-- Every read passes --ignore-working-copy and drops stderr.  jj snapshots the
-- working copy on each invocation; in a repo with large files that prints
-- kilobytes of "Refused to snapshot some files" and takes the working-copy
-- lock, so unguarded reads are slow, noisy and contend with each other.  The
-- status view snapshots once, deliberately, before rendering.
--
-- `jj piper submit` is deliberately absent.  `jj piper mail` asks twice.

if vim.g.loaded_jj_lua then
  return
end
vim.g.loaded_jj_lua = true

local M = {}

local JJ = "jj"

---------------------------------------------------------------------------
-- process plumbing
---------------------------------------------------------------------------

-- Checked per call, not at load: this config is shared across machines and
-- `executable` is a cheap PATH lookup.  Without it, every command on a machine
-- with no jj reports "Not inside a jj workspace", which sends you looking in
-- entirely the wrong place.
function M.available()
  return vim.fn.executable(JJ) == 1
end

local function require_jj()
  if not M.available() then
    vim.notify("jj is not installed on this machine", vim.log.levels.WARN)
    return false
  end
  return true
end

-- List form, so there is no shell and nothing to quote.
local function run(args, opts)
  opts = opts or {}
  if not M.available() then
    return {}, 127
  end
  local cmd = { JJ }
  if not opts.mutating then
    table.insert(cmd, "--ignore-working-copy")
  end
  vim.list_extend(cmd, args)

  local out = vim.fn.systemlist(cmd)
  local code = vim.v.shell_error
  return out, code
end

local function root()
  if not M.available() then
    return nil
  end
  local out, code = run({ "root" })
  if code ~= 0 or not out[1] then
    return nil
  end
  return vim.trim(out[1])
end

local function require_root()
  if not require_jj() then
    return nil
  end
  local r = root()
  if not r then
    vim.notify("Not inside a jj workspace: " .. vim.fn.getcwd(), vim.log.levels.ERROR)
  end
  return r
end

---------------------------------------------------------------------------
-- rendering
---------------------------------------------------------------------------

-- "CHANGEID\tDISPLAY".  Colour is left to Neovim: with --color=always jj turns
-- the ESC in a template literal into a visible U+241B, and colours the change
-- id, which has to stay plain because it is handed straight back to jj.
local LOG_TEMPLATE = table.concat({
  'change_id.shortest(8)',
  '"\\t"',
  'if(current_working_copy, "@", " ")',
  'if(conflict, "x", " ")',
  'if(empty, "o", " ")',
  'if(immutable, "#", " ")',
  '" " ++ pad_end(9, change_id.shortest(8))',
  'pad_end(14, author.timestamp().ago())',
  'pad_end(17, bookmarks.join(" "))',
  'if(description, description.first_line(), "(no description)")',
  '"\\n"',
}, " ++ ")

local function scratch(name, lines, filetype)
  local bufnr = vim.fn.bufnr(name)
  if bufnr == -1 then
    bufnr = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_name(bufnr, name)
  end
  vim.bo[bufnr].modifiable = true
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
  vim.bo[bufnr].modifiable = false
  vim.bo[bufnr].buftype = "nofile"
  vim.bo[bufnr].bufhidden = "hide"
  vim.bo[bufnr].swapfile = false
  if filetype then
    vim.bo[bufnr].filetype = filetype
  end
  local win = vim.fn.bufwinnr(bufnr)
  if win == -1 then
    vim.cmd("botright split")
    vim.api.nvim_win_set_buf(0, bufnr)
  else
    vim.cmd(win .. "wincmd w")
  end
  vim.api.nvim_win_set_cursor(0, { 1, 0 })
  return bufnr
end

---------------------------------------------------------------------------
-- status buffer
---------------------------------------------------------------------------

-- line number (1-based, in the status buffer) -> change id
local status_changes = {}

function M.status()
  local r = require_root()
  if not r then
    return
  end
  -- The one deliberate snapshot; everything below reads with
  -- --ignore-working-copy and would otherwise show stale state.
  run({ "log", "-r", "@", "-n", "1", "-T", '""' }, { mutating = true })

  local lines = { "jj: " .. r, "", "Working copy", "" }
  vim.list_extend(lines, run({ "status" }))
  vim.list_extend(lines, { "", "Log", "" })

  status_changes = {}
  local log = run({ "log", "--no-graph", "-n", "60", "-T", LOG_TEMPLATE })
  for _, line in ipairs(log) do
    local change, display = line:match("^([^\t]*)\t(.*)$")
    if change then
      table.insert(lines, display)
      -- Trimmed: this string is handed straight back to jj as a revision.
      status_changes[#lines] = vim.trim(change)
    end
  end

  local bufnr = scratch("jj://status", lines, "jjstatus")
  local function map(lhs, fn)
    vim.keymap.set("n", lhs, fn, { buffer = bufnr, silent = true, nowait = true })
  end
  map("g", M.status)
  map("q", "<cmd>close<cr>")
  map("<cr>", function() M.show(M.change_at_cursor()) end)
  map("d", function() M.diff(M.change_at_cursor()) end)
  map("D", function() M.describe(M.change_at_cursor()) end)
  map("n", function() M.new(M.change_at_cursor()) end)
  map("e", function() M.edit(M.change_at_cursor()) end)
  map("S", function() M.squash(M.change_at_cursor()) end)
  map("x", function() M.abandon(M.change_at_cursor()) end)
  map("u", function() M.upload(M.change_at_cursor()) end)
  map("c", function() M.open_cl(M.change_at_cursor()) end)
end

function M.change_at_cursor()
  local lnum = vim.api.nvim_win_get_cursor(0)[1]
  return status_changes[lnum]
end

-- Change under the cursor, else ask.  Callback style because vim.ui.input is
-- async and may be backed by a floating picker.
local function with_rev(rev, prompt, fn)
  if rev and rev ~= "" then
    return fn(rev)
  end
  vim.ui.input({ prompt = prompt or "Revision: ", default = "@" }, function(input)
    if input and input ~= "" then
      fn(input)
    end
  end)
end

local function refresh_status()
  if vim.fn.bufwinnr(vim.fn.bufnr("jj://status")) ~= -1 then
    local cur = vim.api.nvim_get_current_win()
    M.status()
    pcall(vim.api.nvim_set_current_win, cur)
  end
end

---------------------------------------------------------------------------
-- read-only views
---------------------------------------------------------------------------

local function view(name, args, ft)
  if not require_jj() then
    return
  end
  local out, code = run(args)
  if code ~= 0 then
    vim.notify("jj failed: " .. table.concat(out, "\n"), vim.log.levels.ERROR)
    return
  end
  scratch(name, out, ft)
end

function M.show(rev)
  with_rev(rev, "Show revision: ", function(r)
    view("jj://show", { "show", "-r", r }, "diff")
  end)
end

function M.diff(rev)
  with_rev(rev, "Diff revision: ", function(r)
    view("jj://diff", { "diff", "--git", "-r", r }, "diff")
  end)
end

function M.log()
  view("jj://log", { "log", "-n", "60" }, "jjlog")
end

function M.op_log()
  view("jj://oplog", { "op", "log", "-n", "40" }, "jjlog")
end

---------------------------------------------------------------------------
-- mutating commands
---------------------------------------------------------------------------

local function mutate(args, done)
  if not require_jj() then
    return
  end
  local out, code = run(args, { mutating = true })
  local msg = table.concat(out, "\n")
  if code == 0 then
    vim.notify("jj " .. args[1] .. ": " .. (msg ~= "" and msg or "ok"))
    refresh_status()
    if done then
      done(msg)
    end
  else
    vim.notify("jj " .. args[1] .. " failed: " .. msg, vim.log.levels.ERROR)
  end
end

function M.describe(rev)
  with_rev(rev, "Describe revision: ", function(r)
    local current = run({ "log", "--no-graph", "-r", r, "-T", "description" })
    vim.ui.input({ prompt = "Description: ", default = vim.trim(current[1] or "") }, function(msg)
      if msg then
        mutate({ "describe", "-r", r, "-m", msg })
      end
    end)
  end)
end

function M.new(rev)
  with_rev(rev, "New child of: ", function(r) mutate({ "new", r }) end)
end

function M.edit(rev)
  with_rev(rev, "Edit revision: ", function(r)
    -- Asks on purpose: moving @ mid-stack is where divergent change ids come
    -- from on jj-on-Piper, and it repoints blaze-bin under anything running.
    if vim.fn.confirm("jj edit " .. r .. " (moves the working copy)?", "&Yes\n&No", 2) == 1 then
      mutate({ "edit", r })
    end
  end)
end

function M.squash(rev)
  with_rev(rev, "Squash into: ", function(r)
    if vim.fn.confirm("Squash @ into " .. r .. "?", "&Yes\n&No", 2) == 1 then
      mutate({ "squash", "--into", r })
    end
  end)
end

function M.abandon(rev)
  with_rev(rev, "Abandon revision: ", function(r)
    if vim.fn.confirm("Abandon " .. r .. " -- discards the commit?", "&Yes\n&No", 2) == 1 then
      mutate({ "abandon", r })
    end
  end)
end

function M.undo()
  if vim.fn.confirm("Undo the last jj operation?", "&Yes\n&No", 2) == 1 then
    mutate({ "undo" })
  end
end

---------------------------------------------------------------------------
-- Piper / Critique
---------------------------------------------------------------------------

local function cl_of(rev)
  local out = run({ "log", "--no-graph", "-r", rev, "-T", 'bookmarks.join(" ")' })
  return (table.concat(out, " "):match("cl/(%d+)"))
end

function M.upload(rev)
  if not require_jj() then
    return
  end
  with_rev(rev, "Upload revision: ", function(r)
    vim.notify("Uploading " .. r .. " to Critique...")
    mutate({ "piper", "upload", "-r", r }, function(msg)
      local cl = msg:match("cl/(%d+)") or cl_of(r)
      if cl then
        vim.fn.setreg("+", "cl/" .. cl)
        vim.notify("Uploaded " .. r .. " -> cl/" .. cl .. " (yanked to +)")
      end
    end)
  end)
end

function M.open_cl(rev)
  with_rev(rev, "Revision: ", function(r)
    local cl = cl_of(r)
    if not cl then
      vim.notify("No CL exported for " .. r .. " yet -- upload it first", vim.log.levels.WARN)
      return
    end
    vim.ui.open("http://cl/" .. cl)
  end)
end

function M.presubmit(rev)
  with_rev(rev, "Presubmit revision: ", function(r)
    vim.cmd("botright split | terminal " .. JJ .. " piper presubmit -r " .. vim.fn.shellescape(r))
  end)
end

function M.mail(rev)
  with_rev(rev, "Mail revision: ", function(r)
    local cl = cl_of(r)
    if not cl then
      vim.notify("No CL exported for " .. r .. " yet -- upload it first", vim.log.levels.WARN)
      return
    end
    -- Twice, on purpose: mailing puts the change in front of reviewers, which
    -- is not something a mistyped key should do.
    if vim.fn.confirm("Mail cl/" .. cl .. " for review?", "&Yes\n&No", 2) ~= 1 then
      return
    end
    vim.ui.input({ prompt = "Reviewers (comma separated, empty to keep): " }, function(revs)
      if revs and revs:match("%-oncall") then
        vim.notify("Refusing to add an -oncall alias as a reviewer", vim.log.levels.ERROR)
        return
      end
      if vim.fn.confirm("Really mail cl/" .. cl .. "?", "&Yes\n&No", 2) ~= 1 then
        return
      end
      local args = { "piper", "mail", "-r", r }
      if revs and revs ~= "" then
        vim.list_extend(args, { "--reviewers", revs })
      end
      mutate(args)
    end)
  end)
end

---------------------------------------------------------------------------
-- CloudCode
---------------------------------------------------------------------------

local function cloudcode_bin()
  if vim.fn.executable("cloudcode") == 1 then
    return "cloudcode"
  end
  local p = vim.fn.expand("~/.cloudcode/bin/cloudcode")
  if vim.fn.executable(p) == 1 then
    return p
  end
  return nil
end

local function project_dir()
  return root() or vim.fn.getcwd()
end

function M.cloudcode()
  local bin = cloudcode_bin()
  if not bin then
    vim.notify("cloudcode not found", vim.log.levels.ERROR)
    return
  end
  vim.cmd("tabnew")
  vim.cmd("lcd " .. vim.fn.fnameescape(project_dir()))
  vim.fn.termopen(bin)
  vim.cmd("startinsert")
end

function M.cloudcode_ask()
  local bin = cloudcode_bin()
  if not bin then
    vim.notify("cloudcode not found", vim.log.levels.ERROR)
    return
  end
  vim.ui.input({ prompt = "Ask CloudCode: " }, function(q)
    if not q or q == "" then
      return
    end
    local lines = { "# " .. q, "" }
    local buf = scratch("cloudcode://ask", lines, "markdown")
    local job = vim.fn.jobstart({ bin, "run" }, {
      cwd = project_dir(),
      stdout_buffered = false,
      on_stdout = function(_, data)
        if not data then
          return
        end
        vim.bo[buf].modifiable = true
        vim.api.nvim_buf_set_lines(buf, -1, -1, false, data)
        vim.bo[buf].modifiable = false
      end,
      on_stderr = function(_, data)
        if data and table.concat(data, "") ~= "" then
          vim.bo[buf].modifiable = true
          vim.api.nvim_buf_set_lines(buf, -1, -1, false, data)
          vim.bo[buf].modifiable = false
        end
      end,
      on_exit = function()
        vim.notify("CloudCode finished")
      end,
    })
    if job <= 0 then
      vim.notify("could not start cloudcode", vim.log.levels.ERROR)
      return
    end
    -- The prompt goes in on stdin, not argv: past ~16kB an argument list hits
    -- ARG_MAX and the call dies with a confusing exec failure. Closing stdin
    -- is what tells `cloudcode run` the message is complete.
    vim.fn.chansend(job, q)
    vim.fn.chanclose(job, "stdin")
  end)
end

---------------------------------------------------------------------------
-- commands and keymaps
---------------------------------------------------------------------------

local cmd = vim.api.nvim_create_user_command
cmd("JJ", function() M.status() end, { desc = "jj status" })
cmd("JJLog", function() M.log() end, { desc = "jj log" })
cmd("JJDiff", function() M.diff() end, { desc = "jj diff" })
cmd("JJShow", function() M.show() end, { desc = "jj show" })
cmd("JJDescribe", function() M.describe() end, { desc = "jj describe" })
cmd("JJNew", function() M.new() end, { desc = "jj new" })
cmd("JJEdit", function() M.edit() end, { desc = "jj edit (asks)" })
cmd("JJSquash", function() M.squash() end, { desc = "jj squash" })
cmd("JJAbandon", function() M.abandon() end, { desc = "jj abandon (asks)" })
cmd("JJUndo", function() M.undo() end, { desc = "jj undo" })
cmd("JJOpLog", function() M.op_log() end, { desc = "jj operation log" })
cmd("JJUpload", function() M.upload() end, { desc = "upload to Critique" })
cmd("JJOpenCL", function() M.open_cl() end, { desc = "open the CL in Critique" })
cmd("JJPresubmit", function() M.presubmit() end, { desc = "jj piper presubmit" })
cmd("JJMail", function() M.mail() end, { desc = "jj piper mail (asks twice)" })
cmd("CloudCode", function() M.cloudcode() end, { desc = "CloudCode TUI" })
cmd("CloudCodeAsk", function() M.cloudcode_ask() end, { desc = "ask CloudCode" })

local function map(lhs, rhs, desc)
  vim.keymap.set("n", lhs, rhs, { silent = true, desc = desc })
end
map("<leader>jj", M.status, "jj status")
map("<leader>jl", M.log, "jj log")
map("<leader>jd", function() M.diff() end, "jj diff")
map("<leader>js", function() M.show() end, "jj show")
map("<leader>jD", function() M.describe() end, "jj describe")
map("<leader>jn", function() M.new() end, "jj new")
map("<leader>je", function() M.edit() end, "jj edit")
map("<leader>jS", function() M.squash() end, "jj squash")
map("<leader>ju", function() M.upload() end, "upload to Critique")
map("<leader>jc", function() M.open_cl() end, "open CL")
map("<leader>jp", function() M.presubmit() end, "presubmit")
map("<leader>jo", M.op_log, "jj operation log")
map("<leader>jz", M.undo, "jj undo")
map("<leader>cc", M.cloudcode, "CloudCode terminal")
map("<leader>ca", M.cloudcode_ask, "ask CloudCode")

_G.jj = M
return M
