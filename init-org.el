;;; init-org.el --- org-mode configuration -*- lexical-binding: t; -*-

;;; Commentary:
;; Configures Babel: enabled source-code languages, source-block
;; fontification/indentation, evaluation without confirmation, and
;; inline image display after evaluation. Also defines a hook to
;; remove export byproducts via a Makefile "distclean" target (bound
;; to "M-n C-c C-c"), a key binding for asynchronous SageMath Babel
;; evaluation ("C-c c"), the default PDF viewer, an advice on
;; `org-open-at-point' to choose which browser opens a link, and TikZ
;; preview support.
;;
;; Requires browser.el (`choose-browser', `w3m-browse-url').

;;; Code:

(require 'browser)

;;;; Setup org-mode
;; Use python 3
(setq org-babel-python-command "python3")
;; Set default Julia command (resolved via PATH; no absolute path needed)
(setq inferior-julia-program-name "julia")
;; Support syntax colouring
(setq org-src-fontify-natively t)
;; Preserve indentation (eg. in makefiles)
(setq org-src-preserve-indentation t)
;; Tabs appropriately in each code block (eg. in makefiles)
(setq org-src-tab-acts-natively t)
;; Enable selected org babel language support
(org-babel-do-load-languages
'org-babel-load-languages
'((R . t)
(shell . t)
(dot . t)
(julia . t)
(spice . t)
(ditaa . t)
(latex . t)
(octave . t)
(python . t)
(maxima . t)
(fortran . t)
(gnuplot . t)
(sagemath . t)
(emacs-lisp . t)
))
;; Exporting org files creates lots of temporary junk files
;; If a makefile is present in the same directory as the org file
;; and this make file has a "distclean" target, it can be
;; invoked using the "M-n C-c C-c" key binding
(defun org-mode-clean-dir ()
(interactive "")
(save-buffer 0)
(compile (concat "make distclean FILENAME='" (car (split-string (buffer-name) "\\.")) "'")))
(defun org-mode-local-clean-hook ()
(define-key org-mode-map (kbd "M-n C-c C-c") 'org-mode-clean-dir))
(add-hook 'org-mode-hook 'org-mode-local-clean-hook)

;; C-c c for asynchronous evaluating (only for SageMath code blocks).
(with-eval-after-load "org"
  (define-key org-mode-map (kbd "C-c c") 'ob-sagemath-execute-async))
;; Do not confirm before evaluation
(setq org-confirm-babel-evaluate nil)
;; Show images after evaluating code blocks.
(add-hook 'org-babel-after-execute-hook 'org-display-inline-images)
;; Set default pdf reader in org mode
(add-to-list 'org-file-apps '("pdf" . "xpdf %s"))
;; Use choose-browser
;; Use external browser with C-u C-c C-o or use default browser
(define-advice org-open-at-point (:around (orig-fn &optional arg reference-link) choose-browser)
  (let ((browse-url-browser-function
		 (cond ((equal arg '(4))
				'browse-url-generic)
			   ((equal arg '(16))
				'choose-browser)
			   (t
				(lambda (url &optional new)
				  (w3m-browse-url url t)))
			   )))
	    (funcall orig-fn arg reference-link)))
;; support Tikz preview
(add-to-list 'org-latex-packages-alist
  '("" "tikz" t))
(eval-after-load "preview"
  '(add-to-list 'preview-default-preamble "\\PreviewEnvironment{tikzpicture}" t))
(setq org-preview-latex-default-process 'dvisvgm)

(provide 'init-org)
;;; init-org.el ends here
