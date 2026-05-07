-- ========================================================================== --
--                                BLINK.LUA                                   --
--                                                                            --
--  Konfiguracija za "Blink.cmp". Ovo je alat zadužen za pametnu              --
--  autokompleciju (prikaz padajuće liste metoda, varijabli i koda).          --
-- ========================================================================== --

return {
  {
    "saghen/blink.cmp",
    opts = {
      
      -- ---------------------------------------------------------
      -- Kontrole na tastaturi za interakciju sa padajućom listom
      -- ---------------------------------------------------------
      keymap = {
        preset = "default", 

        -- Kretanje niz i uz listu prijedloga
        ["<Tab>"] = { "select_next", "snippet_forward", "fallback" },
        ["<S-Tab>"] = { "select_prev", "snippet_backward", "fallback" },
        
        -- Potvrda i prihvatanje označenog prijedloga iz liste
        ["<CR>"] = { "accept", "fallback" },
      },

      -- ---------------------------------------------------------
      -- Vizuelni prikaz liste (Izgled)
      -- ---------------------------------------------------------
      appearance = {
        use_nvim_cmp_as_default = true, -- Oslanja se na poznati interfejs starog nvim-cmp
        nerd_font_variant = "mono",     -- Koristi mono font za savršeno poravnanje ikonica
      },

      -- ---------------------------------------------------------
      -- Pomoć pri kucanju parametara funkcija (Signature Help)
      -- ---------------------------------------------------------
      signature = {
        enabled = true, -- Kad otvoriš zagradu, iskače prozor koji opisuje parametre metode
        window = { border = "rounded" }, -- UI stil ivica za taj prozorčić
      },
    },
  },
}
