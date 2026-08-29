;;; lang-chess.el --- PGN chess file viewing via pygn-mode -*- lexical-binding: t; -*-

;;; Commentary:
;; PyGN mode for viewing/stepping through .pgn chess game files.  The
;; package ships with no interactive keybindings by default -- only a
;; menu-bar menu and a mouse-2 binding (the letter/chord bindings in
;; its own header comment are left commented out for the user to
;; enable) -- so they're bound here explicitly.
;;
;; Board/FEN display shells out to Python's `chess' library via
;; pygn_server.py.  If boards fail to display, run
;; `M-x pygn-mode-run-diagnostic' to check the setup, and
;; `pip install --user chess' if the library itself is missing.
;;
;; Named lang-chess.el rather than chess.el: ~/.elisp/chess already
;; exists as a directory (currently holding chess-babel.el and
;; pgn-babel.el), and ~/.emacs.d/lisp precedes ~/.elisp on
;; `load-path' (see .emacs), so a same-named module here would
;; silently shadow any real chess.el library installed there later --
;; the same hazard .emacs's own Commentary calls out for org/erc/custom.

;;; Code:

(require 'use-package)

(use-package pygn-mode
  :bind (:map pygn-mode-map
              ("C-c C-c" . pygn-mode-display-board-at-pos)
              ("M-f"     . pygn-mode-next-move-follow-board)
              ("M-b"     . pygn-mode-previous-move-follow-board)
              ("C-c C-n" . pygn-mode-next-game)
              ("C-c C-p" . pygn-mode-previous-game)))

(provide 'lang-chess)
;;; lang-chess.el ends here
