;;; init-custom.el --- Custom-generated settings (custom-set-variables / custom-set-faces) -*- lexical-binding: t; -*-

;;; Commentary:
;; Holds the `custom-set-variables' and `custom-set-faces' forms:
;; inline image display in EIN, the list of packages installed via
;; package.el, and the default spice-mode simulator.
;;
;; Also points `custom-file' at this file, so that `M-x customize'
;; saves land here instead of being appended to whatever file was
;; loaded as the init file (~/.emacs).

;;; Code:

(setq custom-file (expand-file-name "init-custom.el"
                                     (file-name-directory (or load-file-name buffer-file-name))))

(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 )

;;;; Setup Local Variables
(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(ein:output-area-inlined-images t)
 '(package-selected-packages
   '(poly-R poly-rst pygn-mode))
 '(spice-simulator "Ngspice"))

(provide 'init-custom)
;;; init-custom.el ends here
