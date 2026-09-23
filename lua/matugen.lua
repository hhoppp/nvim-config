 local M = {}

function M.setup()
  require('base16-colorscheme').setup({
    base00 = '#dce2ef',
    base01 = '#ced6e9',
    base02 = '#c6d0e6',
    base03 = '#74819f',
    base04 = '#4c4d54',
    base05 = '#18191b',
    base06 = '#18191b',
    base07 = '#18191b',
    base08 = '#fd4663',
    base09 = '#6b2d86',
    base0A = '#a32976',
    base0B = '#2253c3',
    base0C = '#601b7e',
    base0D = '#173782',
    base0E = '#7e1b5a',
    base0F = '#ad1f79',
  })

  local hi = function(group, opts)
    vim.api.nvim_set_hl(0, group, opts)
  end

  -- telescope.nvim
  hi('TelescopeNormal',         { fg = '#18191b',          bg = '#dce2ef' })
  hi('TelescopeBorder',         { fg = '#74819f',             bg = '#dce2ef' })
  hi('TelescopePromptNormal',   { fg = '#18191b',          bg = '#dce2ef' })
  hi('TelescopePromptBorder',   { fg = '#74819f',             bg = '#dce2ef' })
  hi('TelescopePromptPrefix',   { fg = '#2253c3',             bg = '#dce2ef' })
  hi('TelescopePromptCounter',  { fg = '#4c4d54',  bg = '#dce2ef' })
  hi('TelescopePromptTitle',    { fg = '#dce2ef',             bg = '#2253c3' })
  hi('TelescopePreviewTitle',   { fg = '#dce2ef',             bg = '#a32976' })
  hi('TelescopeResultsTitle',   { fg = '#dce2ef',             bg = '#6b2d86' })
  hi('TelescopeSelection',      { fg = '#18191b',          bg = '#c6d0e6' })
  hi('TelescopeSelectionCaret', { fg = '#2253c3',             bg = '#c6d0e6' })
  hi('TelescopeMatching',       { fg = '#2253c3',             bold = true })

  -- mini.pick
  hi('MiniPickNormal',         { fg = '#18191b',          bg = '#dce2ef' })
  hi('MiniPickBorder',         { fg = '#74819f',             bg = '#dce2ef' })
  hi('MiniPickPrompt',   { fg = '#18191b',          bg = '#dce2ef' })
  hi('MiniPickPromptPrefix',   { fg = '#2253c3',             bg = '#dce2ef' })
  hi('MiniPickBorderText',    { fg = '#dce2ef',             bg = '#2253c3' })
  hi('MiniPickMatchCurrent',      { fg = '#18191b',          bg = '#c6d0e6' })
  hi('MiniPickPromptCaret', { fg = '#2253c3',             bg = '#c6d0e6' })
  hi('MiniPickMatchRanges',       { fg = '#2253c3',             bold = true })
end

-- Register a signal handler for SIGUSR1 (matugen updates).
-- The handler re-requires this module, which re-runs the code below, so the
-- previous handle is stopped first; otherwise handlers double on every signal.
if _G.__matugen_signal then
  _G.__matugen_signal:stop()
  _G.__matugen_signal:close()
end

local signal = vim.uv.new_signal()
_G.__matugen_signal = signal
signal:start(
  'sigusr1',
  vim.schedule_wrap(function()
    package.loaded['matugen'] = nil
    require('matugen').setup()
  end)
)

return M
