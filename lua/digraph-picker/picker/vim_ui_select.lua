local super = require("digraph-picker.picker")

---@type Picker
return {
  is_installed = function()
    return true
  end,

  insert_digraph = function(digraphs)
    local mode = vim.api.nvim_get_mode().mode
    vim.ui.select(digraphs, {
      prompt = "Select Digraph:",
      format_item = function(item)
        return string.format("%s [%s] %s", item.symbol, item.digraph, item.name)
      end,
    }, function(choice)
      if choice then
        super.insert_text(choice.symbol, mode)
      end
      if mode == 'i' then
        super.sendkeys('a')
      end
    end)
  end
}
