 local M = {}

function M.setup()
  require('base16-colorscheme').setup({
    base00 = '#291b14',
    base01 = '#452c21',
    base02 = '#3e281e',
    base03 = '#716761',
    base04 = '#b6b1af',
    base05 = '#f3f2f2',
    base06 = '#f3f2f2',
    base07 = '#f3f2f2',
    base08 = '#bf6f4b',
    base09 = '#accc66',
    base0A = '#d6bf5c',
    base0B = '#e48e67',
    base0C = '#cfe996',
    base0D = '#ecaf93',
    base0E = '#e9d996',
    base0F = '#f4e9be',
  })

  local hi = function(group, opts)
    vim.api.nvim_set_hl(0, group, opts)
  end

  hi('TelescopeNormal',         { fg = '#f3f2f2',          bg = '#291b14' })
  hi('TelescopeBorder',         { fg = '#716761',             bg = '#291b14' })
  hi('TelescopePromptNormal',   { fg = '#f3f2f2',          bg = '#291b14' })
  hi('TelescopePromptBorder',   { fg = '#716761',             bg = '#291b14' })
  hi('TelescopePromptPrefix',   { fg = '#e48e67',             bg = '#291b14' })
  hi('TelescopePromptCounter',  { fg = '#b6b1af',  bg = '#291b14' })
  hi('TelescopePromptTitle',    { fg = '#291b14',             bg = '#e48e67' })
  hi('TelescopePreviewTitle',   { fg = '#291b14',             bg = '#d6bf5c' })
  hi('TelescopeResultsTitle',   { fg = '#291b14',             bg = '#accc66' })
  hi('TelescopeSelection',      { fg = '#f3f2f2',          bg = '#3e281e' })
  hi('TelescopeSelectionCaret', { fg = '#e48e67',             bg = '#3e281e' })
  hi('TelescopeMatching',       { fg = '#e48e67',             bold = true })
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
