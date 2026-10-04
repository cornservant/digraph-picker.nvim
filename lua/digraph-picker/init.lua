---@class Picker
---@field is_installed fun(): boolean
---@field insert_digraph fun(digraphs: DigraphEntry[])

---@class DigraphEntry
---@field symbol string
---@field digraph string
---@field name string

---@class Options
---@field picker string?
---@field digraphs DigraphEntry[]?
---@field exclude_builtin_digraphs boolean?

-- Module initialisation
local M = {}
M.digraphs = require('digraph-picker.digraphs')
M.picker = "telescope"

local pickers = {
  telescope = require("digraph-picker.picker.telescope"),
  snacks = require("digraph-picker.picker.snacks"),
  vim_ui_select = require("digraph-picker.picker.vim_ui_select"),
}

-- Merges a source digraphs table (`src`) into a destination (`dst`) digraphs table. The digraphs table contains a list of digraph definitions. Here's an example of a digraphs table:
--
--    {
--      { digraph = 'SM', symbol = '☺', name = 'SMILING FACE' },
--      { digraph = 'FR', symbol = '☹', name = 'FROWNING FACE' },
--      { digraph = 'HT', symbol = '♥', name = 'HEART' },
--      { digraph = 'ST', symbol = '★', name = 'STAR' },
--    },
--
-- The rules for merging a digraph definition into the destination table are:
--
-- - If the destination table contains a definition with the same `symbol` then non-nil definition `digraph` and `name` fields are assigned to the corresponding fields in the destination definition.
-- - If the destination table does not contain a definition with the same `symbol` then the source definition is appended to destination table.
function M.merge_digraphs(src, dst)
  local dst_symbols = {}
  for i, def in ipairs(dst) do
    dst_symbols[def.symbol] = i
  end
  for _, src_def in ipairs(src) do
    local dst_index = dst_symbols[src_def.symbol]
    if dst_index then
      local dst_def = dst[dst_index]
      if src_def.digraph then
        dst_def.digraph = src_def.digraph
      end
      if src_def.name then
        dst_def.name = src_def.name
      end
    else
      table.insert(dst, src_def)
    end
  end
end

-- `update_vim_digraphs(symbols, digraphs)` sets Vim digraphs with matching `symbols` with values from the `digraphs` table (see `merge_digraphs`).
function M.update_vim_digraphs(symbols, digraphs)
  local digraphs_index = {}
  for i, def in ipairs(digraphs) do
    digraphs_index[def.symbol] = i
  end
  for _, symbol in pairs(symbols) do
    local def = digraphs[digraphs_index[symbol]]
    vim.fn.digraph_set(def.digraph, def.symbol)
  end
end

-- `validate_digraphs(digraphs)` validates the `digraphs` table of digraph definitions (see `merge_digraphs`). Returns `nil` if there are no error or an error message string if there are validation errors. The digraph definition validation rules are as follows:
--
-- - the `symbol` field must be a single character.
-- - the `digraph` field must be two printable characters.
-- - the `name` field must contain at least one character.
function M.validate_digraphs(digraphs)
  local function digraph_def_error(index, def, message)
    return "invalid digraph definition at index " .. index .. ": " .. message .. ": " .. vim.inspect(def)
  end

  if type(digraphs) ~= "table" then
    return "`digraphs` must be a table of digraph definitions"
  end
  local err
  err = ""
  for i, def in ipairs(digraphs) do
    if type(def) ~= "table" then
      err = err .. "\n" .. digraph_def_error(i, def, "digraph is not a table")
      goto continue
    end
    if type(def.symbol) ~= "string" or vim.fn.strchars(def.symbol) ~= 1 then
      err = err .. "\n" .. digraph_def_error(i, def, "symbol must be a single character")
      goto continue
    end
    if type(def.digraph) ~= "string" or vim.fn.strchars(def.digraph) ~= 2 or not def.digraph:match("^%C%C$") then
      err = err .. "\n" .. digraph_def_error(i, def, "digraph must be two printable characters")
      goto continue
    end
    if type(def.name) ~= "string" or vim.fn.strchars(def.name) < 1 then
      err = err .. "\n" .. digraph_def_error(i, def, "name must contain at least one character")
      goto continue
    end
    ::continue::
  end
  if err == "" then
    err = nil
  else
    err = err:sub(2)
  end
  return err
end

-- `setup` configures the plugin.
--
-- Options:
--
--   `digraphs`: A table of digraph definitions (see `merge_digraphs`).
--   `exclude_builtin_digraphs``: Setting this to `true` stops the builtin digraph table from loading.
--
---@param opts Options?
function M.setup(opts)
  opts = opts or {}
  opts.digraphs = opts.digraphs or {}
  if opts.exclude_builtin_digraphs then
    M.digraphs = {}
  end
  M.merge_digraphs(opts.digraphs, M.digraphs)
  local err = M.validate_digraphs(M.digraphs)
  if err ~= nil then
    vim.notify(err, vim.log.levels.ERROR)
    return
  end
  local symbols = {}
  for _, def in ipairs(opts.digraphs) do
    table.insert(symbols, def.symbol)
  end
  M.update_vim_digraphs(symbols, M.digraphs)
  opts.picker = opts.picker or M.picker
  M.picker = opts.picker
end

-- `insert_digraph` opens a Telescope digraph picker and inserts the selected digraph character into the current window.
-- This function is normally called in insert mode.
function M.insert_digraph()
  if pickers.telescope.is_installed() and M.picker == "telescope" then
    pickers.telescope.insert_digraph(M.digraphs)
    return
  end
  if pickers.snacks.is_installed() and M.picker == "snacks" then
    pickers.snacks.insert_digraph(M.digraphs)
    return
  end
  pickers.vim_ui_select.insert_digraph(M.digraphs)
end

return M
