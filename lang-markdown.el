;;; lang-markdown.el --- Markdown mode: LaTeX/TikZ-aware HTML and PDF export -*- lexical-binding: t; -*-

;;; Commentary:
;; `markdown-mode' itself comes from the system (Debian's
;; elpa-markdown-mode), not MELPA, so this module only configures it --
;; there is nothing to install here.
;;
;; Write LaTeX math and TikZ diagrams directly in the Markdown text,
;; the same way you already would in an .org file: bare `$...$'/
;; `$$...$$' math and a bare `\begin{tikzpicture}...\end{tikzpicture}'
;; environment, no code fences needed. Pandoc's default Markdown
;; dialect recognizes both (the `tex_math_dollars' and `raw_tex'
;; extensions are on by default).
;;
;; TikZ diagrams written in the vscode-tikz extension's style
;; (https://github.com/kevinyuan/vscode-tikz) are also supported: a
;; ```tikz-fenced code block whose content is a full
;; `\begin{document}...\end{document}' body (optionally with
;; `\usepackage{...}' lines before `\begin{document}'). Both styles are
;; handled by the same pandoc-filters/tikz2svg.lua, which also extracts
;; just the tikzpicture/pgfpicture environment out of a vscode-tikz
;; fence for the PDF/LaTeX path (see that file's Commentary) -- any
;; extra `\usepackage' lines in such a fence are honored for HTML
;; preview but NOT carried over to PDF export; add them to
;; tikz-preamble.tex as well if you need them there too.
;;
;; There is no in-buffer preview (no analogue of org's "C-c C-x C-l");
;; preview means compiling and looking at the result, via
;; `markdown-mode's existing commands:
;;   C-c C-c p   `markdown-preview'            -- compile, open in browser
;;   C-c C-c v   `markdown-export-and-preview'  -- also saves <basename>.html
;;   C-c C-c e   `markdown-export'              -- just saves <basename>.html
;; These already exist in markdown-mode; the only change here is
;; `markdown-command', set to `my/markdown-pandoc-command' (a function,
;; not the usual string -- markdown-mode supports this: it funcalls it
;; with (BEGIN END OUTPUT-BUFFER) and treats anything that doesn't
;; signal an error as success). That function runs Pandoc with:
;;   - `--mathjax=URL' for math, using `my/markdown-buffer-mathjax-url'
;;     (a document can override the CDN URL via a `mathjax-url:' key in
;;     its own YAML front matter; otherwise `markdown-default-mathjax-url'
;;     is used -- deliberately v2, not v3, per request)
;;   - `--lua-filter=pandoc-filters/tikz2svg.lua', which MathJax alone
;;     cannot render TikZ diagrams: rasterizes them to cached SVGs and
;;     embeds each one directly as a base64 data: URI (the filter does
;;     this itself; see its own Commentary for why -- in short, Pandoc's
;;     `--embed-resources' flag would also try to fetch and embed the
;;     external MathJax <script src> below, which is fragile and not
;;     actually useful, so it is deliberately not passed here). This
;;     keeps the image working even when the resulting HTML is moved
;;     somewhere else, which `markdown-preview' (C-c C-c p) always does
;;     (it writes to a temp file elsewhere before browsing it).
;;
;; PDF export is new: `my/markdown-export-pdf', bound to "C-c C-c d",
;; runs Pandoc with XeLaTeX as the PDF engine and
;; pandoc-filters/tikz-preamble.tex (`\usepackage{tikz}') as an
;; included header. No MathJax URL is needed on this path -- PDF output
;; is compiled through LaTeX anyway, so bare tikzpicture and math render
;; natively, the same way they do in `init-org.el's TikZ preview (also
;; dvisvgm-based) and PDF export. The Lua filter IS still needed here,
;; though, and is passed just like on the HTML path: a bare tikzpicture
;; needs no help (it's already raw LaTeX, passed through natively), but a
;; vscode-tikz-style ```tikz fence is a genuine CodeBlock, which the
;; LaTeX writer would otherwise typeset as a preformatted code listing --
;; the filter's CodeBlock handler is what extracts the tikzpicture out of
;; it for this path (see tikz2svg.lua's Commentary).
;;
;; Both export functions write next to the visited file, same
;; basename, and export the buffer's current content (including
;; unsaved edits), not the last-saved file on disk.
;;
;; Requires `pandoc', `xelatex', and `dvisvgm' on `exec-path' (all
;; three are already required by, and present for, init-org.el's own
;; LaTeX/TikZ preview setup).
;;
;; "M-n C-c C-c" and "M-n C-c C-d" run a directory makefile's `clean'
;; and `distclean' targets, via `clean-current-program'/
;; `distclean-current-program' from utility.el -- the same mechanism
;; lang-c.el/lang-fortran.el/etc. use (see `compiled-program-bind-keys'
;; there), just without `build'/`run' (M-n C-c C-b/C-r), which don't
;; apply to a Markdown document. As with those languages, this expects
;; a makefile in the same directory as the .md file, with `clean' and
;; `distclean' targets driven by PROGRAM=<basename>/EXT=md (see
;; work/src/fortran/makefile for the model); no such makefile is
;; created by this module.
;;
;; Getting "M-n" to work as a prefix here took one more step:
;; markdown-mode-map already binds plain "M-n"/"M-p" to
;; `markdown-next-link'/`markdown-previous-link', and a key can't be
;; both a command and a prefix in the same keymap. Those two are
;; relocated to "M-N"/"M-P" (shifted) below to make room, rather than
;; dropped or given a different, inconsistent-with-other-languages
;; prefix.

