-- ========================================================================== --
--                                KEYMAPS.LUA                                 --
--                                                                            --
--  Glavni komandni centar za korisničke prečice na tastaturi.                --
--  Napomena: LazyVim koristi <leader> taster, koji je po defaultu 'Space'.   --
-- ========================================================================== --

local map = vim.keymap.set

-- -----------------------------------------------------------------------------
-- 1. NAVIGACIJA I UPRAVLJANJE BUFFERIMA (TABOVIMA)
-- -----------------------------------------------------------------------------
-- Kretanje kroz otvorene fajlove
map("n", "<Tab>", "<cmd>bnext<CR>", { desc = "Switch to next file (tab)" })
map("n", "<S-Tab>", "<cmd>bprevious<CR>", { desc = "Switch to previous file (tab)" })

-- Brzo zatvaranje trenutnog fajla
map("n", "<leader>x", "<cmd>bdelete<CR>", { desc = "Close current tab/file" })

-- Fizičko pomjeranje tabova u gornjoj traci (Bufferline reorganizacija)
map("n", "<leader>b>", "<cmd>BufferLineMoveNext<CR>", { desc = "Move current tab to the right" })
map("n", "<leader>b<", "<cmd>BufferLineMovePrev<CR>", { desc = "Move current tab to the left" })

-- -----------------------------------------------------------------------------
-- 2. ALATI ZA KODIRANJE (FORMATIRANJE)
-- -----------------------------------------------------------------------------
-- Ručno formatiranje koda.
-- Preporuka: koristimo <leader>lf umjesto <leader>cf da ne ulazi u konflikt
-- sa Copilot Chat komandama koje koriste <leader>c...
map({ "n", "v" }, "<leader>lf", function()
  require("conform").format({ async = true, lsp_fallback = true })
end, { desc = "Format selected code or whole file" })

