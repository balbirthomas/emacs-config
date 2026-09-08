;;; init-shell.el --- shell-mode (M-x shell) configuration -*- lexical-binding: t; -*-

;;; Commentary:
;; One optional feature, off by default so default behavior is
;; unchanged unless enabled:
;;
;; - `enable-comint-mime-shell': inline image/rich output (e.g. from
;;   comint-mime's `mimecat' shell function) in shell-mode buffers
;;   (M-x shell). Toggle live any time with `M-x
;;   toggle-comint-mime-shell'; applies immediately to an already-
;;   running "*shell*" buffer, not just ones started after the
;;   toggle.
;;
;; Not in lang-python.el: shell-mode isn't Python-specific, it's a
;; plain built-in Emacs feature (like ERC or Org, configured in
;; init-erc.el/init-org.el) -- comint-mime just happens to also cover
;; it, independently of `enable-comint-mime-python' there. See
;; `enable-comint-mime-js' in lang-js.el for the Node REPL's own,
;; separate toggle.
;;
;; Can also be set permanently via `M-x customize-variable' or `setq'
;; in this file, since it's a plain `defcustom' under Emacs's standard
;; `local' customize group.

;;; Code:

;;;; comint-mime (optional, off by default)
(defcustom enable-comint-mime-shell nil
  "Non-nil to enable comint-mime (inline image/rich output) in
shell-mode buffers (M-x shell)."
  :type 'boolean
  :group 'local)

(defun load-comint-mime-shell ()
  "Load comint-mime and hook it into shell-mode.
Also runs `comint-mime-setup' immediately in the \"*shell*\" buffer if
one is already running, since `shell-mode-hook' (added here) only
fires for buffers started after this call."
  (interactive)
  (add-to-list 'load-path "~/.elisp/comint-mime/")
  (require 'comint-mime)
  (add-hook 'shell-mode-hook 'comint-mime-setup)
  (when-let ((buffer (get-buffer "*shell*")))
    (with-current-buffer buffer
      (when (derived-mode-p 'shell-mode)
        (comint-mime-setup)))))

(defun unload-comint-mime-shell ()
  "Remove comint-mime's hook from shell-mode.
Only affects buffers created after this call; existing buffers keep
whatever was already set up in them."
  (interactive)
  (remove-hook 'shell-mode-hook 'comint-mime-setup))

(defun toggle-comint-mime-shell ()
  "Toggle `enable-comint-mime-shell' and apply the change immediately."
  (interactive)
  (setq enable-comint-mime-shell (not enable-comint-mime-shell))
  (if enable-comint-mime-shell
      (load-comint-mime-shell)
    (unload-comint-mime-shell))
  (message "comint-mime-shell %s" (if enable-comint-mime-shell "enabled" "disabled")))

(when enable-comint-mime-shell
  (load-comint-mime-shell))

(provide 'init-shell)
;;; init-shell.el ends here
