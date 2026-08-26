;;; lang-python.el --- Python mode setup -*- lexical-binding: t; -*-

;;; Commentary:
;; Silences a python-shell-completion warning under org babel, enables
;; micropython-mode, and binds "C-c l" in the inferior Python shell to
;; `clear-comint-buffer' (from utility.el).
;;
;; Two optional, independently-toggleable features (both off/Python by
;; default, so default behavior is unchanged from before either was
;; added):
;;
;; - `enable-comint-mime': inline image/rich output in shell and
;;   inferior-python-mode buffers (an IPython-notebook-like
;;   experience). Toggle live any time with `M-x
;;   toggle-comint-mime'; only affects buffers created after the
;;   toggle.
;;
;; - `python-use-ipython': use IPython instead of Python for new
;;   `run-python' shells (falls back to Python if ipython3 isn't
;;   found). Toggle live any time with `M-x
;;   toggle-python-interpreter'; only affects shells started
;;   after the toggle, not ones already running.
;;
;; Both can also be set permanently via `M-x customize-variable' or
;; `setq' in this file, since both are plain `defcustom's under
;; Emacs's standard `local' customize group.

;;; Code:

(require 'use-package)
(require 'utility)

(use-package python
  :defer t
  :init
  ;; Silence warning message in org babel
  (setq python-shell-completion-native-enable nil)
  :hook (inferior-python-mode . (lambda ()
                                   (local-set-key (kbd "C-c l") 'clear-comint-buffer))))

;; Enable micropython mode
(use-package micropython-mode)

;;;; comint-mime (optional, off by default)
(defcustom enable-comint-mime nil
  "Non-nil to enable comint-mime (inline image/rich output, e.g. an
IPython-notebook-like experience) in shell-mode and
inferior-python-mode buffers."
  :type 'boolean
  :group 'local)

(defun load-comint-mime ()
  "Load comint-mime and hook it into shell-mode and inferior-python-mode."
  (interactive)
  (add-to-list 'load-path "~/.elisp/comint-mime/")
  (require 'comint-mime)
  (add-hook 'shell-mode-hook 'comint-mime-setup)
  (add-hook 'inferior-python-mode-hook 'comint-mime-setup))

(defun unload-comint-mime ()
  "Remove comint-mime's hooks from shell-mode and inferior-python-mode.
Only affects buffers created after this call; existing buffers keep
whatever was already set up in them."
  (interactive)
  (remove-hook 'shell-mode-hook 'comint-mime-setup)
  (remove-hook 'inferior-python-mode-hook 'comint-mime-setup))

(defun toggle-comint-mime ()
  "Toggle `enable-comint-mime' and apply the change immediately."
  (interactive)
  (setq enable-comint-mime (not enable-comint-mime))
  (if enable-comint-mime
      (load-comint-mime)
    (unload-comint-mime))
  (message "comint-mime %s" (if enable-comint-mime "enabled" "disabled")))

(when enable-comint-mime
  (load-comint-mime))

;;;; Python vs IPython interpreter (Python is the default)
(defcustom python-use-ipython nil
  "Non-nil to use IPython instead of Python for new `run-python' shells.
Falls back to Python if ipython3 is not found on `exec-path'."
  :type 'boolean
  :group 'local)

(defvar python-default-interpreter python-shell-interpreter
  "`python-shell-interpreter' value before any switching, used to restore Python.")
(defvar python-default-interpreter-args python-shell-interpreter-args
  "`python-shell-interpreter-args' value before any switching.")

(defun apply-python-interpreter ()
  "Set `python-shell-interpreter'/`python-shell-interpreter-args' to
match `python-use-ipython'. Affects new `run-python' shells only."
  (if (and python-use-ipython (executable-find "ipython3"))
      (setq python-shell-interpreter "ipython3"
            python-shell-interpreter-args "--classic")
    (setq python-shell-interpreter python-default-interpreter
          python-shell-interpreter-args python-default-interpreter-args)))

(defun toggle-python-interpreter ()
  "Toggle between Python and IPython for new `run-python' shells."
  (interactive)
  (setq python-use-ipython (not python-use-ipython))
  (apply-python-interpreter)
  (message "Python shell interpreter: %s" (if python-use-ipython "IPython" "Python")))

(apply-python-interpreter) ; apply the default (Python) at load time

(provide 'lang-python)
;;; lang-python.el ends here
