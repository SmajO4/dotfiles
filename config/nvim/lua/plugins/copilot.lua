-- ========================================================================== --
--                                COPILOT.LUA                                 --
--                                                                            --
--  Integracija GitHub Copilota u editor. Ovaj fajl se brine za inline        --
--  prijedloge koda (Ghost text) i za prozor za konverzaciju (Chat).          --
-- ========================================================================== --

return {

  -- ---------------------------------------------------------------------------
  -- SEKCIJA 1: INLINE SUGESTIJE (GHOST TEXT / SHADOW CODE)
  -- ---------------------------------------------------------------------------
  -- Opis:
  --   Obezbjeđuje sivi tekst koji Copilot nudi dok korisnik kuca kod.
  --
  -- Bitne prečice:
  --   <C-l>       = prihvati cijeli Copilot prijedlog
  --   <M-l>       = rezervna alternativa za prihvatanje prijedloga
  --   <M-w>       = prihvati jednu riječ iz prijedloga
  --   <M-a>       = prihvati jednu liniju iz prijedloga
  --   <M-]>       = sljedeći Copilot prijedlog
  --   <M-[>       = prethodni Copilot prijedlog
  --   <C-]>       = odbaci trenutni prijedlog
  --   <leader>ca  = uključi/isključi automatski ghost text za trenutni buffer
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

        -- [FIX SMAJO] OVO JE BILO TRUE!
        -- Blink.cmp je prebrz i stalno otvara padajući meni. Ako je ovo true,
        -- Copilot će stalno bježati i gasiti sivi tekst. Stavljamo na false
        -- da bi ghost text i Blink mogli živjeti u harmoniji.
        hide_during_completion = false,

        keymap = {
          -- [FIX SMAJO] Gasimo defaultni accept. 
          -- Zašto? Zato što ga prepuštamo našoj "agresivnoj" manualnoj funkciji 
          -- u config bloku ispod koja garantuje da terminal ne pojede <C-l>.
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
      -- [FIX SMAJO] APSOLUTNA KONTROLA NAD <C-l> i <M-l>
      -- -----------------------------------------------------------------------
      -- Ova logika stvara "neprobojni" štit. Kada pritisneš <C-l>, Neovim prvo
      -- pita Copilota: "Da li korisnik trenutno vidi sivi tekst?".
      -- Ako je odgovor DA -> prihvati kod i ne radi ništa drugo.
      -- Ako je odgovor NE -> simuliraj normalan pritisak <C-l> (ili <M-l>).
      
      local function map_copilot_accept(key)
        vim.keymap.set("i", key, function()
          local ok, suggestion = pcall(require, "copilot.suggestion")
          
          -- Ako je modul učitan i ghost text je vidljiv na ekranu
          if ok and suggestion.is_visible() then
            suggestion.accept()
            return "" -- Pojedi taster, ne unosi ništa u kod
          end
          
          -- U suprotnom, vrati normalno ponašanje tastera
          return vim.api.nvim_replace_termcodes(key, true, false, true)
        end, {
          expr = true,
          replace_keycodes = false,
          desc = "Force Accept Copilot suggestion (" .. key .. ")",
        })
      end

      map_copilot_accept("<C-l>")
      map_copilot_accept("<M-l>")

      -- [FIX SMAJO] OBRISANO: Tvoji stari autocmds za BlinkCmpMenuOpen.
      -- Brisanjem toga smo ukinuli "race condition" gdje ti se Copilot
      -- potpuno zaledi i nestane iz buffera. Sada su nezavisni.
    end,

    keys = {
      { "<leader>cp", function() require("copilot.panel").toggle() end, desc = "Toggle Copilot suggestion panel" },
      { "<leader>cs", "<cmd>Copilot status<CR>", desc = "Show Copilot status" },
      { "<leader>ce", "<cmd>Copilot enable<CR>", desc = "Enable Copilot globally" },
      { "<leader>cd", "<cmd>Copilot disable<CR>", desc = "Disable Copilot globally" },
      {
        "<leader>ca",
        function()
          local ok, suggestion = pcall(require, "copilot.suggestion")
          if not ok then
            vim.notify("Copilot suggestion modul još nije učitan.", vim.log.levels.WARN)
            return
          end
          suggestion.toggle_auto_trigger()
          vim.notify("Copilot ghost text prebačen. Za globalno koristi <leader>cd.", vim.log.levels.INFO)
        end,
        desc = "Toggle Copilot ghost text for current buffer",
      },
    },
  },

  -- ---------------------------------------------------------------------------
  -- SEKCIJA 2: COPILOT CHAT INTERFEJS
  -- ---------------------------------------------------------------------------
  -- (Ostatak tvog koda za chat ostaje potpuno identičan, jer je savršeno
  -- iskonfigurisan i problem je bio samo u Ghost text sekciji iznad).
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
