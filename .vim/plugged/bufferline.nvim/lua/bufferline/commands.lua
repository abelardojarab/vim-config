---------------------------------------------------------------------------//
-- User commands
---------------------------------------------------------------------------//
local lazy = require("bufferline.lazy")
local ui = lazy.require("bufferline.ui") ---@module "bufferline.ui"
local state = lazy.require("bufferline.state") ---@module "bufferline.state"
local utils = lazy.require("bufferline.utils") ---@module "bufferline.utils"
local config = lazy.require("bufferline.config") ---@module "bufferline.config"
local groups = lazy.require("bufferline.groups") ---@module "bufferline.groups"
local sorters = lazy.require("bufferline.sorters") ---@module "bufferline.sorters"
local pick = lazy.require("bufferline.pick") ---@module "bufferline.pick"

local M = {}

local fmt = string.format
local api = vim.api

--- open the current element
---@param id number
local function open_element(id)
  if config:is_tabline() and api.nvim_tabpage_is_valid(id) then
    api.nvim_set_current_tabpage(id)
  elseif api.nvim_buf_is_valid(id) then
    api.nvim_set_current_buf(id)
  end
end

---Get the current element i.e. tab or buffer
---@return number
local function get_current_element()
  if config:is_tabline() then return api.nvim_get_current_tabpage() end
  return api.nvim_get_current_buf()
end

---Handle a user "command" which can be a string or a function
---@param command string|function
---@param id number
local function handle_user_command(command, id)
  if not command then return end
  if type(command) == "function" then
    command(id)
  elseif type(command) == "string" then
    -- Fix #574 without the scheduling the command the tabline does not refresh correctly
    vim.schedule(function()
      vim.cmd(fmt(command, id))
      ui.refresh()
    end)
  end
end

---@param position number
local function handle_group_click(position)
  groups.toggle_hidden(position)
  ui.refresh()
end

---@param id number
local function handle_close(id)
  local options = config.options
  local close = options.close_command
  handle_user_command(close, id)
end

---@param id number
local function delete_element(id)
  if config:is_tabline() then
    vim.cmd("tabclose " .. id)
  else
    handle_close(id)
  end
end

---@param id number
function M.handle_win_click(id)
  local win_id = vim.fn.bufwinid(id)
  vim.fn.win_gotoid(win_id)
end

local cmds = {
  r = "right_mouse_command",
  l = "left_mouse_command",
  m = "middle_mouse_command",
}
---Handler for each type of mouse click
---@param id number
---@param button string
local function handle_click(id, _, button)
  local options = config.options
  if id then handle_user_command(options[cmds[button]], id) end
end

---Execute an arbitrary user function on a visible by it's position buffer
---@param index number
---@param func fun(num: number, table?)
function M.exec(index, func)
  local target = state.visible_components[index]
  if target and type(func) == "function" then func(target, state.visible_components) end
end

function M.pick() pick.choose_then(open_element) end

function M.close_with_pick()
  pick.choose_then(function(id) handle_close(id) end)
end

function M.unpin_and_close(id)
  local win_id = id or vim.api.nvim_get_current_buf()
  handle_close(win_id)
  groups.remove_id_from_manual_groupings(win_id)
end

