;;; lang-cpp.el --- C++ build/run/clean/distclean key bindings -*- lexical-binding: t; -*-

;;; Commentary:
;; Binds "M-n C-c C-b/C-r/C-c/C-d" (build/run/clean/distclean, from
;; utility.el's `compiled-program-bind-keys') in c++-mode,
;; matching a per-directory makefile such as work/src/cpp/makefile:
;; `make TARGET PROGRAM=<basename>' run from the visited file's
;; directory.
;;
;; Requires utility.el.

;;; Code:

(require 'utility)

(with-eval-after-load 'cc-mode
  (compiled-program-bind-keys c++-mode-map))

(provide 'lang-cpp)
;;; lang-cpp.el ends here
