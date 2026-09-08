;;; packages.el --- package.el / MELPA setup -*- lexical-binding: t; -*-

;;; Commentary:
;; Adds the MELPA Stable package archive and initializes package.el.
;;
;; Also defines `enable-eaf', an optional-feature toggle following the
;; same pattern as `enable-comint-mime-shell' (init-shell.el)/
;; `python-use-ipython' (lang-python.el).
;;
;; EAF/eaf-jupyter is off by default (`comint-mime' -- see
;; init-shell.el -- covers the same "inline rich output in a
;; shell buffer" need more lightly). To turn it on:
;;   - permanently: `M-x customize-variable RET enable-eaf RET',
;;     or (setq enable-eaf t) before this file loads; takes
;;     effect on the next Emacs startup; or
;;   - for the running session only: `M-x toggle-eaf'.
;; EAF starts a Python subprocess and cannot be cleanly unloaded once
;; started, so disabling it (either way) only prevents loading it on
;; the *next* startup -- it does not stop an already-running session.

;;; Code:

;;;; Melpa Stable Repository
(require 'package)
(add-to-list 'package-archives '("melpa-stable" . "https://stable.melpa.org/packages/") t)
(package-initialize)

;;;; EAF / eaf-jupyter (optional, off by default)
(defcustom enable-eaf nil
  "Non-nil to load EAF (Emacs Application Framework) and eaf-jupyter at startup.
See this file's Commentary for how EAF differs from `enable-comint-mime-shell'
(init-shell.el) and why disabling it does not stop an already-running session."
  :type 'boolean
  :group 'local)

(defun load-eaf ()
  "Load EAF and eaf-jupyter now, regardless of `enable-eaf'."
  (interactive)
  (add-to-list 'load-path "~/.elisp/eaf/")
  (require 'eaf)
  (require 'eaf-jupyter))

(defun toggle-eaf ()
  "Toggle `enable-eaf'; loads EAF immediately if turning it on."
  (interactive)
  (setq enable-eaf (not enable-eaf))
  (if enable-eaf
      (load-eaf)
    (message "enable-eaf is now nil; restart Emacs to fully unload EAF")))

(when enable-eaf
  (load-eaf))

(provide 'packages)
;;; packages.el ends here
