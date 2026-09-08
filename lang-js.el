;;; lang-js.el --- JavaScript editing + multi-interpreter REPL -*- lexical-binding: t; -*-

;;; Commentary:
;; JavaScript support built on Emacs's built-in `js-mode' (already the
;; default major mode for .js files -- nothing to install for editing).
;;
;; Adds a REPL layer that can drive any of several JavaScript
;; interpreters (Node.js, QuickJS, MuJS by default; see
;; `js-repl-interpreters' to add/change others) instead of hardcoding
;; one:
;;
;; - "C-c C-p" (`run-js') prompts for which interpreter to use and
;;   opens it in its own comint buffer, e.g. "*js-node*",
;;   "*js-quickjs*", "*js-mujs*" -- so more than one can run at once.
;;   Calling it again for an interpreter that's already running just
;;   switches to that buffer; "C-u C-c C-p" kills and restarts it.
;;
;; - "C-c C-c" sends the whole buffer to the REPL; "C-c C-e" sends the
;;   active region, or the current line if no region is active ("send
;;   statement" -- js-mode has no real statement-boundary detection to
;;   do better than that, unlike python.el's C-c C-c/C-c C-v).
;;
;; Each js-mode buffer remembers which REPL buffer it last sent code
;; to (buffer-local `js-repl-target-buffer'); the first send in a
;; buffer, or after that REPL buffer is gone, prompts (via `run-js')
;; to pick or start one.
;;
;; "C-c l" in the REPL buffer clears it, matching lang-python.el's
;; inferior-python-mode binding (via `clear-comint-buffer' from
;; utility.el).
;;
;; Note: MuJS's REPL does not echo a prompt or auto-print expression
;; values the way Node's and QuickJS's do -- use `print(...)'
;; explicitly to see output from it.

;;; Code:

(require 'js)
(require 'comint)
(require 'utility)

;;;; Which interpreters `run-js' can start
(defcustom js-repl-interpreters
  '(("node"    . "node -i")
    ("quickjs" . "qjs -i")
    ("mujs"    . "mujs -i"))
  "Alist of (NAME . SHELL-COMMAND) JavaScript interpreters `run-js' can start.
SHELL-COMMAND is split on whitespace into a program and its arguments;
the program must be on `exec-path'. Add, remove, or edit entries to
change what `run-js' offers."
  :type '(alist :key-type string :value-type string)
  :group 'local)

(defvar js-repl-last-interpreter nil
  "Name (from `js-repl-interpreters') last chosen in `run-js'.
Used as the default the next time it prompts.")

(defvar-local js-repl-target-buffer nil
  "The REPL buffer this js-mode buffer last sent code to.
Set automatically by `run-js' and by the send commands when they have
to prompt for one; see `js-repl-get-buffer'.")

;;;; inferior-js-mode: the REPL buffer's major mode
(define-derived-mode inferior-js-mode comint-mode "Inferior JS"
  "Major mode for a running JavaScript interpreter started by `run-js'.")

(define-key inferior-js-mode-map (kbd "C-c l") 'clear-comint-buffer)

;;;; Starting/switching to a REPL
(defun js-repl-buffer-name (interpreter-name)
  "Comint buffer name for INTERPRETER-NAME, e.g. \"*js-node*\"."
  (format "*js-%s*" interpreter-name))

(defun run-js (&optional restart)
  "Start, or switch to, a JavaScript REPL.
Prompts for which interpreter (from `js-repl-interpreters') to use.
If that interpreter already has a live REPL buffer, just switches to
it -- unless RESTART (the prefix argument) is non-nil, in which case
the existing process is killed and a fresh one started.
If called from a js-mode buffer, that buffer's `js-repl-target-buffer'
is set to the new REPL so subsequent sends go there."
  (interactive "P")
  (let* ((source-buffer (and (derived-mode-p 'js-mode) (current-buffer)))
         (name (completing-read
                (format "JavaScript interpreter%s: "
                        (if js-repl-last-interpreter
                            (format " (default %s)" js-repl-last-interpreter)
                          ""))
                (mapcar #'car js-repl-interpreters)
                nil t nil nil js-repl-last-interpreter))
         (command (or (cdr (assoc name js-repl-interpreters))
                      (user-error "Unknown interpreter: %s" name)))
         (parts (split-string command))
         (program (car parts))
         (args (cdr parts))
         (buffer-name (js-repl-buffer-name name))
         (buffer (get-buffer buffer-name)))
    (setq js-repl-last-interpreter name)
    (unless (executable-find program)
      (user-error "%s not found on exec-path" program))
    (when (and restart buffer)
      (let ((proc (get-buffer-process buffer)))
        (when (process-live-p proc) (delete-process proc)))
      (let ((kill-buffer-query-functions nil))
        (kill-buffer buffer))
      (setq buffer nil))
    (unless (and buffer (process-live-p (get-buffer-process buffer)))
      (setq buffer (apply #'make-comint-in-buffer name buffer-name program nil args))
      (with-current-buffer buffer (inferior-js-mode)))
    (when source-buffer
      (with-current-buffer source-buffer
        (setq js-repl-target-buffer buffer)))
    (pop-to-buffer buffer)))

;;;; Sending code
(defun js-repl-get-buffer ()
  "Return the REPL buffer this js-mode buffer should send code to.
Prompts (via `run-js') to pick or start one if there isn't a live one
already associated in `js-repl-target-buffer'."
  (let ((source (current-buffer)))
    (unless (and js-repl-target-buffer
                 (buffer-live-p js-repl-target-buffer)
                 (process-live-p (get-buffer-process js-repl-target-buffer)))
      (call-interactively 'run-js))
    (buffer-local-value 'js-repl-target-buffer source)))

(defun js-send-string (string)
  "Send STRING, followed by a newline, to this buffer's JS REPL.
Displays the REPL buffer without selecting it."
  (let ((buffer (js-repl-get-buffer)))
    (comint-send-string buffer string)
    (comint-send-string buffer "\n")
    (display-buffer buffer)))

(defun js-send-buffer ()
  "Send the whole buffer to its JavaScript REPL."
  (interactive)
  (js-send-string (buffer-substring-no-properties (point-min) (point-max))))

(defun js-send-dwim ()
  "Send the active region, or else the current line, to the JavaScript REPL."
  (interactive)
  (js-send-string
   (if (use-region-p)
       (buffer-substring-no-properties (region-beginning) (region-end))
     (buffer-substring-no-properties (line-beginning-position) (line-end-position)))))

;;;; Key bindings in js-mode
(define-key js-mode-map (kbd "C-c C-p") 'run-js)
(define-key js-mode-map (kbd "C-c C-c") 'js-send-buffer)
(define-key js-mode-map (kbd "C-c C-e") 'js-send-dwim)

(provide 'lang-js)
;;; lang-js.el ends here
