;;; lang-xppaut.el --- XPP-AUT mode setup -*- lexical-binding: t; -*-

;;; Commentary:
;; XPP-AUT mode for .ode files. "C-c C-r" in an xpp-mode buffer saves
;; the file and runs it via `xppaut'.

;;; Code:

(require 'use-package)

(use-package xpp
  :mode ("\\.ode\\'" . xpp-mode)
  :config
  (defun xpp-mode-save-and-run ()
    (interactive "")
    (save-buffer 0)
    (compile (concat "xppaut " (buffer-name)) t))
  (define-key xpp-mode-map (kbd "C-c C-r") 'xpp-mode-save-and-run))

(provide 'lang-xppaut)
;;; lang-xppaut.el ends here
