;;; browser.el --- Default browser and browser-choice helper -*- lexical-binding: t; -*-

;;; Commentary:
;; Sets Firefox as the default `browse-url' handler and defines
;; `choose-browser', an interactive command that prompts whether to
;; open a URL in the external browser or in w3m. Also autoloads w3m's
;; `w3m-browse-url'.
;;
;; `choose-browser' and `w3m-browse-url' are used by init-org.el's
;; `org-open-at-point' advice.

;;; Code:

;;;; Default browser
(setq browse-url-browser-function 'browse-url-firefox)
;; Choose browser
(setq browse-url-generic-program "/usr/bin/firefox")
(defun choose-browser (url &rest args)
  (interactive "sURL: ")
  (if (y-or-n-p "Use external browser? ")
	  (browse-url-generic url)
	    (w3m-browse-url url)))

;;;; w3m
(autoload 'w3m-browse-url "w3m" "Ask a WWW browser to show a URL." t)
;; optional keyboard short-cut
;; (global-set-key "\C-xm" 'browse-url-at-point)

(provide 'browser)
;;; browser.el ends here
