;;; lang-bc.el --- GNU bc mode setup -*- lexical-binding: t; -*-

;;; Commentary:
;; GNU bc mode for .bc files and #!/usr/bin/env bc scripts.

;;; Code:

(require 'use-package)

(use-package bc-mode
  :mode (".bc\\'" . bc-mode)
  :interpreter ("bc" . bc-mode))

(provide 'lang-bc)
;;; lang-bc.el ends here
