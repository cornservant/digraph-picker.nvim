local M = {}

function M.debug(val)
  vim.notify(vim.inspect(val), vim.log.levels.DEBUG)
end

-- Sends string to the keyboard input buffer.
---@param str string
function M.sendkeys(str)
  local keys = vim.api.nvim_replace_termcodes(str, true, false, true)
  vim.api.nvim_feedkeys(keys, 'n', false)
end

-- Insert `text` at the cursor.
-- `mode` is the mode of the window that the text is being inserted into.
---@param text string
---@param mode string
function M.insert_text(text, mode)
  local buf = vim.api.nvim_get_current_buf()
  local pos = vim.api.nvim_win_get_cursor(0)
  local row = pos[1]
  local col = pos[2]
  if mode ~= 'i' then
    col = col - 1
  end
  local line = vim.api.nvim_buf_get_lines(buf, row - 1, row, false)[1] or ''
  local new_line = line:sub(1, col) .. text .. line:sub(col + 1)
  vim.api.nvim_buf_set_lines(buf, row - 1, row, false, { new_line })
  local new_col = col + #text
  vim.api.nvim_win_set_cursor(0, { row, new_col })
end

return M
