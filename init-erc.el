;;; init-erc.el --- ERC (IRC) configuration -*- lexical-binding: t; -*-

;;; Commentary:
;; Loads and configures ERC (built into Emacs) plus the third-party
;; erc-tex, erc-image, and erc-notify extensions from ~/.elisp: enables
;; the tex, image, and notifications ERC modules, sets up activity
;; tracking (`erc-track-mode') with excluded/hidden message types,
;; binds "C-c C-l" and "C-c C-v" in ERC buffers to toggle ERC-TeX and
;; enable ERC-Image, and binds "C-c e f" globally to connect.
;;
;; Reads IRCSERVER (default "irc.libera.chat") and IRCNICK (falling
;; back to `user-login-name' if unset, so connecting never fails
;; outright) from the environment -- see README.md. The realname sent
;; to the server comes from `user-full-name' (set in mail.el from
;; EMAIL_NAME).
;;
;; erc-tex and erc-image are loaded from ~/.elisp; load editing.el
;; first so that directory is on `load-path'.
;;
;; The NickServ password is read from ~/.authinfo (machine matching
;; IRCSERVER, login matching IRCNICK) via `auth-source', not stored in
;; this file.

;;; Code:

(require 'use-package)
(require 'auth-source)
(require 'utility)

(use-package erc
  :demand t
  :bind ("C-c e f" . erc-connect)
  :hook (erc-mode . erc-local-mode-hook)
  :config
  ;; TODO Switch to TLS as described at
  ;; https://www.oftc.net/NickServ/CertFP/
  ;; and https://www.emacswiki.org/emacs/ErcSSL
  (require 'erc-dcc)
  (require 'erc-tex)
  (require 'erc-image)
  (require 'erc-notify)
  (add-to-list 'erc-modules 'tex)
  (add-to-list 'erc-modules 'image)
  (add-to-list 'erc-modules 'notifications)
  (erc-update-modules)
  ;; check channels
  (erc-track-mode t)
  (setq erc-track-exclude-types '("JOIN" "NICK" "PART" "QUIT" "MODE"
                               "324" "329" "332" "333" "353" "477"))
  ;; don't show any of this
  (setq erc-hide-list '("JOIN" "PART" "QUIT" "NICK"))

  (defun erc-connect ()
    "Connect to IRCSERVER (default irc.libera.chat) as IRCNICK,
reading the NickServ password from auth-source."
    (interactive)
    (let ((server (getenv-or-warn "IRCSERVER" "irc.libera.chat"))
          (nick (getenv-or-warn "IRCNICK" (user-login-name))))
      (erc :server server :port 6667 :nick nick
           :password (auth-source-pick-first-password :host server :user nick)
           :full-name user-full-name)))

  (defun erc-local-mode-hook ()
    (local-set-key (kbd "C-c C-l") 'erc-tex-mode)     ; Toggle ERC-TeX
    (local-set-key (kbd "C-c C-v") 'erc-image-enable) ; Enable ERC-Image
    ))

(provide 'init-erc)
;;; init-erc.el ends here