-- -----------------------------------------------------------------------------
-- 3. PRECIZNO OTVARANJE NOVOG REDA ISPOD TRENUTNOG REDA
-- -----------------------------------------------------------------------------
-- Prečica:
--   o u normal modu
--
-- Zašto ovo postoji?
--   Obični Neovim 'o' u C/C++/Java fajlovima pokušava "pametno" odrediti
--   indentaciju prema strukturi bloka. To je često korisno, ali nije ono
--   što ti želiš.
--
--   Ti želiš:
--
--   1. Ako je trenutna linija početak bloka:
--        void foo() {
--      novi red treba dobiti dodatni indent nivo.
--
--   2. Ako si već unutar bloka:
--            nekaLinija();
--      novi red treba zadržati isti indent.
--
--   3. Ako si ručno napravio dublju indentaciju:
--                posebnaLinija();
--      novi red MORA ostati na toj istoj dubljoj indentaciji,
--      bez vraćanja na "standardni" indent bloka.
--
-- Primjer koji mora raditi:
--
--   int main() {
--       const int a = 10;
--           const int b = 20;
--           |  <- nakon ESC + o sa linije const int b = 20;
--       return 0;
--   }
--
-- Dodatno:
--   Ako je '{' prije inline komentara, npr.
--        void foo() { // komentar
--   i dalje se prepoznaje da treba ući jedan nivo dublje.

local function open_line_below_with_relative_indent()
  local current_line = vim.api.nvim_get_current_line()
  local current_row = vim.api.nvim_win_get_cursor(0)[1]

  -- Uzimamo TAČNO postojeću početnu indentaciju trenutne linije.
  -- Ako linija ima 8 razmaka, novi red će krenuti sa 8 razmaka.
  local current_indent = current_line:match("^%s*") or ""

  -- Za odluku o dodatnom indentu ignorišemo:
  --   - whitespace na kraju reda
  --   - inline // komentar na kraju reda
  local code_part = current_line
    :gsub("%s+$", "")
    :gsub("%s*//.*$", "")
    :gsub("%s+$", "")

  -- Ako linija završava otvaranjem bloka ili zagrade,
  -- dodaj još jedan indent nivo.
  local extra_indent = ""
  if code_part:match("[{[(]$") then
    local shiftwidth = vim.bo.shiftwidth
    if shiftwidth == 0 then
      shiftwidth = vim.o.shiftwidth
    end
    extra_indent = string.rep(" ", shiftwidth)
  end

  local new_line = current_indent .. extra_indent

  -- Direktno ubacujemo novi red ispod trenutnog reda.
  -- Ovo zaobilazi defaultni Neovim 'o' indent mehanizam.
  vim.api.nvim_buf_set_lines(0, current_row, current_row, false, { new_line })

  -- Kursor ide na kraj pripremljene indentacije.
  vim.api.nvim_win_set_cursor(0, { current_row + 1, #new_line })

  -- Ulazak u Insert mode na novoj liniji.
  vim.cmd("startinsert!")
end

-- Globalni map za 'o'
map("n", "o", open_line_below_with_relative_indent, {
  desc = "Open line below with exact relative indentation",
})

-- [FIX SMAJO]
-- Dodatno osiguranje:
--   Kada se učita konkretan filetype (.cpp, .java, .ts, ...),
--   ponovo postavljamo buffer-local 'o' map.
--
-- Zašto?
--   Ako filetype plugin ili neki drugi dio konfiguracije naknadno promijeni
--   ponašanje 'o', ovaj buffer-local map opet pobjeđuje i zadržava tvoju logiku.
vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("SmajoExactOpenLineIndent", { clear = true }),
  callback = function(args)
    vim.keymap.set("n", "o", open_line_below_with_relative_indent, {
      buffer = args.buf,
      desc = "Open line below with exact relative indentation",
    })
  end,
})

-- -----------------------------------------------------------------------------
-- NAPOMENA ZA AI ASISTENTA
-- -----------------------------------------------------------------------------
-- Copilot prečice se NAMJERNO ne nalaze u ovom fajlu.
-- Sve Copilot mape su centralizovane u:
--   lua/plugins/copilot.lua
--
-- Zašto?
--   Da ne dođe do dupliranja kao kod <leader>cc.
--   keymaps.lua ostaje za opšte editor komande, a copilot.lua za AI komande.

-- -----------------------------------------------------------------------------
-- 4. TERMINAL I POKRETANJE PROGRAMA
-- -----------------------------------------------------------------------------
-- Spas iz terminal moda: Dupli ESC te vraća u normalni Neovim mod
map("t", "<Esc><Esc>", "<C-\\><C-n>", { desc = "Exit terminal mode to normal mode" })

-- -----------------------------------------------------------------------------
-- [NOVO SMAJO] TERMINAL PANEL SA VIŠE TERMINALA U ISTOM PROSTORU
-- -----------------------------------------------------------------------------
-- Ideja:
--   Umjesto da se svaki novi terminal otvara kao novi split jedan iznad drugog,
--   sada imamo:
--
--     - JEDAN donji terminal panel
--     - VIŠE terminal buffer sesija unutar tog panela
--     - prebacivanje između terminala kao između "terminal tabova"
--
-- Vizuelno:
--   Iznad terminal panela prikazuje se winbar, npr:
--
--      Terminali:  [1]   2   3
--
--   Aktivni terminal je označen uglastim zagradama.
--
-- Prečice:
--   <leader>ot = Space + o + t
--     Toggle cijelog terminal panela.
--
--   <leader>oT = Space + o + Shift+t
--     Otvara novi dodatni terminal u ISTOM donjem panelu.
--
--   <leader>on = Space + o + n
--     Prebaci na sljedeći terminal.
--
--   <leader>op = Space + o + p
--     Prebaci na prethodni terminal.
--
--   <leader>ok = Space + o + k
--     Sakrij cijeli terminal panel, ali terminali ostaju živi.
--
--   <leader>oq = Space + o + q
--     Ubij trenutno aktivni terminal.
--
-- Važna napomena:
--   Ove prečice su namjerno definisane samo u NORMAL modu.
--   Pošto ti je <leader> = Space, kada bismo ih mapirali i u terminal modu,
--   Neovim bi imao zadršku pri svakom normalnom kucanju razmaka u shellu.
--
--   Zato je workflow iz terminala:
--     1. Esc Esc
--     2. Space + o + ...
--
-- Šta zadržavamo iz prethodnog rješenja:
--   - ako je explorer otvoren lijevo, terminal panel je desno od njega
--   - terminal ne ulazi ispod explorera
--   - terminal ima winfixheight i ne raste ružno pri Niri resize-u
--   - terminal bufferi su unlisted i ne smetaju <Tab>/<S-Tab> navigaciji

-- Lista svih terminal buffera kojima upravlja ovaj panel.
local terminal_buffers = {}

-- Indeks trenutno aktivnog terminala u terminal_buffers.
local active_terminal_index = nil

-- Window ID donjeg terminal panela.
-- Ako je nil ili nevalidan, panel je skriven/zatvoren.
local terminal_panel_win = nil

-- Pomoćna funkcija:
-- Provjerava da li je buffer validan terminal buffer.
local function is_valid_terminal_buffer(buf)
  return buf
    and vim.api.nvim_buf_is_valid(buf)
    and vim.bo[buf].buftype == "terminal"
end

-- Pomoćna funkcija:
-- Uklanja iz naše liste terminale koji više ne postoje.
-- Ovo je korisno ako neki terminal buffer nestane ručno ili neočekivano.
local function cleanup_terminal_buffers()
  local cleaned = {}
  local new_active_index = nil

  for index, buf in ipairs(terminal_buffers) do
    if is_valid_terminal_buffer(buf) then
      table.insert(cleaned, buf)

      if active_terminal_index == index then
        new_active_index = #cleaned
      end
    end
  end

  terminal_buffers = cleaned

  if #terminal_buffers == 0 then
    active_terminal_index = nil
  else
    active_terminal_index = new_active_index or math.min(active_terminal_index or 1, #terminal_buffers)
  end
end

-- Pomoćna funkcija:
-- Pronalazi najširi normalni prozor u trenutnom tabu.
--
-- U tvojoj tipičnoj postavci to znači:
--   - editor prozor desno od explorera, ako je explorer otvoren
--   - obični glavni editor prozor, ako explorer nije otvoren
local function find_main_editor_like_window()
  local current_tab = vim.api.nvim_get_current_tabpage()
  local windows = vim.api.nvim_tabpage_list_wins(current_tab)

  local best_window = nil
  local best_width = -1

  for _, win in ipairs(windows) do
    if vim.api.nvim_win_is_valid(win) then
      local win_config = vim.api.nvim_win_get_config(win)

      -- Ignorišemo floating prozore; zanimaju nas samo pravi layout splitovi.
      if win_config.relative == "" then
        local buf = vim.api.nvim_win_get_buf(win)
        local buftype = vim.bo[buf].buftype

        -- Ne želimo kao osnovu koristiti terminal panel ili terminal buffere.
        if buftype ~= "terminal" then
          local width = vim.api.nvim_win_get_width(win)

          -- Najširi normalni prozor je u tvojoj konfiguraciji
          -- praktično uvijek glavni editor dio desno od explorera.
          if width > best_width then
            best_width = width
            best_window = win
          end
        end
      end
    end
  end

  -- Fallback: ako iz nekog razloga ne pronađemo bolji kandidat,
  -- koristimo trenutno fokusirani prozor.
  return best_window or vim.api.nvim_get_current_win()
end

-- Pomoćna funkcija:
-- Provjerava da li je terminal panel trenutno vidljiv.
local function is_terminal_panel_visible()
  return terminal_panel_win and vim.api.nvim_win_is_valid(terminal_panel_win)
end

-- Pomoćna funkcija:
-- Podešava winbar terminal panela:
--
--    Terminali:  [1]   2   3
--
-- Aktivni terminal je označen uglastim zagradama.
local function update_terminal_winbar()
  if not is_terminal_panel_visible() then
    return
  end

  cleanup_terminal_buffers()

  if #terminal_buffers == 0 then
    vim.wo[terminal_panel_win].winbar = "  Terminali: nema otvorenih terminala "
    return
  end

  local labels = {}

  for index, _ in ipairs(terminal_buffers) do
    if index == active_terminal_index then
      table.insert(labels, "[" .. index .. "]")
    else
      table.insert(labels, tostring(index))
    end
  end

  vim.wo[terminal_panel_win].winbar = "  Terminali:  " .. table.concat(labels, "   ") .. " "
end

-- Pomoćna funkcija:
-- Daje terminal bufferu poželjne osobine.
local function configure_current_terminal_buffer()
  -- Terminali se ne pojavljuju u tvojoj regularnoj <Tab>/<S-Tab> buffer navigaciji.
  vim.bo.buflisted = false

  -- Kad se terminal sakrije, njegov buffer i proces ostaju živi.
  vim.bo.bufhidden = "hide"

  -- Donji panel zadržava visinu stabilnijom pri promjenama layouta.
  -- Ovo je ono što ti je već lijepo riješilo Niri resize problem.
  vim.wo.winfixheight = true
end

-- Pomoćna funkcija:
-- Otvara prazan donji terminal panel ispod glavnog editora.
-- Još ne bira koji će terminal buffer biti prikazan.
local function open_terminal_panel_window()
  local target_window = find_main_editor_like_window()

  if vim.api.nvim_win_is_valid(target_window) then
    vim.api.nvim_set_current_win(target_window)
  end

  -- Otvara panel ispod glavnog editor prozora,
  -- tako da explorer ostaje njegova lijeva granica.
  vim.cmd("belowright split | resize 10")

  terminal_panel_win = vim.api.nvim_get_current_win()

  -- Zaključavamo visinu samog panela.
  vim.wo.winfixheight = true
end

-- Pomoćna funkcija:
-- Prikaže dati terminal buffer u donjem panelu.
local function show_terminal_buffer(index)
  cleanup_terminal_buffers()

  if #terminal_buffers == 0 then
    vim.notify("Nema otvorenih terminala.", vim.log.levels.WARN)
    return
  end

  if index < 1 then
    index = #terminal_buffers
  elseif index > #terminal_buffers then
    index = 1
  end

  active_terminal_index = index
  local target_buf = terminal_buffers[active_terminal_index]

  if not is_valid_terminal_buffer(target_buf) then
    cleanup_terminal_buffers()
    return
  end

  if not is_terminal_panel_visible() then
    open_terminal_panel_window()
  else
    vim.api.nvim_set_current_win(terminal_panel_win)
  end

  vim.api.nvim_win_set_buf(terminal_panel_win, target_buf)

  configure_current_terminal_buffer()
  update_terminal_winbar()

  -- Kad se prebaciš na terminal, odmah možeš kucati.
  vim.cmd("startinsert")
end

-- Pomoćna funkcija:
-- Kreira potpuno novi terminal i smjesti ga u isti donji panel.
local function create_new_terminal()
  cleanup_terminal_buffers()

  if not is_terminal_panel_visible() then
    open_terminal_panel_window()
  else
    vim.api.nvim_set_current_win(terminal_panel_win)
  end

  -- :terminal pravi novi terminal buffer u trenutnom windowu.
  -- Prethodno prikazani terminal ostaje živ, samo se sakrije u pozadini.
  vim.cmd("terminal")

  local new_terminal_buf = vim.api.nvim_get_current_buf()

  configure_current_terminal_buffer()

  table.insert(terminal_buffers, new_terminal_buf)
  active_terminal_index = #terminal_buffers

  update_terminal_winbar()

  vim.cmd("startinsert")
end

-- Pomoćna funkcija:
-- Sakriva cijeli terminal panel, ali svi terminal procesi ostaju živi.
local function hide_terminal_panel()
  if not is_terminal_panel_visible() then
    return
  end

  local panel_win = terminal_panel_win
  terminal_panel_win = nil

  pcall(vim.api.nvim_win_close, panel_win, false)
end

-- Pomoćna funkcija:
-- Ubij trenutno aktivni terminal.
--
-- Ako poslije brisanja ostane još terminala:
--   - u istom panelu se automatski prikaže sljedeći/prethodni terminal.
--
-- Ako ne ostane nijedan:
--   - terminal panel se zatvori.
local function kill_active_terminal()
  cleanup_terminal_buffers()

  if #terminal_buffers == 0 or not active_terminal_index then
    vim.notify("Nema aktivnog terminala za zatvaranje.", vim.log.levels.WARN)
    return
  end

  local buf_to_kill = terminal_buffers[active_terminal_index]

  if is_valid_terminal_buffer(buf_to_kill) then
    pcall(vim.api.nvim_buf_delete, buf_to_kill, { force = true })
  end

  table.remove(terminal_buffers, active_terminal_index)

  if #terminal_buffers == 0 then
    active_terminal_index = nil
    hide_terminal_panel()
    return
  end

  if active_terminal_index > #terminal_buffers then
    active_terminal_index = #terminal_buffers
  end

  show_terminal_buffer(active_terminal_index)
end

-- -----------------------------------------------------------------------------
-- Space + o + t
-- Toggle terminal panela
-- -----------------------------------------------------------------------------
-- Ponašanje:
--   - ako nema nijednog terminala -> napravi prvi
--   - ako panel nije vidljiv, ali terminali postoje -> prikaži aktivni
--   - ako panel jeste vidljiv -> sakrij cijeli panel
map("n", "<leader>ot", function()
  cleanup_terminal_buffers()

  if #terminal_buffers == 0 then
    create_new_terminal()
    return
  end

  if is_terminal_panel_visible() then
    hide_terminal_panel()
    return
  end

  show_terminal_buffer(active_terminal_index or 1)
end, { desc = "Toggle terminal panel" })

-- -----------------------------------------------------------------------------
-- Space + o + T
-- Novi dodatni terminal u istom panelu
-- -----------------------------------------------------------------------------
map("n", "<leader>oT", function()
  create_new_terminal()
end, { desc = "Create extra terminal in terminal panel" })

-- -----------------------------------------------------------------------------
-- Space + o + n
-- Sljedeći terminal
-- -----------------------------------------------------------------------------
map("n", "<leader>on", function()
  cleanup_terminal_buffers()

  if #terminal_buffers == 0 then
    vim.notify("Nema otvorenih terminala.", vim.log.levels.WARN)
    return
  end

  local next_index = (active_terminal_index or 1) + 1
  if next_index > #terminal_buffers then
    next_index = 1
  end

  show_terminal_buffer(next_index)
end, { desc = "Next terminal" })

-- -----------------------------------------------------------------------------
-- Space + o + p
-- Prethodni terminal
-- -----------------------------------------------------------------------------
map("n", "<leader>op", function()
  cleanup_terminal_buffers()

  if #terminal_buffers == 0 then
    vim.notify("Nema otvorenih terminala.", vim.log.levels.WARN)
    return
  end

  local prev_index = (active_terminal_index or 1) - 1
  if prev_index < 1 then
    prev_index = #terminal_buffers
  end

  show_terminal_buffer(prev_index)
end, { desc = "Previous terminal" })

-- -----------------------------------------------------------------------------
-- Space + o + k
-- Sakrij terminal panel
-- -----------------------------------------------------------------------------
map("n", "<leader>ok", function()
  hide_terminal_panel()
end, { desc = "Hide terminal panel" })

-- -----------------------------------------------------------------------------
-- Space + o + q
-- Ubij trenutno aktivni terminal
-- -----------------------------------------------------------------------------
map("n", "<leader>oq", function()
  kill_active_terminal()
end, { desc = "Kill active terminal" })

-- -----------------------------------------------------------------------------
-- 5. UNIVERZALNI RUNNER ZA STUDENTSKI WORKFLOW
-- -----------------------------------------------------------------------------
-- Opis:
--   Centralizovana funkcija za pokretanje komandi u donjem terminalu.
--   Java, C++ i OpenGL sada koriste isti stil:
--     1. snimi fajl
--     2. kompajliraj/pokreni
--     3. prikaži jasnu liniju razdvajanja
--     4. čekaj ENTER prije zatvaranja
--
-- Zašto ovo?
--   Da ponašanje bude konzistentno i predvidivo kao u IDE-u.
local function run_in_bottom_terminal(cmd, title)
  title = title or "Program"

  local wrapped_cmd = string.format(
    "echo '▶ %s'; echo '---------------------------------'; %s; " ..
    "status=$?; echo ''; echo '---------------------------------'; " ..
    "if [ $status -eq 0 ]; then echo '✅ Finished successfully.'; else echo '❌ Finished with errors.'; fi; " ..
    "echo 'Press ENTER to close...'; read",
    title,
    cmd
  )

  require("snacks").terminal(wrapped_cmd, {
    win = {
      position = "bottom",
      height = 0.4,
      border = "rounded",
      title = " " .. title .. " ",
    },
  })
end

-- Pomoćna funkcija: shell escape za putanje sa razmacima.
local function shesc(value)
  return vim.fn.shellescape(value)
end

-- Pomoćna funkcija: provjerava da li fajl ili folder postoji.
local function exists(path)
  return vim.fn.filereadable(path) == 1 or vim.fn.isdirectory(path) == 1
end

-- Pomoćna funkcija: spajanje putanja bez ručnog peglanja slash-eva.
local function join_paths(...)
  return table.concat({ ... }, "/"):gsub("//+", "/")
end

-- Pomoćna funkcija: pronalazi najbliži roditeljski folder koji sadrži marker.
-- Markeri su stvari koje obično označavaju Java projekat:
--   .project      = Eclipse projekat
--   .classpath    = Eclipse classpath
--   pom.xml       = Maven projekat
--   build.gradle  = Gradle projekat
--   src           = običan studentski Java projekat
local function find_upwards(start_dir, markers)
  local dir = vim.fn.fnamemodify(start_dir, ":p")

  while dir ~= "/" do
    for _, marker in ipairs(markers) do
      if exists(join_paths(dir, marker)) then
        return vim.fn.fnamemodify(dir, ":p:h")
      end
    end

    local parent = vim.fn.fnamemodify(dir, ":h")
    if parent == dir then
      break
    end
    dir = parent
  end

  return nil
end

-- Pomoćna funkcija: čita package deklaraciju iz Java fajla.
-- Primjer:
--   package ba.etf.rpr;
-- vraća:
--   ba.etf.rpr
local function get_java_package(filepath)
  local lines = vim.fn.readfile(filepath)

  for _, line in ipairs(lines) do
    local package_name = line:match("^%s*package%s+([%w%._]+)%s*;")
    if package_name then
      return package_name
    end
  end

  return ""
end

-- Pomoćna funkcija: provjerava da li trenutni Java fajl ima main metodu.
-- Ovo sprječava slučajno pokretanje klase koja nema entry point.
local function java_file_has_main(filepath)
  local content = table.concat(vim.fn.readfile(filepath), "\n")

  return content:match("public%s+static%s+void%s+main%s*%(%s*String%s*%[%s*%]%s*%w+%s*%)")
    or content:match("public%s+static%s+void%s+main%s*%(%s*String%s+%w+%[%s*%]%s*%)")
end

-- Pomoćna funkcija: pokušava pronaći root trenutnog Java projekta.
-- Prioritet:
--   1. najbliži Eclipse/Maven/Gradle projekat
--   2. najbliži folder koji sadrži src
--   3. trenutni working directory
local function find_java_project_root(filepath)
  local file_dir = vim.fn.fnamemodify(filepath, ":p:h")

  local project_root = find_upwards(file_dir, {
    ".project",
    ".classpath",
    "pom.xml",
    "build.gradle",
    "build.gradle.kts",
    "settings.gradle",
    "settings.gradle.kts",
    "src",
  })

  return project_root or vim.fn.getcwd()
end

-- Pomoćna funkcija: pronalazi Java source root.
-- Podržava najčešće strukture:
--   src/main/java
--   src/test/java
--   src
--   trenutni projekat bez src foldera
local function find_java_source_root(filepath, project_root)
  local normalized_file = vim.fn.fnamemodify(filepath, ":p")
  local candidates = {
    join_paths(project_root, "src/main/java"),
    join_paths(project_root, "src/test/java"),
    join_paths(project_root, "src"),
    project_root,
  }

  for _, candidate in ipairs(candidates) do
    local normalized_candidate = vim.fn.fnamemodify(candidate, ":p")

    if vim.fn.isdirectory(normalized_candidate) == 1 and normalized_file:sub(1, #normalized_candidate) == normalized_candidate then
      return vim.fn.fnamemodify(normalized_candidate, ":p:h")
    end
  end

  return project_root
end

-- Pomoćna funkcija: čita Eclipse .classpath i pronalazi dodatne source foldere.
-- Ovo je bitno za Eclipse workspace projekte koji mogu imati više source foldera.
local function get_eclipse_source_roots(project_root)
  local classpath_file = join_paths(project_root, ".classpath")
  local roots = {}

  if vim.fn.filereadable(classpath_file) == 0 then
    return roots
  end

  for _, line in ipairs(vim.fn.readfile(classpath_file)) do
    local src_path = line:match('kind="src"%s+path="([^"]+)"') or line:match('path="([^"]+)"%s+kind="src"')

    if src_path and src_path ~= "" then
      local full_path = join_paths(project_root, src_path)

      if vim.fn.isdirectory(full_path) == 1 then
        table.insert(roots, full_path)
      end
    end
  end

  return roots
end

-- Pomoćna funkcija: pravi listu source rootova za kompajliranje.
-- Ovo omogućava da klase iz drugih paketa u istom projektu budu dostupne.
local function get_java_source_roots(project_root)
  local roots = {}

  local eclipse_roots = get_eclipse_source_roots(project_root)
  for _, root in ipairs(eclipse_roots) do
    table.insert(roots, root)
  end

  local common_roots = {
    join_paths(project_root, "src/main/java"),
    join_paths(project_root, "src/test/java"),
    join_paths(project_root, "src"),
  }

  for _, root in ipairs(common_roots) do
    if vim.fn.isdirectory(root) == 1 then
      table.insert(roots, root)
    end
  end

  -- Ako nema src foldera, tretiramo cijeli projekat kao source root.
  if #roots == 0 then
    table.insert(roots, project_root)
  end

  -- Uklanjanje duplikata.
  local seen = {}
  local unique_roots = {}

  for _, root in ipairs(roots) do
    local normalized = vim.fn.fnamemodify(root, ":p:h")
    if not seen[normalized] then
      seen[normalized] = true
      table.insert(unique_roots, normalized)
    end
  end

  return unique_roots
end

-- Pomoćna funkcija: pravi puno ime Java klase.
-- Ako fajl ima package, koristi package + ime klase.
-- Ako nema package, koristi samo ime klase.
local function get_java_main_class(filepath)
  local package_name = get_java_package(filepath)
  local class_name = vim.fn.fnamemodify(filepath, ":t:r")

  if package_name ~= "" then
    return package_name .. "." .. class_name
  end

  return class_name
end

-- Pomoćna funkcija: automatski dodaje lokalne .jar biblioteke u classpath.
-- Podržava česte studentske/Eclipse foldere:
--   lib/
--   libs/
--   target/classes
--   build/classes/java/main
--   build/resources/main
local function get_java_classpath(project_root, build_dir)
  local classpath_parts = {
    build_dir,
    join_paths(project_root, "target/classes"),
    join_paths(project_root, "build/classes/java/main"),
    join_paths(project_root, "build/resources/main"),
  }

  local jar_dirs = {
    join_paths(project_root, "lib"),
    join_paths(project_root, "libs"),
  }

  for _, jar_dir in ipairs(jar_dirs) do
    if vim.fn.isdirectory(jar_dir) == 1 then
      table.insert(classpath_parts, join_paths(jar_dir, "*"))
    end
  end

  return table.concat(classpath_parts, ":")
end

-- -----------------------------------
-- [Pisanje i kompajliranje: JAVA]
-- -----------------------------------
-- Prečica:
--   <leader>rj = Space + r + j
--
-- Kako koristiti:
--   1. Pokreni workspace:
--        nvim ~/eclipse-workspace
--
--   2. Otvori bilo koji Java fajl koji ima main metodu.
--
--   3. Pritisni:
--        Space + r + j
--
-- Šta ova komanda radi:
--   - automatski pronađe root projekta
--   - automatski pronađe src folder
--   - pročita package iz trenutnog fajla
--   - kompajlira sve .java fajlove iz projekta
--   - pokrene trenutnu klasu kao main klasu
--
-- Bitna napomena:
--   Ovo rješava povezane klase i pakete unutar istog projekta.
--   Ako koristiš vanjske .jar biblioteke, stavi ih u lib/ ili libs/ folder projekta.
map("n", "<leader>rj", function()
  if vim.bo.filetype ~= "java" then
    vim.notify("Ova komanda radi samo unutar Java fajla.", vim.log.levels.WARN)
    return
  end

  vim.cmd("silent! write")

  local filepath = vim.fn.expand("%:p")

  if not java_file_has_main(filepath) then
    vim.notify("Trenutni Java fajl nema public static void main(String[] args).", vim.log.levels.WARN)
    return
  end

  local project_root = find_java_project_root(filepath)
  local source_root = find_java_source_root(filepath, project_root)
  local source_roots = get_java_source_roots(project_root)
  local main_class = get_java_main_class(filepath)

  -- Build folder je sakriven unutar projekta.
  -- Ne prlja ti src folder .class fajlovima.
  local build_dir = join_paths(project_root, ".nvim-java-build", "classes")
  local classpath = get_java_classpath(project_root, build_dir)

  local find_sources_parts = {}
  for _, root in ipairs(source_roots) do
    table.insert(find_sources_parts, shesc(root))
  end

  local source_roots_for_find = table.concat(find_sources_parts, " ")

  local cmd = string.format(
    "cd %s && " ..
    "mkdir -p %s && " ..
    "find %s -name '*.java' > .nvim-java-build/sources.txt && " ..
    "javac -encoding UTF-8 -cp %s -d %s @.nvim-java-build/sources.txt && " ..
    "java -cp %s %s",
    shesc(project_root),
    shesc(build_dir),
    source_roots_for_find,
    shesc(classpath),
    shesc(build_dir),
    shesc(classpath),
    shesc(main_class)
  )

  local title = "Java: " .. main_class

  vim.notify(
    "Java project root: " .. project_root .. "\n" ..
    "Java source root: " .. source_root .. "\n" ..
    "Java main class: " .. main_class,
    vim.log.levels.INFO
  )

  run_in_bottom_terminal(cmd, title)
end, { desc = "Compile and run Java workspace project" })

-- -----------------------------------
-- [Pisanje i kompajliranje: C++]
-- -----------------------------------
-- Prečica:
--   <leader>rc = Space + r + c
--
-- Kako koristiti:
--   1. Budi u .cpp fajlu koji želiš kompajlirati.
--   2. Pritisni Space + r + c.
--   3. Program se kompajlira u /tmp, tako da ti ne prlja projekat dodatnim binarnim fajlovima.
map("n", "<leader>rc", function()
  if vim.bo.filetype ~= "cpp" then
    vim.notify("Ova komanda radi samo unutar C++ fajla.", vim.log.levels.WARN)
    return
  end

  vim.cmd("silent! write")

  local filename = vim.fn.expand("%:p")
  local basename = vim.fn.expand("%:t:r")
  local output = "/tmp/" .. basename

  local cmd = string.format(
    "clang++ -std=c++20 -Wall -Wextra -O2 %s -o %s && %s",
    shesc(filename),
    shesc(output),
    shesc(output)
  )

  run_in_bottom_terminal(cmd, "C++: " .. basename)
end, { desc = "Compile and run C++ program (Standard)" })

-- -----------------------------------
-- [Pisanje i kompajliranje: C++ OpenGL]
-- -----------------------------------
-- Prečica:
--   <leader>ro = Space + r + o
--
-- Kako koristiti:
--   1. Budi u .cpp fajlu za OpenGL/GLUT vježbu.
--   2. Pritisni Space + r + o.
--   3. Kompajlira se sa -lGL -lGLU -lglut.
map("n", "<leader>ro", function()
  if vim.bo.filetype ~= "cpp" then
    vim.notify("Ova komanda radi samo unutar C++ fajla.", vim.log.levels.WARN)
    return
  end

  vim.cmd("silent! write")

  local filename = vim.fn.expand("%:p")
  local basename = vim.fn.expand("%:t:r")
  local output = "/tmp/" .. basename .. "_opengl"

  local cmd = string.format(
    "g++ -std=c++20 -Wall -Wextra -O2 %s -o %s -lGL -lGLU -lglut && %s",
    shesc(filename),
    shesc(output),
    shesc(output)
  )

  run_in_bottom_terminal(cmd, "OpenGL C++: " .. basename)
end, { desc = "Compile and run C++ OpenGL program" })
