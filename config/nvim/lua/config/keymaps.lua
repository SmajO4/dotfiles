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
-- 3. TERMINAL I POKRETANJE PROGRAMA
-- -----------------------------------------------------------------------------
-- Spas iz terminal moda: Dupli ESC te vraća u normalni Neovim mod
map("t", "<Esc><Esc>", "<C-\\><C-n>", { desc = "Exit terminal mode to normal mode" })

-- Obični, prazni terminal za manuelni unos komandi
map("n", "<leader>ot", function()
  vim.cmd("botright split | resize 10 | terminal")
end, { desc = "Open standard terminal at the bottom" })

-- -----------------------------------------------------------------------------
-- 4. UNIVERZALNI RUNNER ZA STUDENTSKI WORKFLOW
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
