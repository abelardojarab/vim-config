local utils = require("flutter-tools.utils")
local path = require("flutter-tools.utils.path")
local color = require("flutter-tools.lsp.color")

local api = vim.api
local lsp = vim.lsp
local fn = vim.fn
local fmt = string.format

local FILETYPE = "dart"
local SERVER_NAME = "dartls"

local M = {
  lsps = {},
}

local function analysis_server_snapshot_path(sdk_path)
  return path.join(sdk_path, "bin", "snapshots", "analysis_server.dart.snapshot")
end

---Merge a set of default configurations with a user's own settings
---NOTE: a user can specify a function in which case this will be used
---to determine how to merge the defaults with a user's config
---@param default table
---@param user table|function
---@return table
local function merge_config(default, user)
  if type(user) == "function" then
    return user(default)
  end
  if not user or vim.tbl_isempty(user) then
    return default
  end
  return vim.tbl_deep_extend("force", default or {}, user or {})
end

local function create_debug_log(level)
  return function(msg)
    local levels = require("flutter-tools.config").debug_levels
    if level <= levels.DEBUG then
      require("flutter-tools.ui").notify({ msg }, { level = level })
    end
  end
end

---Handle progress notifications from the server
---@param err table
---@param result table
---@param ctx table
local function handle_progress(err, result, ctx)
  -- Call the existing handler for progress so plugins can also handle the event
  -- but only whilst not editing the buffer as dartls can be spammy
  if api.nvim_get_mode().mode ~= "i" then
    vim.lsp.handlers["$/progress"](err, result, ctx)
  end
  -- NOTE: this event gets called whenever the analysis server has completed some work
  -- rather than just when the server has started.
  if result and result.value and result.value.kind == "end" then
    vim.cmd("doautocmd User FlutterToolsLspAnalysisComplete")
  end
end

---Create default config for dartls
---@param opts table
---@return table
local function get_defaults(opts)
  local flutter_sdk_path = opts.flutter_sdk
  local config = {
    init_options = {
      onlyAnalyzeProjectsWithOpenFiles = true,
      suggestFromUnimportedLibraries = true,
      closingLabels = true,
      outline = true,
      flutterOutline = true,
    },
    settings = {
      dart = {
        completeFunctionCalls = true,
        showTodos = true,
        analysisExcludedFolders = {
          path.join(flutter_sdk_path, "packages"),
          path.join(flutter_sdk_path, ".pub-cache"),
        },
      },
    },
    handlers = {
      -- TODO: can this be replaced with the initialized capability
      ["$/progress"] = handle_progress,
      ["dart/textDocument/publishClosingLabels"] = utils.lsp_handler(
        require("flutter-tools.labels").closing_tags
      ),
      ["dart/textDocument/publishOutline"] = utils.lsp_handler(
        require("flutter-tools.outline").document_outline
      ),
      ["dart/textDocument/publishFlutterOutline"] = utils.lsp_handler(
        require("flutter-tools.guides").widget_guides
      ),
      ["textDocument/documentColor"] = require("flutter-tools.lsp.color").on_document_color,
    },
    commands = {
      ["refactor.perform"] = require("flutter-tools.lsp.commands").refactor_perform,
    },
    capabilities = (function()
      local capabilities = lsp.protocol.make_client_capabilities()
      capabilities.workspace.configuration = true
      -- This setting allows document changes to be made via the lsp e.g. renaming a file when
      -- the containing class is renamed also
      -- @see: https://microsoft.github.io/language-server-protocol/specifications/specification-current/#workspaceEdit
      capabilities.workspace.workspaceEdit.documentChanges = true
      capabilities.textDocument.completion.completionItem.snippetSupport = true
      capabilities.textDocument.documentColor = {
        dynamicRegistration = true,
      }
      -- @see: https://github.com/hrsh7th/nvim-compe#how-to-use-lsp-snippet
      capabilities.textDocument.completion.completionItem.resolveSupport = {
        properties = {
          "documentation",
          "detail",
          "additionalTextEdits",
        },
      }
      return capabilities
    end)(),
  }
  return config
end

function M.restart()
  local client = utils.find(vim.lsp.get_active_clients(), function(client)
    return client.name == SERVER_NAME
  end)
  if client then
    local bufs = lsp.get_buffers_by_client_id(client.id)
    client.stop()
    local client_id = lsp.start_client(client.config)
    for _, buf in pairs(bufs) do
      lsp.buf_attach_client(buf, client_id)
    end
  end
end

local function get_dartls_client(server_name)
  server_name = server_name or SERVER_NAME
  for _, buf in pairs(vim.fn.getbufinfo({ bufloaded = true })) do
    if vim.bo[buf.bufnr].filetype == FILETYPE then
      local clients = lsp.buf_get_clients(buf.bufnr)
      for _, client in ipairs(clients) do
        if client.config.name == server_name then
          return client
        end
      end
    end
  end
end

function M.get_lsp_root_dir()
  local client = get_dartls_client()
  return client and client.config.root_dir or nil
end

-- FIXME: I'm not sure how to correctly wait till a server is ready before
-- sending this request. Ideally we would wait till the server is ready.
M.document_color = function()
  local active_clients = vim.tbl_map(function(c)
    return c.id
  end, vim.lsp.get_active_clients())
  local dartls = get_dartls_client()
  if
    dartls
    and vim.tbl_contains(active_clients, dartls.id)
    and dartls.server_capabilities.colorProvider
  then
    color.document_color()
  end
end
M.on_document_color = color.on_document_color

---This was heavily inspired by nvim-metals implementation of the attach functionality
---@return boolean
function M.attach()
  local conf = require("flutter-tools.config").get()
  local user_config = conf.lsp
  local debug_log = create_debug_log(user_config.debug)

  debug_log("attaching LSP")

  local config = utils.merge({ name = SERVER_NAME }, user_config, { "color" })

  local bufnr = api.nvim_get_current_buf()

  -- Check to see if dartls is already attached, and if so attatch
  local existing_client = get_dartls_client(config.name)
  if existing_client then
    lsp.buf_attach_client(bufnr, existing_client.id)
    return true
  end

  config.filetypes = { FILETYPE }

  local executable = require("flutter-tools.executable")
  --- TODO: if a user specifies a command we do not need to call
  --- executable.dart_sdk_root_path
  executable.get(function(paths)
    local defaults = get_defaults({ flutter_sdk = paths.flutter_sdk })
    local root_path = paths.dart_sdk
    debug_log(fmt("dart_sdk_path: %s", root_path))

    config.cmd = config.cmd
      or {
        paths.dart_bin,
        analysis_server_snapshot_path(root_path),
        "--lsp",
      }
    config.root_patterns = config.root_patterns or { ".git", "pubspec.yaml" }

    local current_dir = fn.expand("%:p:h")
    config.root_dir = path.find_root(config.root_patterns, current_dir) or current_dir

    config.capabilities = merge_config(defaults.capabilities, config.capabilities)
    config.init_options = merge_config(defaults.init_options, config.init_options)
    config.handlers = merge_config(defaults.handlers, config.handlers)
    config.settings = merge_config(defaults.settings, { dart = config.settings })
    config.commands = merge_config(defaults.commands, config.commands)

    config.on_init = function(client, _)
      return client.notify("workspace/didChangeConfiguration", { settings = config.settings })
    end

    local client_id = M.lsps[config.root_dir]
    if not client_id then
      client_id = lsp.start_client(config)
      M.lsps[config.root_dir] = client_id
    end

    lsp.buf_attach_client(bufnr, client_id)
  end)
end

return M
