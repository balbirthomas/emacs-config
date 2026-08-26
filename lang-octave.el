;;; lang-octave.el --- Octave mode setup -*- lexical-binding: t; -*-

;;; Commentary:
;; Octave mode for .m files.

;;; Code:

(require 'use-package)

(use-package octave
  :mode ("\\.m\\'" . octave-mode))

(provide 'lang-octave)
;;; lang-octave.el ends here
