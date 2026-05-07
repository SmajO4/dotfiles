-- ========================================================================== --
--                                AUTOCMDS.LUA                                --
--                                                                            --
--  Ovaj fajl sadrži automatizovane akcije koje Neovim izvršava u pozadini    --
--  kao reakciju na određene događaje (npr. otvaranje ili kreiranje fajla).   --
-- ========================================================================== --

local augroup = vim.api.nvim_create_augroup
local autocmd = vim.api.nvim_create_autocmd

-- -----------------------------------------------------------------------------
-- 1. AUTOMATSKI JAVA TEMPLATE (BOILERPLATE)
-- -----------------------------------------------------------------------------
-- Opis: Generiše osnovnu strukturu (package, class, main) za nove .java fajlove.
-- Okidači (Events):
--   - BufNewFile: Kada se kreira potpuno novi fajl
--   - BufReadPost: Nakon što se fajl učita u buffer
--   - BufWinEnter: Kada se fajl prikaže u prozoru (osigurava rad sa file explorerima)
autocmd({ "BufNewFile", "BufReadPost", "BufWinEnter" }, {
  pattern = "*.java",
  group = augroup("JavaTemplate", { clear = true }),
  callback = function()
    -- [KORAK 1] Provjera sadržaja: Nastavljamo samo ako je fajl potpuno prazan
    local lines_in_buf = vim.api.nvim_buf_get_lines(0, 0, -1, false)
    if #lines_in_buf > 1 or (#lines_in_buf == 1 and lines_in_buf[1] ~= "") then
      return 
    end

    -- [KORAK 2] Ekstrakcija metapodataka o fajlu
    local filename = vim.fn.expand("%:t:r") -- Ime fajla bez ekstenzije (ImeKlase)
    local filepath = vim.fn.expand("%:p:h") -- Puna putanja do direktorija
    
    -- [KORAK 3] Dinamičko detektovanje Java paketa (package)
    local package_name = ""
    local maven_match = filepath:match("src/main/java/(.+)")
    local normal_match = filepath:match("src/(.+)")
    
    if maven_match then 
      package_name = maven_match:gsub("/", "."):gsub("\\", ".")
    elseif normal_match then 
      package_name = normal_match:gsub("/", "."):gsub("\\", ".")
    end
    
    -- [KORAK 4] Konstrukcija izvornog koda liniju po liniju
    local code = {}
    if package_name ~= "" then
      table.insert(code, "package " .. package_name .. ";")
      table.insert(code, "")
    end
    table.insert(code, "public class " .. filename .. " {")
    table.insert(code, "    public static void main(String[] args) {")
    table.insert(code, "        ") -- Prazan prostor gdje kursor treba sletjeti
    table.insert(code, "    }")
    table.insert(code, "}")
    
    -- [KORAK 5] Upisivanje generisanog koda u aktivni buffer
    vim.api.nvim_buf_set_lines(0, 0, -1, false, code)
    
    -- [KORAK 6] Pozicioniranje kursora unutar 'main' metode
    -- Koristi se 'defer_fn' (100ms) da bi se Neovim UI stabilizovao prije skoka
    vim.defer_fn(function()
      local row = (package_name ~= "") and 5 or 3 -- Linija zavisi od postojanja paketa
      if vim.api.nvim_buf_is_valid(0) then
        vim.api.nvim_win_set_cursor(0, { row, 8 })
        vim.cmd("startinsert!") -- Automatski prelazi u mod za kucanje (Insert mode)
      end
    end, 100)
  end,
  desc = "Generates Java structure for empty files",
})

-- -----------------------------------------------------------------------------
-- 2. C/C++ FORMATIRANJE (INDENTACIJA)
-- -----------------------------------------------------------------------------
-- Opis: Forsira inženjerski standard od 4 razmaka (spaces) za C i C++ kod,
-- ignorirajući potencijalne konflikte sa drugim pluginima (npr. Google stil).
autocmd("FileType", {
  pattern = { "cpp", "c", "h", "hpp" },
  group = augroup("CppSettings", { clear = true }),
  callback = function()
    vim.bo.shiftwidth = 4
    vim.bo.tabstop = 4
    vim.bo.expandtab = true
  end,
})
