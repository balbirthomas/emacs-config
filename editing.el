;;; editing.el --- Core editor UI and behavior settings -*- lexical-binding: t; -*-

;;; Commentary:
;; General editor behavior: global key bindings, mode line (clock,
;; line/column numbers), abbrev file location, bell settings, startup
;; warning level, default indentation, paren highlighting, backup
;; file policy, preferred window-splitting direction, font-lock,
;; dired, ansi-color support in shell-mode buffers, and Ediff's
;; window layout.
;;
;; Also appends ~/.elisp and its subdirectories to `load-path'. Load
;; this module before any module that requires packages living under
;; ~/.elisp (e.g. init-erc.el).

;;; Code:

;;;; Global definitions and key bindings
;; Whitespace mode global key binding
(global-set-key (kbd "M-n C-c C-w") 'whitespace-mode) ;
;; Disable global automatic help
(global-eldoc-mode -1)

;;;; Display clock
(display-time)

;;;; Abbreviations
;; tell emacs where to read abbrev
(setq abbrev-file-name  "~/.emacs.d/abbrev_defs")

;;;; Turn off noisy Bell
(setq visible-bell 1)

;;;; Disable warnings on startup
(setq warning-minimum-level :emergency)

;;;; Line and Column number mode on
(line-number-mode 1)
(column-number-mode 1)

;;;; Expand all tabs as spaces (Bad idea globally for Makefiles)
(setq-default indent-tabs-mode nil)
;; Set default tab width to 4
(setq-default tab-width 4)

;;;; Highlight Parenthesis
(setq show-paren-delay 0
  show-paren-style 'parenthesis)
(show-paren-mode 1)

;;;; Append local Emacs Lisp directory to search path
(setq load-path (append load-path (list "~/.elisp")))
;; Prepend local Emacs Lisp directory to search path
;; (setq load-path (append (list "~/.elisp") load-path))
;; Add local elisp directory and sub-directories to load-path
(let ((default-directory  "~/.elisp/"))
    (normal-top-level-add-subdirs-to-load-path))

;;;; Don't make backup files (i.e filename~)
(setq backup-inhibited t)

;;;; Default window splitting behaviour
(defun split-window-sensibly-prefer-horizontal (&optional window)
  (let ((window (or window (selected-window))))
    (or (and (window-splittable-p window t)
             ;; Split window horizontally.
             (with-selected-window window
               (split-window-right)))
        (and (window-splittable-p window)
             ;; Split window vertically.
             (with-selected-window window
               (split-window-below)))
        (and (eq window (frame-root-window (window-frame window)))
             (not (window-minibuffer-p window))
             ;; If WINDOW is the only window on its frame and is not the
             ;; minibuffer window, try to split it horizontally disregarding
             ;; the value of `split-width-threshold'.
             (let ((split-width-threshold 0))
               (when (window-splittable-p window t)
                 (with-selected-window window
                   (split-window-right))))))))

(setq split-window-preferred-function 'split-window-sensibly-prefer-horizontal)

;;;; Turn on syntax highlighting where ever possible
(global-font-lock-mode 1)

;;;; Dired mode config
(put 'dired-find-alternate-file 'disabled nil)

;;;; Allow directory colors listing in shell mode (M-x shell)
;; For a full fleged terminal that allows execution of
;; ncurses based applications use "M-x term" not "M-x shell"
(autoload 'ansi-color-for-comint-mode-on "ansi-color" nil t)
(add-hook 'shell-mode-hook 'ansi-color-for-comint-mode-on)

;;;; Enabled commands (disabled by default)
(put 'downcase-region 'disabled nil)
(put 'upcase-region 'disabled nil)

;;;; Setup info path
(require 'info)
(setq Info-directory-list
  (cons (expand-file-name "/usr/share/info")
        (cons (expand-file-name "~/info")
             Info-directory-list)))

;;;; specify additional fonts to use for unicode characters
(set-fontset-font t 'symbol "Noto Color Emoji" nil 'append)
(set-fontset-font t 'symbol "Symbola" nil 'append)

;;;; Ediff setup
(setq ediff-split-window-function 'split-window-horizontally)
(setq ediff-window-setup-function 'ediff-setup-windows-plain)

(provide 'editing)
;;; editing.el ends here
