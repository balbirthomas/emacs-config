;;; languages.el --- Per-language mode setup (loader) -*- lexical-binding: t; -*-

;;; Commentary:
;; Loads the per-language configuration modules: Spice, Octave, GNU
;; bc, Python, JavaScript, XPP-AUT, SageMath, AucTeX/Sweave, ESS R
;; Markdown, Markdown (LaTeX/TikZ-aware HTML and PDF export),
;; Maxima/imaxima/imath, Fortran, C, C++, and PGN chess (pygn-mode).
;; Each module is a self-contained `provide'/`require' unit built on
;; `use-package'; see its own Commentary for what it configures.
;;
;; Requires utility.el (`clear-comint-buffer', used by the
;; Python and SageMath modules; `compiled-program-bind-keys', used by
;; the Fortran, C, and C++ modules).

;;; Code:

(require 'utility)

(require 'lang-spice)
(require 'lang-octave)
(require 'lang-bc)
(require 'lang-python)
(require 'lang-js)
(require 'lang-xppaut)
(require 'lang-sage)
(require 'lang-auctex)
(require 'lang-essmd)
(require 'lang-markdown)
(require 'lang-maxima)
(require 'lang-fortran)
(require 'lang-c)
(require 'lang-cpp)
(require 'lang-chess)

(provide 'languages)
;;; languages.el ends here
