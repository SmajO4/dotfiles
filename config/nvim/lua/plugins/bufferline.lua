-- ========================================================================== --
--                             BUFFERLINE.LUA                                 --
--                                                                            --
--  Upravlja gornjom trakom editora koja prikazuje otvorene fajlove           --
--  u obliku tabova (slično kao u web browseru ili klasičnom IDE-u).          --
-- ========================================================================== --

return {
  {
    "akinsho/bufferline.nvim",
    opts = function(_, opts)
      opts.options = opts.options or {}

      -- -----------------------------------------------------------------------
      -- PAMETNA LOGIKA: Umjesto da pogađamo gdje ti je kursor (dashboard,
      -- explorer), jednostavno brojimo "stvarne" fajlove u pozadini.
      -- Dashboard, neo-tree i lazy su sistemski fajlovi i oni se ne broje.
      -- -----------------------------------------------------------------------
      local function has_real_file_open()
        for _, buf in ipairs(vim.api.nvim_list_bufs()) do
          -- 'buflisted' znači da je to fajl koji treba da ima tab na vrhu
          if vim.fn.buflisted(buf) == 1 and vim.api.nvim_buf_is_valid(buf) then
            local name = vim.api.nvim_buf_get_name(buf)
            local ft = vim.bo[buf].filetype
            -- Ignorišemo onaj početni prazni fajl koji Neovim otvori prije dashboarda
            local is_empty = (name == "" and ft == "" and not vim.bo[buf].modified)
            
            if not is_empty then
              return true -- Pronašli smo barem 1 pravi fajl (Java, C++, txt...)!
            end
          end
        end
        return false -- Nema pravih fajlova, znači tu su samo Dashboard ili Explorer
      end

      -- 1. Provjeravamo stanje prilikom samog učitavanja Neovima
      opts.options.always_show_bufferline = has_real_file_open()

      -- 2. Postavljamo pravilo koje prati tvoje kretanje (uživo)
      -- Dodali smo BufAdd i BufDelete da okine tačno u trenutku otvaranja/brisanja fajla
      vim.api.nvim_create_autocmd({ "BufAdd", "BufDelete", "BufEnter", "WinEnter" }, {
        group = vim.api.nvim_create_augroup("DynamicBufferlineAlwaysShow", { clear = true }),
        callback = function()
          -- vim.schedule osigurava da pluginovi (explorer) završe otvaranje prije provjere
          vim.schedule(function()
            local we_have_files = has_real_file_open()

            -- Pristupamo dubokim unutrašnjim postavkama aktivnog bufferline plugina
            local ok, bufferline_config = pcall(require, "bufferline.config")
            if ok and bufferline_config.options then
              -- Mijenjamo pravilo u letu: true ako imamo fajlove, false ako nemamo
              bufferline_config.options.always_show_bufferline = we_have_files
            end

            -- Ručno gasimo ili palimo traku za savršen prijelaz bez crne linije
            if we_have_files then
              vim.opt.showtabline = 2
            else
              vim.opt.showtabline = 0
            end
          end)
        end,
      })
    end,
  },
}
