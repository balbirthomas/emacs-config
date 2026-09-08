;;; lang-python.el --- Python mode setup -*- lexical-binding: t; -*-

;;; Commentary:
;; Silences a python-shell-completion warning under org babel, enables
;; micropython-mode, and binds "C-c l" in the inferior Python shell to
;; `clear-comint-buffer' (from utility.el).
;;
;; Two optional, independently-toggleable features (both off by
;; default, so default behavior is unchanged from before either was
;; added):
;;
;; - `enable-comint-mime-python': inline image/rich output in
;;   inferior-python-mode buffers (an IPython-notebook-like
;;   experience). Toggle live any time with `M-x
;;   toggle-comint-mime-python'; applies immediately to an already-
;;   running "*Python*" buffer, not just ones started after the
;;   toggle. (For the analogous shell-mode toggle, see init-shell.el
;;   -- shell-mode isn't Python-specific, so it isn't here; and see
;;   `enable-comint-mime-js' in lang-js.el for the Node REPL.)
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
(defcustom enable-comint-mime-python nil
  "Non-nil to enable comint-mime (inline image/rich output, e.g. an
IPython-notebook-like experience) in inferior-python-mode buffers
(M-x run-python)."
  :type 'boolean
  :group 'local)

(defun load-comint-mime-python ()
  "Load comint-mime and hook it into inferior-python-mode.
Also runs `comint-mime-setup' immediately in the \"*Python*\" buffer if
one is already running, since `inferior-python-mode-hook' (added
here) only fires for buffers started after this call."
  (interactive)
  (add-to-list 'load-path "~/.elisp/comint-mime/")
  (require 'comint-mime)
  (add-hook 'inferior-python-mode-hook 'comint-mime-setup)
  (when-let ((buffer (get-buffer "*Python*")))
    (with-current-buffer buffer
      (when (derived-mode-p 'inferior-python-mode)
        (comint-mime-setup)))))

(defun unload-comint-mime-python ()
  "Remove comint-mime's hook from inferior-python-mode.
Only affects buffers created after this call; existing buffers keep
whatever was already set up in them."
  (interactive)
  (remove-hook 'inferior-python-mode-hook 'comint-mime-setup))

(defun toggle-comint-mime-python ()
  "Toggle `enable-comint-mime-python' and apply the change immediately."
  (interactive)
  (setq enable-comint-mime-python (not enable-comint-mime-python))
  (if enable-comint-mime-python
      (load-comint-mime-python)
    (unload-comint-mime-python))
  (message "comint-mime-python %s" (if enable-comint-mime-python "enabled" "disabled")))

(when enable-comint-mime-python
  (load-comint-mime-python))

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