--- Open a element based on it's visible position in the list
--- unless absolute is specified in which case this will open it based on it place in the full list
--- this is significantly less helpful if you have a lot of elements open
---@param num number | string
---@param absolute boolean? whether or not to use the elements absolute position or visible positions
function M.go_to(num, absolute)
  num = type(num) == "string" and tonumber(num) or num
  local list = absolute and state.components or state.visible_components
  local element = list[num]
  if num == -1 or not element then element = list[#list] end
  open_element(element.id)
end

---@param current_state bufferline.State
---@param opts table?
---@return number?
---@return bufferline.TabElement?
function M.get_current_element_index(current_state, opts)
  opts = opts or { include_hidden = false }
  local list = opts.include_hidden and current_state.__components or current_state.components
  for index, item in ipairs(list) do
    local element = item:as_element()
    if element and element.id == get_current_element() then return index, element end
  end
end

---@param current_state bufferline.State
---@return number
local get_last_pinned_index = function(current_state)
  for index, item in ipairs(current_state.components) do
    local element = item:as_element()
    if element and not groups._is_pinned(element) then return index - 1 end
  end
  return 0
end

--- Move the buffer at index `from_index` (or current index if not specified) to position `to_index`
--- @param to_index number negative indices are accepted (counting from the right instead of the left, e.g. -1 for the last position, -2 for the second-last, etc.)
--- @param from_index number?
function M.move_to(to_index, from_index)
  local index = from_index or M.get_current_element_index(state)
  if not index then return utils.notify("Unable to find buffer to move, sorry", "warn") end
  -- Calculate next index depending on the sign of `to_index`
  local next_index = to_index > 0 and to_index or #state.components + 1 + to_index
  if next_index >= 1 and next_index <= #state.components then
    local item = state.components[index]
    local destination_buf = state.components[next_index]
    state.components[next_index] = item
    state.components[index] = destination_buf
    state.custom_sort = utils.get_ids(state.components)
    local opts = config.options
    if opts.persist_buffer_sort then utils.save_positions(state.custom_sort) end
    ui.refresh()
  end
end

--- @param direction number
function M.move(direction)
  local index, element = M.get_current_element_index(state)
  if not element then return end

  local next_index = index + direction
  if not config.options.move_wraps_at_ends or not index then return M.move_to(next_index, index) end

  local last_pinned_index = get_last_pinned_index(state)
  if groups._is_pinned(element) then
    if next_index <= 0 then
      next_index = last_pinned_index
    elseif next_index > last_pinned_index then
      next_index = 1
    end
  else
    if next_index <= last_pinned_index then
      next_index = #state.components
    elseif next_index > #state.components then
      next_index = last_pinned_index + 1
    end
  end
  M.move_to(next_index, index)
end

--- @param direction number
function M.cycle(direction)
  if vim.opt.showtabline == 0 then
    if direction > 0 then vim.cmd("bnext") end
    if direction < 0 then vim.cmd("bprev") end
  end
  local index = M.get_current_element_index(state)
  if not index then return end
  local length = #state.components
  local next_index = index + direction

  if next_index <= length and next_index >= 1 then
    next_index = index + direction
  elseif index + direction <= 0 then
    next_index = length
  else
    next_index = 1
  end

  local item = state.components[next_index]
  if not item then return utils.notify(fmt("This %s does not exist", item.type), "error") end
  open_element(item.id)
end

function M.get_elements()
  return {
    mode = config.options.mode,
    elements = vim.tbl_map(
      function(elem) return { id = elem.id, name = elem.name, path = elem.path } end,
      state.components
    ),
  }
end

---@alias Direction "'left'" | "'right'"
---Close all elements to the left or right of the current buffer
---@param direction Direction
function M.close_in_direction(direction)
  local index = M.get_current_element_index(state)
  if not index then return end
  local length = #state.components
  if not (index == length and direction == "right") and not (index == 1 and direction == "left") then
    local start = direction == "left" and 1 or index + 1
    local _end = direction == "left" and index - 1 or length
    for _, item in ipairs(vim.list_slice(state.components, start, _end)) do
      delete_element(item.id)
    end
  end
  ui.refresh()
end

--Close other buffers
function M.close_others()
  local index = M.get_current_element_index(state)
  if not index then return end

  for i, item in ipairs(state.components) do
    if i ~= index then delete_element(item.id) end
  end
  ui.refresh()
end

--- sorts all elements
--- @param sort_by (string|function)?
function M.sort_by(sort_by)
  if next(state.components) == nil then return utils.notify("Unable to find elements to sort, sorry", "warn") end
  sorters.sort(state.components, { sort_by = sort_by })
  state.custom_sort = utils.get_ids(state.components)
  local opts = config.options
  if opts.persist_buffer_sort then utils.save_positions(state.custom_sort) end
  ui.refresh()
end

_G.___bufferline_private.handle_close = handle_close
_G.___bufferline_private.handle_click = handle_click
_G.___bufferline_private.handle_group_click = handle_group_click

return M
