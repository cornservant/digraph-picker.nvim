local super = require("digraph-picker.picker")

---@type Picker
return {
  is_installed = function()
    local ok, _ = pcall(require, 'snacks.picker')
    return ok
  end,

  insert_digraph = function(digraphs)
    local ok, snacks = pcall(require, 'snacks')
    if not ok or not snacks.picker then
      vim.notify("[digraph-picker] Snacks.picker is not available", vim.log.levels.ERROR)
      return
    end

    local mode = vim.api.nvim_get_mode().mode

    local items = {}
    for idx, item in ipairs(digraphs) do
      table.insert(items, {
        idx = idx,
        text = string.format("%s %-2s %s", item.symbol, item.digraph, item.name),
        item = item,
      })
    end

    snacks.picker.pick({
      title = "Insert Digraph",
      items = items,
      format = function(item, picker)
        return {
          { item.item.symbol,  "SnacksPickerIdx" },
          { "  " },
          { item.item.digraph, "Normal" },
          { "  " },
          { item.item.name,    "SnacksPickerComment" },
        }
      end,
      confirm = function(picker, item)
        picker:close()

        if item and item.item then
          super.debug("Symbol selected: " .. item.item.symbol)
          super.insert_text(item.item.symbol, mode)
          if mode == 'i' then
            super.sendkeys('a')
          end
        end
      end,
      on_close = function()
        if mode == 'i' and vim.api.nvim_get_mode().mode ~= 'i' then
          super.sendkeys('a')
        end
      end,
      layout = {
        preview = false,
      },
    })
  end
}
