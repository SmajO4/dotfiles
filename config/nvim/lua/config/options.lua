-- ========================================================================== --
--                                OPTIONS.LUA                                 --
--                                                                            --
--  Definiše osnovna ponašanja editora, vizuelni interfejs i pravila za       --
--  obradu koda (brojevi linija, razmaci, miš, clipboard).                    --
-- ========================================================================== --

-- -----------------------------------------------------------------------------
-- 1. INDENTACIJA I FORMATIRANJE
-- -----------------------------------------------------------------------------
vim.opt.shiftwidth = 4     -- Broj razmaka pri korištenju komandi '>>' i '<<'
vim.opt.tabstop = 4        -- Vizuelna širina jednog <Tab> karaktera
vim.opt.softtabstop = 4    -- Koliko mjesta <Backspace> briše unazad
vim.opt.expandtab = true   -- Konvertuje pritisak na taster <Tab> u stvarne razmake

-- Osnovna automatska indentacija.
-- Napomena:
--   Ovo pomaže pri Enter-u i opštem ponašanju novih linija.
--   Tvoje specifično ponašanje za normal-mode 'o' je precizno definisano
--   u lua/config/keymaps.lua, jer želiš:
--     - pametni dodatni indent poslije '{'
--     - ali i vjerno čuvanje ručno veće indentacije
vim.opt.autoindent = true
vim.opt.smartindent = true

-- -----------------------------------------------------------------------------
-- 2. PONAŠANJE EDITORA I UI ELEMENTI
-- -----------------------------------------------------------------------------
vim.opt.number = true             -- Prikaz apsolutnih brojeva linija sa lijeve strane
vim.opt.relativenumber = false    -- Isključen relativni prikaz (lakše za tradicionalni pregled)
vim.opt.cursorline = true         -- Diskretno podvlači liniju na kojoj se nalazi kursor
vim.opt.mouse = "a"               -- Omogućava potpunu upotrebu miša u svim modovima
vim.opt.clipboard = "unnamedplus" -- Sinhronizuje Neovim i sistemski (OS) clipboard
vim.opt.scrolloff = 8             -- Drži kursor minimalno 8 linija udaljen od ruba ekrana
vim.opt.wrap = false              -- Isključuje prelamanje dugih linija (kod ide udesno)
vim.opt.swapfile = false          -- Onemogućava kreiranje sistemskih '.swp' fajlova

-- Korisne produkcijske postavke:
vim.opt.undofile = true           -- Čuva undo historiju i nakon zatvaranja fajla
vim.opt.confirm = true            -- Upozori prije izlaska ako postoje nesnimljene izmjene
vim.opt.signcolumn = "yes"        -- Kolona za LSP/git znakove je stalno rezervisana, bez trzanja layouta

-- -----------------------------------------------------------------------------
-- 3. GLOBALNE LAZYVIM POSTAVKE
-- -----------------------------------------------------------------------------
-- Isključuje automatsko formatiranje koda prilikom svakog čuvanja fajla (on-save).
-- Umjesto toga, korisnik ručno formatira kod preko definisane prečice (<leader>lf).
vim.g.autoformat = false

-- -----------------------------------------------------------------------------
-- 4. LOGIKA PRETRAŽIVANJA (SEARCH)
-- -----------------------------------------------------------------------------
vim.opt.ignorecase = true  -- Pretraga ne razlikuje velika i mala slova (npr. traži 'test' nađe 'Test')
vim.opt.smartcase = true   -- ...OSIM ako korisnik unese barem jedno veliko slovo.

-- -----------------------------------------------------------------------------
-- 5. COPILOT CHAT / COMPLETION KOMPATIBILNOST
-- -----------------------------------------------------------------------------
-- Poboljšava ponašanje autocomplete-a u Copilot Chat prozoru.
-- Posebno korisno za #buffer, #file, @copilot, /Explain, /Review i slične opcije.
vim.opt.completeopt = { "menu", "menuone", "noinsert", "noselect", "popup" }
