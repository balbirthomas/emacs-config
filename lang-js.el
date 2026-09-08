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
;;   opens it in its own buffer, e.g. "*js-node*", "*js-quickjs*",
;;   "*js-mujs*" -- so more than one can run at once. Calling it again
;;   for an interpreter that's already running just switches to that
;;   buffer; "C-u C-c C-p" kills and restarts it.
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
;; "C-c l" in the REPL buffer clears it.
;;
;; Note: MuJS's REPL does not echo a prompt or auto-print expression
;; values the way Node's and QuickJS's do -- use `print(...)'
;; explicitly to see output from it.
;;
;; `enable-comint-mime-js' (off by default; toggle with `M-x
;; toggle-comint-mime-js') turns on comint-mime -- see lang-python.el's
;; Commentary for what that is generally -- in the "node" REPL, so
;; e.g. a node-canvas (Debian's node-canvas package) Canvas can be
;; drawn inline in the REPL buffer with `showCanvas(canvas)' instead
;; of printing as a plain object. See that variable's docstring for
;; how to use it.
;;
;; Two REPL backends, chosen automatically per interpreter:
;;
;; - comint (Emacs's normal REPL machinery; the default). Node and
;;   MuJS use this -- no extra dependency.
;;
;; - Eat (a real terminal emulator; see `js-repl-eat-interpreters').
;;   QuickJS's `-i' REPL does its own cursor-addressed redraws
;;   (colored syntax highlighting, in-place line editing), which
;;   comint -- a plain line-based abstraction with no way to execute a
;;   "move cursor back and erase" escape sequence -- cannot render: it
;;   can only ever append text, so each of QuickJS's redraws piles up
;;   as more text instead of replacing the last one, e.g. sending
;;   `console.log("hello")' shows up mangled as
;;   "ccoconconsconsoconsole...console.log(\"hello\")". Eat is a
;;   proper terminal emulator, so it renders these correctly, at the
;;   cost of a real dependency: the `eat' package (packaged here as
;;   Debian's elpa-eat -- see debian/ in the emacs-eat checkout
;;   alongside this directory -- deliberately not installed from
;;   ELPA). `run-js' requires it lazily, only when actually starting
;;   an interpreter listed in `js-repl-eat-interpreters', so editing
;;   JS or running Node/MuJS never needs it installed.

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

