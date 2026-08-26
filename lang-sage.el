;;; lang-sage.el --- SageMath mode setup -*- lexical-binding: t; -*-

;;; Commentary:
;; Configures sage-shell-mode (adds `run-sage' as an alias for
;; `sage-shell:run-sage', eldoc in the Sage shell and source files,
;; "C-c l" to clear the shell buffer via `clear-comint-buffer' from
;; utility.el) and sage-shell-view (inline plots and LaTeX
;; preview).
;;
;; Reads the Sage install root from SAGE_ROOT (see README.md); the
;; executable is derived as $SAGE_ROOT/bin/sage. If SAGE_ROOT is
;; unset, sage-shell-mode's own defaults are left in place.

;;; Code:

(require 'use-package)
(require 'utility)

(use-package sage-shell-mode
  :demand t
  :init
  (setq sage-shell:use-simple-prompt t)
  (let ((sage-root (getenv-or-warn "SAGE_ROOT")))
    (when sage-root
      (setq sage-shell:sage-root sage-root)
      (setq sage-shell:sage-executable (expand-file-name "bin/sage" sage-root))))
  :hook ((sage-shell-mode . eldoc-mode)
         (sage-shell:sage-mode . eldoc-mode)
         (sage-shell-mode . (lambda ()
                               (local-set-key (kbd "C-c l") 'clear-comint-buffer))))
  :config
  ;; Run SageMath by M-x run-sage instead of M-x sage-shell:run-sage
  (sage-shell:define-alias))

(use-package sage-shell-view
  :demand t
  :after sage-shell-mode
  :hook (sage-shell-after-prompt . sage-shell-view-mode))

(provide 'lang-sage)
;;; lang-sage.el ends here
