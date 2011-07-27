;;; perlmonks.el --- A simple interface to www.perlmonks.org

;;; Copyright (C) (range 2011 'forever) by Terrence Brannon <metaperl@gmail.com>
;;; Acknowledgements: jlf in #emacs

;;; This program is free software; you can redistribute it and/or modify
;;; it under the terms of the GNU General Public License as published by
;;; the Free Software Foundation; either version 2, or (at your option)
;;; any later version.

;;; This program is distributed in the hope that it will be useful,
;;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;;; GNU General Public License for more details.

;;; You should have received a copy of the GNU General Public License
;;; along with this program; see the file COPYING.  If not, write to the
;;; Free Software Foundation, Inc.,   51 Franklin Street, Fifth Floor,
;;; Boston, MA  02110-1301  USA

;;; Commentary:
;;;
;;; Load this file and then:
;;;
;;;   M-x perlmonks-login
;;;
;;; to setup a url-cookie so that you can then:
;;;
;;;  M-x perlmonks-sopw
;;;
;;; to edit a buffer for submission to Perlmonks


;;; Code:

;;;###autoload
(defgroup perlmonks nil
  "Perlmonks -- perlmonks.org client"
  :tag "Perlmonks"
  :group 'tools)


(defun epm-http-post (url args)
  (interactive)
  "Send ARGS to URL as a POST request."
      (let ((url-request-method "POST")
            (url-request-extra-headers
             '(("Content-Type" . "application/x-www-form-urlencoded")))
            (url-request-data
             (mapconcat (lambda (arg)
                          (concat (url-hexify-string (car arg))
                                  "="
                                  (url-hexify-string (cdr arg))))
                        args
                        "&")))
        ;; if you want, replace `my-switch-to-url-buffer' with `my-kill-url-buffer'
        (url-retrieve url 'my-switch-to-url-buffer)))

    (defun my-kill-url-buffer (status)
      "Kill the buffer returned by `url-retrieve'."
      (kill-buffer (current-buffer)))

    (defun my-switch-to-url-buffer (status)
      "Switch to the buffer returned by `url-retreive'.
    The buffer contains the raw HTTP response sent by the server."
      (switch-to-buffer (current-buffer)))

; irc.freenode.net, #emacs
; [14:08] <jlf> er,  (interactive "sString1:\nsString2:") or somesuch

(defun perlmonks-login (username password)
  "Login to perlmonks.org with USERNAME and PASSWORD and setting a cookie which will
expire in 10 years."
  (interactive "sUsername: 
sPassword: ")
  (epm-http-post "http://www.perlmonks.org"
		 `(
		   ("node_id"	. "109")
		   ("op"	. "login")
		   ("user" . 	,username)
		   ("passwd" .	,password)
		   ("expires"	. "+10y")
		   ("sexisgood"	. "submit")
		   (".cgifields" .	"expires"))
		 ))

(defun perlmonks-sopw (node-title)
  "Post current buffer to Seekers of Perl Wisdom on perlmonks.org with NODE-TITLE"
  (interactive "sNode title? ")
  (let ((msg-text (buffer-substring (point-min) (point-max))))
    (epm-http-post "http://www.perlmonks.org"
		 `(
		   ("node_id"	. "479")
		   ("type"	. "perlquestion")
		   ("node" . 	,node-title)
		   ("perlquestion_doctext" .	,msg-text)
		   ("op" .	"create"))
		 )))

(defun perlmonks-blockquote ()
   (interactive)
   (kill-region (point) (mark))
   (insert "\n<blockquote><i>\n    ")
   (yank)
   (insert "\n</i></blockquote>\n\n")
 )

(provide 'perlmonks)
;;; pastebin.el ends here