(defcustom js-repl-eat-interpreters '("quickjs")
  "Names (from `js-repl-interpreters') that need Eat instead of comint.
See this file's Commentary for why. Interpreters not listed here use
plain comint and never require Eat to be installed."
  :type '(repeat string)
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
      (if (member name js-repl-eat-interpreters)
          (progn
            (unless (require 'eat nil t)
              (user-error "Eat is not installed (Debian package elpa-eat), needed for %s" name))
            (setq buffer (apply #'eat-make (concat "js-" name) program nil args))
            (with-current-buffer buffer (local-set-key (kbd "C-c l") 'eat-reset)))
        (setq buffer (apply #'make-comint-in-buffer name buffer-name program nil args))
        (with-current-buffer buffer (inferior-js-mode))))
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
    (with-current-buffer buffer
      (if (eq major-mode 'eat-mode)
          (eat-term-send-string eat-terminal (concat string "\n"))
        (comint-send-string buffer string)
        (comint-send-string buffer "\n")))
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

;;;; comint-mime (optional, off by default)
;;
;; Inline image display (e.g. a node-canvas Canvas) in the "node" REPL
;; buffer. See lang-python.el's Commentary for what comint-mime is
;; generally; this applies the same mechanism to `inferior-js-mode',
;; but only for the "node" interpreter -- comint-mime-node.js needs
;; Node's `.load' REPL command and `require("canvas")', neither of
;; which QuickJS or MuJS have.
(defcustom enable-comint-mime-js nil
  "Non-nil to enable comint-mime (inline image display) in the \"node\"
REPL buffer started by `run-js'.

Once enabled, in that REPL:

    const {createCanvas} = require(\"canvas\");
    const canvas = createCanvas(200, 200);
    const ctx = canvas.getContext(\"2d\");
    ctx.fillStyle = \"tomato\";
    ctx.fillRect(20, 20, 160, 160);
    showCanvas(canvas);

draws the canvas directly in the buffer instead of printing a
\"Canvas { ... }\" object. `mimecat(buffer, type)' is also available
for sending other MIME data by hand; see comint-mime-node.js."
  :type 'boolean
  :group 'local)

(defvar comint-mime-node-script
  (expand-file-name "comint-mime-node.js"
                     (file-name-directory (or load-file-name buffer-file-name)))
  "Path to the Node-side comint-mime helper loaded by `comint-mime-setup-js'.")

(defun comint-mime-setup-js (&rest _)
  "Setup code specific to `inferior-js-mode', for
`comint-mime-setup-function-alist'.
Only acts in a \"*js-node*\" buffer (see `js-repl-buffer-name'); does
nothing in other `inferior-js-mode' buffers (MuJS), which have no
`canvas' module for `comint-mime-node-script' to use. Waits for the
REPL's first output (Node's startup banner and prompt) before sending
anything, since sending it any earlier could race Node's own startup;
removes itself from `comint-output-filter-functions' once it has
fired.

Sends a single `eval(...)' line that reads and evaluates
`comint-mime-node-script' in one shot, rather than Node's own `.load'
REPL command -- `.load' also echoes every line of the file (and each
line's result) back into the buffer, which for even a short script is
a lot of noise for a one-time setup step."
  (if (not (equal (buffer-name) (js-repl-buffer-name "node")))
      (remove-hook 'comint-output-filter-functions 'comint-mime-setup-js t)
    (if (= (point-min) (point-max))
        (add-hook 'comint-output-filter-functions 'comint-mime-setup-js nil t)
      (remove-hook 'comint-output-filter-functions 'comint-mime-setup-js t)
      (comint-send-string
       (get-buffer-process (current-buffer))
       (format "eval(require(%S).readFileSync(%S, \"utf8\"));\n"
               "fs" comint-mime-node-script)))))

(defun load-comint-mime-js ()
  "Load comint-mime and hook it into `inferior-js-mode'.
Also runs `comint-mime-setup' immediately in the \"*js-node*\" buffer
if one is already running, since `inferior-js-mode-hook' (added here)
only fires for buffers started after this call -- without this,
toggling comint-mime-js on while a node REPL is already open would
silently do nothing to it until it's restarted."
  (interactive)
  (add-to-list 'load-path "~/.elisp/comint-mime/")
  (require 'comint-mime)
  (unless (assq 'inferior-js-mode comint-mime-setup-function-alist)
    (push '(inferior-js-mode . comint-mime-setup-js) comint-mime-setup-function-alist))
  (add-hook 'inferior-js-mode-hook 'comint-mime-setup)
  (when-let ((buffer (get-buffer (js-repl-buffer-name "node"))))
    (with-current-buffer buffer
      (when (derived-mode-p 'inferior-js-mode)
        (comint-mime-setup)))))

(defun unload-comint-mime-js ()
  "Remove comint-mime's hook from `inferior-js-mode'.
Only affects buffers created after this call; existing buffers keep
whatever was already set up in them."
  (interactive)
  (remove-hook 'inferior-js-mode-hook 'comint-mime-setup))

(defun toggle-comint-mime-js ()
  "Toggle `enable-comint-mime-js' and apply the change immediately."
  (interactive)
  (setq enable-comint-mime-js (not enable-comint-mime-js))
  (if enable-comint-mime-js
      (load-comint-mime-js)
    (unload-comint-mime-js))
  (message "comint-mime-js %s" (if enable-comint-mime-js "enabled" "disabled")))

(when enable-comint-mime-js
  (load-comint-mime-js))

(provide 'lang-js)
;;; lang-js.el ends here
