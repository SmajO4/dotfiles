-- ========================================================================== --
--                                LAZY.LUA                                    --
--                                                                            --
--  Ovo je "bootstrapper". Motor koji pokreće cijeli sistem, instalira        --
--  samog sebe ako nedostaje, te upravlja svim ostalim dodacima (pluginima).  --
-- ========================================================================== --

-- -----------------------------------------------------------------------------
-- 1. AUTOMATSKA INSTALACIJA (BOOTSTRAPPING)
-- -----------------------------------------------------------------------------
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = "https://github.com/folke/lazy.nvim.git"
  local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { "Critical error: Failed to clone lazy.nvim:\n", "ErrorMsg" },
      { out, "WarningMsg" },
      { "\nPress any key to exit..." },
    }, true, {})
    vim.fn.getchar()
    os.exit(1)
  end
end
vim.opt.rtp:prepend(lazypath)

-- -----------------------------------------------------------------------------
-- 2. KONFIGURACIJA I UČITAVANJE PLUGINA
-- -----------------------------------------------------------------------------
require("lazy").setup({
  spec = {
    -- Baza: Učitavanje standardne arhitekture LazyVim-a
    { "LazyVim/LazyVim", import = "lazyvim.plugins" },
    
    -- Zvanične ekstenzije: Specijalizovana podrška za jezike (Java)
    { import = "lazyvim.plugins.extras.lang.java" },
    
    -- Korisnički plugini: Učitava sve fajlove iz foldera 'lua/plugins/'
    { import = "plugins" },
  },
  
  defaults = {
    lazy = false,    -- Isključeno "lijeno učitavanje" po defaultu; plugini se učitavaju odmah
    version = false, -- Prati najnovije 'commitove' umjesto fiksiranih verzija
  },
  
  -- Definiše temu koja se prikazuje dok se plugini instaliraju prvi put
  install = { colorscheme = { "tokyonight" } }, 
  
  checker = {
    enabled = true, -- Omogućava provjeru novih verzija u pozadini
    notify = false, -- Sprječava iskakajuće poruke koje ometaju rad
  },
})
