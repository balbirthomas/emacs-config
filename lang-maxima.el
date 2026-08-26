;;; lang-maxima.el --- Maxima, imaxima, and imath setup -*- lexical-binding: t; -*-

;;; Commentary:
;; Maxima major mode (.mac/.max), imath minor mode (.mth), and
;; imaxima's inline image support for Maxima (invoked interactively
;; via `imaxima', configured to use maxima-mode and Large fonts).

;;; Code:

(require 'use-package)

(use-package maxima
  :mode ("\\.ma[cx]" . maxima-mode)
  :commands maxima)

(use-package imaxima
  :commands imaxima
  :init
  (setq imaxima-use-maxima-mode-flag t)
  (setq imaxima-fnt-size "Large"))

(use-package imath
  :mode ("\\.mth" . imath-mode))

(provide 'lang-maxima)
;;; lang-maxima.el ends here
