-- ========================================================================== --
--                              TELESCOPE.LUA                                 --
--                                                                            --
--  Centralni modul za pretragu i "Fuzzy Finding". Omogućava korisniku        --
--  instantnu pretragu hiljada fajlova po imenu ili po tekstu unutar njih.    --
-- ========================================================================== --

return {
  {
    "nvim-telescope/telescope.nvim",
    opts = {
      defaults = {
        
        -- ---------------------------------------------------------
        -- Izgled pretraživača (Layout & UI)
        -- ---------------------------------------------------------
        layout_strategy = "horizontal", -- Standardni horizontalni prikaz
        layout_config = {
          horizontal = {
            prompt_position = "top",    -- Linija za unos teksta nalazi se na samom vrhu
            preview_width = 0.5,        -- Prozor za vizuelni pregled fajla zauzima desnu polovinu (50%)
          },
        },
        
        -- ---------------------------------------------------------
        -- Logika obrade podataka (Poredak i Ignorisanje)
        -- ---------------------------------------------------------
        sorting_strategy = "ascending", -- Prikazuje najrelevantnije rezultate direktno ispod linije za unos
        
        -- Zabrana pretrage u sistemskim i builds folderima kako bi pretraga koda bila trenutna
        file_ignore_patterns = { "node_modules", ".git/", "target/", "build/" },
      },
    },
  },
}
