local super = require("digraph-picker.picker")

---@type Picker
return {
  is_installed = function()
    local ok, _ = pcall(require, 'telescope')
    return ok
  end,

  insert_digraph = function(digraphs)
    local ok, _ = pcall(require, 'telescope')
    if not ok then
      vim.notify("Telescope is not installed", vim.log.levels.ERROR)
      return
    end

    local actions = require('telescope.actions')
    local action_state = require('telescope.actions.state')
    local finders = require('telescope.finders')
    local pickers = require('telescope.pickers')
    local entry_display = require('telescope.pickers.entry_display')
    local conf = require('telescope.config').values

    local mode = vim.api.nvim_get_mode().mode

    -- Custom column layout for Telescope display
    local function make_display(entry)
      local displayer = entry_display.create({
        separator = ' ',
        items = {
          { width = 0.1 },
          { width = 0.1 },
          { width = 0.8 },
        },
      })
      return displayer({
        { entry.value.symbol,  'TelescopeResultsIdentifier' },
        { entry.value.digraph, 'TelescopeResultsNumber' },
        entry.value.name,
      })
    end

    pickers.new({}, {
      prompt_title = "Insert Digraph",
      finder = finders.new_table {
        results = digraphs,
        entry_maker = function(entry)
          return {
            value = entry,
            display = make_display,
            ordinal = entry.digraph .. ' ' .. entry.symbol .. ' ' .. entry.name,
          }
        end
      },
      sorter = conf.generic_sorter({}),
      attach_mappings = function(prompt_bufnr, map)
        map({ 'i', 'n' }, '<Esc>', function()
          actions.close(prompt_bufnr)
          super.debug("Picker cancelled")
          if mode == 'i' then
            super.sendkeys('a')
          end
        end)
        actions.select_default:replace(function()
          actions.close(prompt_bufnr)
          local selection = action_state.get_selected_entry()
          if selection then
            local symbol = selection.value.symbol
            super.debug("Symbol selected: " .. symbol)
            super.insert_text(symbol, mode)
            if mode == 'i' then
              super.sendkeys('a')
            end
          end
        end)
        return true
      end,
      layout_config = {
        width = 0.8,
        height = 0.5,
      }
    }):find()
  end,
}
