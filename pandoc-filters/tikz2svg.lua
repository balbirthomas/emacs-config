-- tikz2svg.lua
--
-- For lang-markdown.el (markdown-command). MathJax renders $...$/$$...$$
-- math client-side, but it cannot render TikZ. This filter finds TikZ
-- diagrams written in either of two styles:
--
--   1. A bare `\begin{tikzpicture}...\end{tikzpicture}' (or pgfpicture)
--      environment directly in the Markdown source, which parses as a
--      `RawBlock (Format "tex")` (via the raw_tex extension), or as an
--      explicit ```{=latex} ... ``` raw block, which parses as
--      `RawBlock (Format "latex")`.
--   2. A ```tikz-fenced code block in the style of the vscode-tikz
--      VS Code extension (https://github.com/kevinyuan/vscode-tikz),
--      which parses as `CodeBlock ("", ["tikz"], []) "..."`. Its
--      content is a full `\begin{document}...\end{document}' body
--      (optionally with `\usepackage{...}' lines before
--      `\begin{document}'), not just the bare environment.
--
-- For non-LaTeX output formats such as HTML, each is compiled via
-- pdflatex + dvisvgm into an SVG, cached by content hash in a
-- ".tikz-cache/" directory next to wherever Pandoc is run, then embedded
-- directly as a base64 data: URI (not a file path) so the image survives
-- being moved to a different directory -- which markdown-mode's
-- `markdown-preview' always does (it writes the compiled HTML to a temp
-- file elsewhere before browsing it). This filter deliberately does its
-- own embedding rather than relying on Pandoc's `--embed-resources':
-- that flag also tries to fetch and embed the MathJax <script src> tag
-- itself, and on any network hiccup silently embeds whatever bytes came
-- back (an error page, even a random domain's homepage if the URL
-- doesn't resolve as expected) instead of failing loudly -- and even on
-- a working connection, MathJax dynamically loads more of itself at
-- *view* time in the browser, so a one-shot embed can't make it fully
-- offline-capable anyway. So lang-markdown.el's Pandoc invocation does
-- not pass `--embed-resources' at all; only this filter's own images are
-- embedded, and MathJax is left as a plain, working external URL.
--
-- For LaTeX/PDF output, style 1 is left untouched (it already IS a raw
-- latex block, compiles natively -- see tikz-preamble.tex). Style 2
-- can't be left untouched: it's a genuine CodeBlock, which the LaTeX
-- writer would otherwise typeset as a preformatted code listing, and its
-- content can't be spliced in verbatim either, since it has its own
-- `\begin{document}...\end{document}' and the surrounding document
-- already has one. So just the tikzpicture/pgfpicture environment is
-- extracted out of it and emitted as raw latex; any `\usepackage' lines
-- before that fence's `\begin{document}' are NOT carried over to PDF
-- export (add them to tikz-preamble.tex as well if you need them there).

local cache_dir = ".tikz-cache"

-- Pure-Lua base64 encoder (no external `base64' dependency). Works three
-- bytes at a time via a lookup table so multi-megabyte photos (see the
-- Image handler below) encode in well under a second.
local b64chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
local b64 = {}
for i = 1, 64 do b64[i - 1] = b64chars:sub(i, i) end
local function base64_encode(data)
  local out, n = {}, 0
  local len = #data
  for i = 1, len - 2, 3 do
    local a, b, c = data:byte(i, i + 2)
    local v = a * 65536 + b * 256 + c
    n = n + 1
    out[n] = b64[v >> 18] .. b64[(v >> 12) & 63] .. b64[(v >> 6) & 63] .. b64[v & 63]
  end
  local rest = len % 3
  if rest == 1 then
    local a = data:byte(len)
    n = n + 1
    out[n] = b64[a >> 2] .. b64[(a & 3) << 4] .. "=="
  elseif rest == 2 then
    local a, b = data:byte(len - 1, len)
    local v = a * 256 + b
    n = n + 1
    out[n] = b64[v >> 10] .. b64[(v >> 4) & 63] .. b64[(v & 15) << 2] .. "="
  end
  return table.concat(out)
end

local function read_file(path)
  local f = io.open(path, "rb")
  if not f then return nil end
  local contents = f:read("*a")
  f:close()
  return contents
end

local function looks_like_tikz(src)
  return src:match("\\begin{tikzpicture}") ~= nil
    or src:match("\\begin{pgfpicture}") ~= nil
end

-- Extract just a `\begin{ENV}...\end{ENV}' environment (tikzpicture or
-- pgfpicture) out of a larger body, e.g. a vscode-tikz fence's
-- `\begin{document}...\end{document}' content -- for the LaTeX/PDF path,
-- where that wrapper can't be spliced in as-is. Returns nil if neither
-- environment is found.
local function extract_tikz_environment(body)
  for _, env in ipairs({ "tikzpicture", "pgfpicture" }) do
    local found = body:match("(\\begin{" .. env .. "}.-\\end{" .. env .. "})")
    if found then return found end
  end
  return nil
end

-- Render DOCUMENT-BODY -- everything from `\begin{document}' through
-- `\end{document}' (optionally with extra `\usepackage' lines before
-- `\begin{document}') -- to an SVG, returning its path, or nil on
-- failure. Cached by content hash so unchanged diagrams aren't
-- recompiled.
local function render_svg(document_body)
  pandoc.system.make_directory(cache_dir, true)
  local hash = pandoc.utils.sha1(document_body)
  local svg_path = cache_dir .. "/" .. hash .. ".svg"

  local existing = io.open(svg_path, "r")
  if existing then
    existing:close()
    return svg_path
  end

  local rendered = pandoc.system.with_temporary_directory("tikz2svg", function(tmpdir)
    local tex_path = tmpdir .. "/diagram.tex"
    local f = io.open(tex_path, "w")
    f:write("\\documentclass{standalone}\n\\usepackage{tikz}\n")
    f:write(document_body)
    f:write("\n")
    f:close()

    local latex_ok = os.execute(string.format(
      "cd %s && pdflatex -interaction=nonstopmode -halt-on-error diagram.tex >pdflatex.log 2>&1",
      pandoc.path.normalize(tmpdir)))
    if not latex_ok then
      io.stderr:write("tikz2svg.lua: pdflatex failed; see " .. tmpdir .. "/pdflatex.log\n")
      return false
    end

    local svg_ok = os.execute(string.format(
      "dvisvgm --pdf -o %s %s/diagram.pdf >/dev/null 2>&1",
      svg_path, pandoc.path.normalize(tmpdir)))
    if not svg_ok then
      io.stderr:write("tikz2svg.lua: dvisvgm failed for " .. tmpdir .. "/diagram.pdf\n")
      return false
    end
    return true
  end)

  if rendered then
    return svg_path
  end
  return nil
end

-- Render DOCUMENT-BODY (see `render_svg') and wrap it as a Para
-- containing an <img> with the SVG embedded as a base64 data: URI.
-- Returns nil (leave the original element untouched) on any failure.
local function embed_as_image(document_body)
  local svg_path = render_svg(document_body)
  if not svg_path then
    return nil -- render failed; fall through to whatever the writer does with the original element
  end
  local svg_data = read_file(svg_path)
  if not svg_data then
    io.stderr:write("tikz2svg.lua: could not read back " .. svg_path .. "\n")
    return nil
  end
  local data_uri = "data:image/svg+xml;base64," .. base64_encode(svg_data)
  return pandoc.Para({ pandoc.Image({ pandoc.Str("TikZ diagram") }, data_uri) })
end

function RawBlock(el)
  if (el.format ~= "latex" and el.format ~= "tex") or not looks_like_tikz(el.text) then
    return nil
  end
  if not FORMAT:match("html") then
    return nil -- LaTeX/PDF output: leave the raw block untouched
  end
  return embed_as_image("\\begin{document}\n" .. el.text .. "\n\\end{document}\n")
end

function CodeBlock(el)
  if not el.classes:includes("tikz") then
    return nil
  end
  if FORMAT:match("html") then
    return embed_as_image(el.text) -- already a full \begin{document}...\end{document} body
  end
  -- LaTeX/PDF output: splice in just the tikzpicture/pgfpicture environment
  -- as raw latex; see this file's Commentary for why the fence's own
  -- \begin{document}...\end{document} wrapper can't be used as-is here.
  local diagram = extract_tikz_environment(el.text)
  if diagram then
    return pandoc.RawBlock("latex", diagram)
  end
  return nil
end

-- Embed plain local images (`![caption](path)') as base64 data: URIs so
-- the HTML stays self-contained wherever it is written, e.g. the temp
-- file `markdown-preview' (C-c C-c p) opens. Relative paths resolve
-- against Pandoc's working directory, i.e. the .md file's directory.
-- Remote URLs, existing data: URIs (including this filter's own TikZ
-- output) and unreadable files are left untouched.
local mime_types = {
  png = "image/png", apng = "image/apng", jpg = "image/jpeg",
  jpeg = "image/jpeg", jpe = "image/jpeg", jfif = "image/jpeg",
  gif = "image/gif", svg = "image/svg+xml", webp = "image/webp",
  avif = "image/avif", bmp = "image/bmp", ico = "image/x-icon",
  tif = "image/tiff", tiff = "image/tiff",
}

function Image(el)
  if not FORMAT:match("html") then
    return nil
  end
  local src = el.src
  if src:match("^%a[%w+.-]*:") then
    return nil -- data:, http(s):, file:, ...
  end
  local path = src:gsub("%%(%x%x)", function(h) return string.char(tonumber(h, 16)) end)
  local mime = mime_types[(path:match("%.(%w+)$") or ""):lower()]
  local data = mime and read_file(path)
  if not data then
    io.stderr:write("tikz2svg.lua: not embedding image " .. src .. "\n")
    return nil
  end
  el.src = "data:" .. mime .. ";base64," .. base64_encode(data)
  return el
end
