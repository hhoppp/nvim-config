 local M = {}

function M.setup()
  require('base16-colorscheme').setup({
    base00 = '#f2e1d9',
    base01 = '#ecd5ca',
    base02 = '#eacfc3',
    base03 = '#9a7c6f',
    base04 = '#56514e',
    base05 = '#1b1918',
    base06 = '#1b1918',
    base07 = '#1b1918',
    base08 = '#bf6f4b',
    base09 = '#6a862d',
    base0A = '#a38c29',
    base0B = '#c35422',
    base0C = '#5f7e1b',
    base0D = '#823817',
    base0E = '#7e6b1b',
    base0F = '#ad921f',
  })

  local hi = function(group, opts)
    vim.api.nvim_set_hl(0, group, opts)
  end

  -- telescope.nvim
  hi('TelescopeNormal',         { fg = '#1b1918',          bg = '#f2e1d9' })
  hi('TelescopeBorder',         { fg = '#9a7c6f',             bg = '#f2e1d9' })
  hi('TelescopePromptNormal',   { fg = '#1b1918',          bg = '#f2e1d9' })
  hi('TelescopePromptBorder',   { fg = '#9a7c6f',             bg = '#f2e1d9' })
  hi('TelescopePromptPrefix',   { fg = '#c35422',             bg = '#f2e1d9' })
  hi('TelescopePromptCounter',  { fg = '#56514e',  bg = '#f2e1d9' })
  hi('TelescopePromptTitle',    { fg = '#f2e1d9',             bg = '#c35422' })
  hi('TelescopePreviewTitle',   { fg = '#f2e1d9',             bg = '#a38c29' })
  hi('TelescopeResultsTitle',   { fg = '#f2e1d9',             bg = '#6a862d' })
  hi('TelescopeSelection',      { fg = '#1b1918',          bg = '#eacfc3' })
  hi('TelescopeSelectionCaret', { fg = '#c35422',             bg = '#eacfc3' })
  hi('TelescopeMatching',       { fg = '#c35422',             bold = true })

  -- mini.pick
  hi('MiniPickNormal',         { fg = '#1b1918',          bg = '#f2e1d9' })
  hi('MiniPickBorder',         { fg = '#9a7c6f',             bg = '#f2e1d9' })
  hi('MiniPickPrompt',   { fg = '#1b1918',          bg = '#f2e1d9' })
  hi('MiniPickPromptPrefix',   { fg = '#c35422',             bg = '#f2e1d9' })
  hi('MiniPickBorderText',    { fg = '#f2e1d9',             bg = '#c35422' })
  hi('MiniPickMatchCurrent',      { fg = '#1b1918',          bg = '#eacfc3' })
  hi('MiniPickPromptCaret', { fg = '#c35422',             bg = '#eacfc3' })
  hi('MiniPickMatchRanges',       { fg = '#c35422',             bold = true })
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
