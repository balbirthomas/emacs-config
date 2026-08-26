;;; mail.el --- Mail: identity, SMTP, and Gnus configuration -*- lexical-binding: t; -*-

;;; Commentary:
;; Sets the user's name and email address from the EMAIL_NAME and
;; EMAIL_ADDRESS environment variables (see README.md), configures
;; `smtpmail' to send mail via Gmail's SMTP server (credentials read
;; from ~/.authinfo), and configures Gnus to read Usenet (server from
;; GNUS_NNTP_SERVER, default news.eternal-september.org) and Gmail via
;; IMAP (also authenticated from ~/.authinfo).
;;
;; The SMTP/IMAP hosts are Gmail-specific; edit them directly below if
;; you use a different provider.

;;; Code:

(require 'utility)

;;;; User name
(setq user-full-name (getenv-or-warn "EMAIL_NAME"))

;;;; User Email Address
(setq user-mail-address (getenv-or-warn "EMAIL_ADDRESS"))
;; This requires starttls provided by gnutls-bin package
(setq send-mail-function 'smtpmail-send-it
  message-send-mail-function 'smtpmail-send-it
  smtpmail-starttls-credentials
  '(("smtp.gmail.com" 587 nil nil))
  smtpmail-auth-credentials
  (expand-file-name "~/.authinfo")
  smtpmail-default-smtp-server "smtp.gmail.com"
  smtpmail-smtp-server "smtp.gmail.com"
  smtpmail-smtp-service 587
  smtpmail-debug-info t)
(require 'smtpmail)
;; GNUS Configuration
(setq
 gnus-select-method (list 'nntp (getenv-or-warn "GNUS_NNTP_SERVER" "news.eternal-september.org"))
 gnus-directory "~/.gnus"
 gnus-startup-file "~/.gnus/newsrc"
 gnus-thread-hide-subtree t
 message-directory gnus-directory
 message-auto-save-directory message-directory
 nndraft-directory message-directory
 )
(setq gnus-secondary-select-methods
  '((nnimap "gmail"
    (nnimap-address "imap.gmail.com")
    (nnimap-server-port "imaps")
    (nnimap-stream ssl)
    (nnimap-authinfo-file "~/.authinfo")
    (nnmail-expiry-target "nnimap+gmail:[Gmail]/Trash")  ; Move expired messages to Gmail's trash.
    (nnmail-expiry-wait immediate)))) ; Mails marked as expired can be processed immediately.

(provide 'mail)
;;; mail.el ends here
