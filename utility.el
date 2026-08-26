;;; utility.el --- Generic helper functions used by other modules -*- lexical-binding: t; -*-

;;; Commentary:
;; `getenv-or-warn': read an environment variable, falling back to a
;; default if given, or warning via `message' if not. Used throughout
;; this configuration to keep personal information (name, email, IRC
;; login, local install paths) out of the Lisp and in the environment
;; instead -- see README.md.
;;
;; `close-and-kill-next-pane': close the other window and kill the
;; buffer displayed in it.
;; `clear-comint-buffer': truncate the current comint buffer; bound to
;; "C-c l" in Python and SageMath shells by languages.el.
;;
;; `build-current-program', `run-current-program',
;; `clean-current-program', `distclean-current-program': run the
;; `build'/`run'/`clean'/`distclean' targets of a makefile in the
;; current file's directory, passing PROGRAM=<basename-without-extension>
;; and EXT=<extension> of the current file, in a `compile' buffer.
;; `compiled-program-bind-keys'
;; binds all four to "M-n C-c C-b/C-r/C-c/C-d" in a given keymap; see
;; lang-fortran.el for how a language module wires this up. To
;; support a new compiled language: write a makefile with the same
;; four targets and PROGRAM convention (see work/src/fortran/makefile
;; for the model), then add a
;;   (with-eval-after-load 'FEATURE (compiled-program-bind-keys MODE-MAP))
;; stanza -- no changes needed here.
;;
;; Load this module before languages.el, which uses
;; `clear-comint-buffer' and `compiled-program-bind-keys'.

;;; Code:

;;;; Environment variables
(defun getenv-or-warn (var &optional default)
  "Return the value of environment variable VAR.
If VAR is unset, return DEFAULT if given; otherwise warn via
`message' and return nil."
  (or (getenv var)
      default
      (progn (message "Warning: environment variable %s is not set" var) nil)))

;;;; Utility functions
(defun close-and-kill-next-pane ()
  "If there are multiple windows, then close the other pane and kill the buffer in it also."
  (interactive)
  (other-window 1)
  (kill-this-buffer)
  (if (not (one-window-p))
	  (delete-window)))

;;;; Functions to clear interactive shell buffer
(defun clear-comint-buffer ()
  (interactive)
    (let ((comint-buffer-maximum-size 0))
          (comint-truncate-buffer)))

;;;; Build/run/clean/distclean a single-file compiled program via make
(defun run-make-target (target &optional comint)
  "Run \"make TARGET PROGRAM=<basename> EXT=<extension>\" for the current file.
Uses a makefile expected to live in the same directory as the file
being visited, run with that directory as `default-directory'.
PROGRAM is the file's basename without extension and EXT is its
extension, e.g. PROGRAM=foo EXT=f90 for \"foo.f90\" -- passing EXT
explicitly (rather than leaving it to the makefile to guess) matters
when more than one extension variant of the same PROGRAM exists in a
directory (e.g. foo.f90 and foo.f77): only the buffer knows which one
is actually open. Output goes to a `compile' buffer.
If COMINT is non-nil, the buffer runs in Comint mode instead of plain
Compilation mode, so keystrokes are sent to the subprocess's stdin --
needed for `run', whose program may prompt for interactive input."
  (let* ((file (or buffer-file-name
                    (user-error "Buffer is not visiting a file")))
         (default-directory (file-name-directory file))
         (program (file-name-base file))
         (ext (file-name-extension file)))
    (compile (format "make %s PROGRAM=%s%s" target
                      (shell-quote-argument program)
                      (if ext (format " EXT=%s" (shell-quote-argument ext)) ""))
              comint)))

(defun build-current-program ()
  "Run the makefile's `build' target for the current file's program."
  (interactive)
  (run-make-target "build"))

(defun run-current-program ()
  "Run the makefile's `run' target for the current file's program.
Runs in Comint mode so the program can read interactive input from
the buffer -- see `run-make-target'."
  (interactive)
  (run-make-target "run" t))

(defun clean-current-program ()
  "Run the makefile's `clean' target for the current file's program."
  (interactive)
  (run-make-target "clean"))

(defun distclean-current-program ()
  "Run the makefile's `distclean' target for the current file's program."
  (interactive)
  (run-make-target "distclean"))

(defun compiled-program-bind-keys (map)
  "Bind the build/run/clean/distclean commands in MAP."
  (define-key map (kbd "M-n C-c C-b") 'build-current-program)
  (define-key map (kbd "M-n C-c C-r") 'run-current-program)
  (define-key map (kbd "M-n C-c C-c") 'clean-current-program)
  (define-key map (kbd "M-n C-c C-d") 'distclean-current-program))

(provide 'utility)
;;; utility.el ends here
