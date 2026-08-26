;;; lang-fortran.el --- Fortran build/run/clean/distclean key bindings -*- lexical-binding: t; -*-

;;; Commentary:
;; Binds "M-n C-c C-b/C-r/C-c/C-d" (build/run/clean/distclean, from
;; utility.el's `compiled-program-bind-keys') in both
;; fortran-mode (fixed-form .f/.for/.f77) and f90-mode (free-form .f90
;; and later), matching a per-directory makefile such as
;; work/src/fortran/makefile: `make TARGET PROGRAM=<basename>' run
;; from the visited file's directory.
;;
;; Also maps .f77 to fortran-mode: Emacs's default `auto-mode-alist'
;; already covers .f/.for but not .f77 (a non-standard but sometimes
;; used fixed-form Fortran 77 extension -- the actual standard is
;; .f/.for/.ftn).
;;
;; Requires utility.el.

;;; Code:

(require 'utility)

(add-to-list 'auto-mode-alist '("\\.f77\\'" . fortran-mode))

(with-eval-after-load 'fortran
  (compiled-program-bind-keys fortran-mode-map))

(with-eval-after-load 'f90
  (compiled-program-bind-keys f90-mode-map))

(provide 'lang-fortran)
;;; lang-fortran.el ends here
