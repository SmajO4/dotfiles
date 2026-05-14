-- ========================================================================== --
--                                COPILOT.LUA                                 --
--                                                                            --
--  Integracija GitHub Copilota u editor. Ovaj fajl se brine za inline        --
--  prijedloge koda (Ghost text) i za prozor za konverzaciju (Chat).          --
--                                                                            --
--  VAŽNA POLITIKA OVE KONFIGURACIJE:                                          --
--    Copilot postoji i spreman je za korištenje, ali je pri pokretanju       --
--    Neovima GLOBALNO ISKLJUČEN. Korisnik ga ručno uključuje kada želi.       --
-- ========================================================================== --

return {

  -- ---------------------------------------------------------------------------
  -- SEKCIJA 1: INLINE SUGESTIJE (GHOST TEXT / SHADOW CODE)
  -- ---------------------------------------------------------------------------
  -- Opis:
  --   Obezbjeđuje sivi tekst koji Copilot nudi dok korisnik kuca kod.
  --
  -- Status po pokretanju Neovima:
  --   - Copilot je instaliran
  --   - Copilot je inicijalno GLOBALNO ugašen
  --   - Uključuješ ga ručno preko <leader>ce
  --
  -- Bitne prečice:
  --   <leader>ce  = uključi Copilot globalno
  --   <leader>cd  = isključi Copilot globalno
  --   <leader>cs  = pokaži Copilot status
  --   <leader>ca  = uključi/isključi automatski ghost text za trenutni buffer
  --   <leader>cp  = otvori/zatvori suggestion panel
  --
  -- Kada je Copilot uključen:
  --   <C-l>       = prihvati cijeli Copilot prijedlog
  --   <M-l>       = rezervna alternativa za prihvatanje prijedloga
  --   <M-w>       = prihvati jednu riječ iz prijedloga
  --   <M-a>       = prihvati jednu liniju iz prijedloga
  --   <M-]>       = sljedeći Copilot prijedlog
  --   <M-[>       = prethodni Copilot prijedlog
  --   <C-]>       = odbaci trenutni prijedlog
  {
    "zbirenbaum/copilot.lua",
    cmd = "Copilot",
    build = ":Copilot auth",
    event = "InsertEnter",

    opts = {
      suggestion = {
        enabled = true,
        auto_trigger = true,
        debounce = 75,

        -- [FIX SMAJO]
        -- Blink.cmp i Copilot ghost text mogu živjeti zajedno.
        -- Ako je ovo true, ghost text često nestaje dok completion meni radi.
        hide_during_completion = false,

        keymap = {
          -- [FIX SMAJO]
          -- Gasimo defaultni Copilot accept i koristimo našu preciznu logiku
          -- ispod, koja podržava <C-l> i <M-l> bez rušenja fallback ponašanja.
          accept = false,
          accept_word = "<M-w>",
          accept_line = "<M-a>",
          next = "<M-]>",
          prev = "<M-[>",
          dismiss = "<C-]>",
        },
      },

      panel = {
        enabled = true,
        auto_refresh = true,
        keymap = {
          jump_prev = "[[",
          jump_next = "]]",
          accept = "<CR>",
          refresh = "gr",
          open = "<M-CR>",
        },
        layout = {
          position = "right",
          ratio = 0.35,
        },
      },

      filetypes = {
        markdown = true,
        help = true,
        gitcommit = true,
        yaml = true,
        ["*"] = true,
      },

      copilot_node_command = "node",
      server_opts_overrides = {},
    },

    config = function(_, opts)
      require("copilot").setup(opts)

      -- -----------------------------------------------------------------------
      -- [NOVO SMAJO] Copilot je GLOBALNO ISKLJUČEN pri svakom startu Neovima
      -- -----------------------------------------------------------------------
      -- Ovo omogućava:
      --   - da plugin ostane instaliran i spreman
      --   - da ti ništa ne iskače dok ga ne zatražiš
      --   - da ga ručno pališ preko <leader>ce
      local ok_command, copilot_command = pcall(require, "copilot.command")
      if ok_command and copilot_command and copilot_command.disable then
        copilot_command.disable()
      end

      -- -----------------------------------------------------------------------
      -- [FIX SMAJO] APSOLUTNA KONTROLA NAD <C-l> i <M-l>
      -- -----------------------------------------------------------------------
      -- Kada pritisneš <C-l> ili <M-l>:
      --   - ako je Copilot suggestion vidljiv -> prihvati suggestion
      --   - ako nije vidljiv -> pusti normalno ponašanje tog tastera
      local function map_copilot_accept(key)
        vim.keymap.set("i", key, function()
          local ok, suggestion = pcall(require, "copilot.suggestion")

          if ok and suggestion.is_visible() then
            suggestion.accept()
            return ""
          end

          return vim.api.nvim_replace_termcodes(key, true, false, true)
        end, {
          expr = true,
          replace_keycodes = false,
          desc = "Force Accept Copilot suggestion (" .. key .. ")",
        })
      end

      map_copilot_accept("<C-l>")
      map_copilot_accept("<M-l>")
    end,

    keys = {
      {
        "<leader>cp",
        function()
          require("copilot.panel").toggle()
        end,
        desc = "Toggle Copilot suggestion panel",
      },

      {
        "<leader>cs",
        "<cmd>Copilot status<CR>",
        desc = "Show Copilot status",
      },

      {
        "<leader>ce",
        function()
          local ok, copilot_command = pcall(require, "copilot.command")
          if not ok then
            vim.notify("Copilot command modul nije dostupan.", vim.log.levels.WARN)
            return
          end

          copilot_command.enable()
          vim.notify("Copilot je uključen.", vim.log.levels.INFO)
        end,
        desc = "Enable Copilot globally",
      },

      {
        "<leader>cd",
        function()
          local ok, copilot_command = pcall(require, "copilot.command")
          if not ok then
            vim.notify("Copilot command modul nije dostupan.", vim.log.levels.WARN)
            return
          end

          copilot_command.disable()
          vim.notify("Copilot je isključen.", vim.log.levels.INFO)
        end,
        desc = "Disable Copilot globally",
      },

      {
        "<leader>ca",
        function()
          local ok, suggestion = pcall(require, "copilot.suggestion")
          if not ok then
            vim.notify("Copilot suggestion modul još nije učitan.", vim.log.levels.WARN)
            return
          end

          suggestion.toggle_auto_trigger()
          vim.notify(
            "Copilot ghost text za trenutni buffer je prebačen. Ako je Copilot globalno ugašen, prvo koristi <leader>ce.",
            vim.log.levels.INFO
          )
        end,
        desc = "Toggle Copilot ghost text for current buffer",
      },
    },
  },

  -- ---------------------------------------------------------------------------
  -- SEKCIJA 2: COPILOT CHAT INTERFEJS
  -- ---------------------------------------------------------------------------
  -- Napomena:
  --   Ako želiš koristiti Copilot Chat nakon starta Neovima,
  --   najčišći workflow je:
  --     1. <leader>ce  -> uključi Copilot
  --     2. <leader>cc  -> otvori Copilot Chat
  {
    "CopilotC-Nvim/CopilotChat.nvim",
    branch = "main",
    cmd = {
      "CopilotChat", "CopilotChatOpen", "CopilotChatClose", "CopilotChatToggle",
      "CopilotChatStop", "CopilotChatReset", "CopilotChatPrompts", "CopilotChatModels",
      "CopilotChatExplain", "CopilotChatReview", "CopilotChatFix", "CopilotChatOptimize", "CopilotChatTests",
    },
    dependencies = {
      { "zbirenbaum/copilot.lua" },
      { "nvim-lua/plenary.nvim" },
    },
    opts = function()
      local user = vim.env.USER or "Student"
      user = user:sub(1, 1):upper() .. user:sub(2)

      return {
        auto_insert_mode = true,
        question_header = "  " .. user .. " ",
        answer_header = "  Copilot ",
        error_header = "  Error ",
        temperature = 0.1,
        window = {
          layout = "vertical",
          side = "left",
          width = 0.35,
          border = "rounded",
          title = " Copilot Chat ",
        },
        auto_follow_cursor = false,
      }
    end,
    keys = {
      { "<leader>cc", "<cmd>CopilotChatToggle<CR>", desc = "Toggle Copilot Chat window", mode = { "n", "x" } },
      { "<leader>cq", "<cmd>CopilotChat #buffer:active ", desc = "Ask Copilot about current buffer", mode = "n" },
      { "<leader>cx", "<cmd>CopilotChatExplain<CR>", desc = "Explain selected code", mode = "x" },
      { "<leader>cr", "<cmd>CopilotChatReview<CR>", desc = "Review selected code", mode = "x" },
      { "<leader>cf", "<cmd>CopilotChatFix<CR>", desc = "Fix selected code with Copilot", mode = "x" },
      { "<leader>co", "<cmd>CopilotChatOptimize<CR>", desc = "Optimize selected code", mode = "x" },
      { "<leader>ct", "<cmd>CopilotChatTests<CR>", desc = "Generate tests for selected code", mode = "x" },
      { "<leader>cm", "<cmd>CopilotChatModels<CR>", desc = "Select Copilot Chat model" },
      { "<leader>cP", "<cmd>CopilotChatPrompts<CR>", desc = "Show Copilot Chat prompts" },
      { "<C-s>", "<CR>", ft = "copilot-chat", desc = "Submit Copilot Chat prompt", remap = true },
    },
  },
}

