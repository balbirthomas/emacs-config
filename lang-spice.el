;;; lang-spice.el --- Spice mode setup -*- lexical-binding: t; -*-

;;; Commentary:
;; Spice mode for circuit netlist files (.sp/.cir/.ckt/.mod/.spc/
;; .spice/.cdl/.chi/.inp). The default simulator (`spice-simulator')
;; is set in init-custom.el via `custom-set-variables'.

;;; Code:

(require 'use-package)

(use-package spice-mode
  :mode ("\\.sp$" "\\.cir$" "\\.ckt$" "\\.mod$"
         "\\.spc$"   ; xcircuit output
         "\\.spice$" ; magic output
         "\\.cdl$"
         "\\.chi$"   ; eldo output
         "\\.inp$")
  :init
  (eval-after-load 'spice-mode
    '(fset 'yes-or-no-p 'y-or-n-p)))
;; Use custom-set-variables as follows to set the default simulator/viewer
;; for spice-mode. Note that there should only be a single custom-set-variables
;; block in an emacs config file (so search this file)
;;(custom-set-variables
;;  '(spice-simulator "Gnucap")                        ;; default simulator
;;  '(spice-waveform-viewer "Gwave")                   ;; default waveform
;;  '(spice-output-local "Gnucap")
;;)

(provide 'lang-spice)
;;; lang-spice.el ends here