;;; Code:

(require 'use-package)
(require 'utility)

(defconst markdown-pandoc-filters-directory
  (expand-file-name "lisp/pandoc-filters/" user-emacs-directory)
  "Directory holding the Pandoc filter and header files this module uses.")

(defconst markdown-default-mathjax-url
  "http://localhost/javascript/mathjax/MathJax.js?config=TeX-MML-AM_CHTML"
  "Default MathJax v2 URL used for HTML preview/export.
Points at the local Apache-served copy of Debian's libjs-mathjax
package (confirmed to also serve MathJax's own dynamically-loaded
sub-resources, e.g. jax/output/CommonHTML/, not just the top-level
file, so this is genuinely usable offline, not just a same-machine
convenience) -- so exported HTML only renders correctly on a machine
running that Apache setup. For a document meant to be viewed
elsewhere, override with a CDN URL, e.g.
\"https://cdnjs.cloudflare.com/ajax/libs/mathjax/2.7.9/MathJax.js?config=TeX-MML-AM_CHTML\"
via `mathjax-url:' in that document's own front matter; see
`my/markdown-buffer-mathjax-url'.")

(defun my/markdown-buffer-mathjax-url ()
  "Return the MathJax URL to use for the current buffer.
Reads a `mathjax-url:' key from a `---'-delimited YAML front-matter
block at the top of the buffer, if present and the buffer has one;
otherwise returns `markdown-default-mathjax-url'."
  (save-excursion
    (goto-char (point-min))
    (let ((front-matter-end
           (and (looking-at-p "^---[ \t]*$")
                (save-excursion
                  (forward-line 1)
                  (and (re-search-forward "^---[ \t]*$\\|^\\.\\.\\.[ \t]*$" nil t)
                       (point))))))
      (if (and front-matter-end
               (re-search-forward
                "^mathjax-url:[ \t]*[\"']?\\([^\"'\n]+?\\)[\"']?[ \t]*$"
                front-matter-end t))
          (match-string 1)
        markdown-default-mathjax-url))))

(defun my/markdown-pandoc-command (begin end output-buffer)
  "`markdown-command' function: run Pandoc with MathJax and the TikZ filter.
See this file's Commentary for the full rationale. Signals an error if
Pandoc exits non-zero, which is how `markdown-command' functions report
failure back to markdown-mode (see `markdown', the function that calls
this one).

Pandoc's stderr (e.g. its \"document format requires a nonempty
<title>\" warning when a file has no title metadata -- harmless, it
still defaults the <title> tag to the filename) is captured into
*markdown-pandoc-errors*, never left mixed into OUTPUT-BUFFER:
`call-process-region' mixes stderr into the same buffer as stdout
unless told otherwise, and OUTPUT-BUFFER here is the HTML
markdown-mode is about to display or save, so any stderr text would
otherwise show up as literal text at the top of the rendered page.
`call-process-region' can only redirect stderr to nil, t (mix, the
default we're avoiding), or a file name -- not directly to a buffer --
hence the temp file below, whose contents are copied into
*markdown-pandoc-errors* afterward and then deleted."
  (let ((err-file (make-temp-file "markdown-pandoc-errors-")))
    (unwind-protect
        (let ((exit-code
               (call-process-region
                begin end "pandoc" nil (list output-buffer err-file) nil
                "--from=markdown" "--to=html5" "--standalone"
                (concat "--mathjax=" (my/markdown-buffer-mathjax-url))
                (concat "--lua-filter="
                        (expand-file-name "tikz2svg.lua" markdown-pandoc-filters-directory)))))
          (with-current-buffer (get-buffer-create "*markdown-pandoc-errors*")
            (erase-buffer)
            (insert-file-contents err-file))
          (unless (eq exit-code 0)
            (display-buffer "*markdown-pandoc-errors*")
            (error "pandoc failed with exit code %s; see *markdown-pandoc-errors*" exit-code)))
      (ignore-errors (delete-file err-file)))))

(use-package markdown-mode
  :defer t
  :init
  (setq markdown-command #'my/markdown-pandoc-command))

(defun my/markdown-export-pdf ()
  "Export the current Markdown buffer to a same-named PDF via Pandoc/XeLaTeX.
Uses `markdown-export-file-name' for the output filename, exactly as
`markdown-export' does for HTML, and exports the buffer's current
content (including unsaved edits), not the last-saved file on disk."
  (interactive)
  (let ((output-file (markdown-export-file-name ".pdf")))
    (unless output-file
      (user-error "Buffer is not visiting a file"))
    (let ((err-buf (get-buffer-create "*markdown-pdf-export*"))
          (preamble (expand-file-name "tikz-preamble.tex" markdown-pandoc-filters-directory)))
      (with-current-buffer err-buf
        (erase-buffer))
      (message "Exporting %s..." output-file)
      (if (zerop (call-process-region
                  (point-min) (point-max) "pandoc" nil err-buf nil
                  "--pdf-engine=xelatex"
                  (concat "--include-in-header=" preamble)
                  (concat "--lua-filter="
                          (expand-file-name "tikz2svg.lua" markdown-pandoc-filters-directory))
                  "-o" output-file))
          (message "Exported to %s" output-file)
        (display-buffer err-buf)
        (user-error "pandoc failed exporting %s; see %s"
                    output-file (buffer-name err-buf))))))

(with-eval-after-load 'markdown-mode
  (define-key markdown-mode-command-map (kbd "d") 'my/markdown-export-pdf)
  ;; Relocate link navigation off of plain M-n/M-p so M-n is free to be a
  ;; prefix (see this file's Commentary).
  (define-key markdown-mode-map (kbd "M-N") 'markdown-next-link)
  (define-key markdown-mode-map (kbd "M-P") 'markdown-previous-link)
  (define-key markdown-mode-map (kbd "M-n") nil)
  (define-key markdown-mode-map (kbd "M-p") nil)
  (define-key markdown-mode-map (kbd "M-n C-c C-c") 'clean-current-program)
  (define-key markdown-mode-map (kbd "M-n C-c C-d") 'distclean-current-program))

(provide 'lang-markdown)
;;; lang-markdown.el ends here
