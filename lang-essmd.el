;;; lang-essmd.el --- ESS Markdown mode for R Markdown (.Rmd) files -*- lexical-binding: t; -*-

;;; Commentary:
;; Defines `rmd-mode', a thin wrapper that loads poly-R/poly-markdown
;; and switches to `poly-markdown+r-mode', and registers it for .Rmd
;; files. Not wrapped in `use-package' since `rmd-mode' is a local
;; function, not a package entry point to autoload against.

;;; Code:

(defun rmd-mode ()
  "ESS Markdown mode for rmd files"
  (interactive)
  (require 'poly-R)
  (require 'poly-markdown)
  (poly-markdown+r-mode))
(setq auto-mode-alist
(cons '("\\.Rmd$" . rmd-mode) auto-mode-alist))

(provide 'lang-essmd)
;;; lang-essmd.el ends here
