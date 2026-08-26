;;; lang-auctex.el --- AucTeX integration with Sweave/R -*- lexical-binding: t; -*-

;;; Commentary:
;; File-extension setup for Sweave/R noweb documents (.Rnw/.Snw) used
;; with AucTeX. AucTeX itself is installed and loaded system-wide
;; (see /etc/emacs/site-start.d/50auctex.el), so there is no package
;; to defer-load here -- just the extra `auto-mode-alist' entries.

;;; Code:

(setq TeX-file-extensions
  '("Snw" "Rnw" "nw" "tex" "sty" "cls" "ltx" "texi" "texinfo"))
(add-to-list 'auto-mode-alist '("\\.Rnw\\'" . Rnw-mode))
(add-to-list 'auto-mode-alist '("\\.Snw\\'" . Snw-mode))

(provide 'lang-auctex)
;;; lang-auctex.el ends here
