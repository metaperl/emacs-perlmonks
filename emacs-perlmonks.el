;;; pastebin.el --- A simple interface to www.perlmonks.org

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
;;; Load this file and run:
;;;
;;;   M-x pastebin-buffer
;;;
;;; to send the whole buffer or select a region and run
;;;
;;;  M-x pastebin
;;;
;;; to send just the region.
;;;
;;; In either case the url that pastebin generates is left on the kill
;;; ring and the paste buffer.


;;; Code:

;;;###autoload
(defgroup pastebin nil
  "Pastebin -- pastebin.com client"
  :tag "Pastebin"
  :group 'tools)

(defcustom pastebin-default-domain "pastebin.com"
  "Pastebin domain to use by default"
  :type 'string
  :group 'pastebin
  )

(defcustom pastebin-domain-versions '(("pastebin.com" "/api_public.php")
                                      ("pastebin.example.com" "/pastebin.php"))
  "The version of pastebin that is supported by domains that you use.

As Pastebin changes versions they sometimes change the path used. 
Valid paths are:

 /pastebin.php   - early version
 /api_public.php - current version

The pastebin code adapts to the version depending on this.
"
  :group 'pastebin
  )

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

; # emacs
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

;;;###autoload
(defun pastebin-buffer (&optional domain)
  "Send the whole buffer to pastebin.com.
Optional argument domain will request the virtual host to use,
eg:'emacs.pastebin.com' or 'mylocalpastebin.com'."
  (interactive
   (let ((pastebin-domain
          (if current-prefix-arg
              (read-string "pastebin domain:" 
                           pastebin-default-domain
                           'pastebin-domain-history) pastebin-default-domain)))
     (list pastebin-domain)))
  (pastebin (point-min) (point-max) domain))



;;;###autoload
(defun pastebin (start end &optional domain)
  "Send the region to the pastebin service specified by domain.

See pastebin.com for more information about pastebin.

Called interactively pastebin uses the current region for
preference for sending... if the mark is NOT set then the entire
buffer is sent.

Argument START is the start of region.
Argument END is the end of region.

If domain is used pastebin prompts for a domain defaulting to
'pastebin-default-domain' so you can send requests or use a
different domain.
"
  (interactive
   (let ((pastebin-domain
          (if current-prefix-arg
              (read-string "pastebin domain:" 
                           pastebin-default-domain
                           'pastebin-domain-history) pastebin-default-domain)))
     (if (mark)
         (list (region-beginning) (region-end) pastebin-domain)
       (list (point-min) (point-max) pastebin-domain))))
  ;; Main function
  (if (not domain)
      (setq domain pastebin-default-domain))
  (let* ((path (cadr (assoc domain pastebin-domain-versions)))
         (params (cond
                  ((equal path "/api_public.php")
                   (concat "submit=submit"
                           "&paste_private=0"
                           "&paste_expire_date=N"
                           (if (not (equal domain "pastebin.com")) 
                               "&paste_subdomain=%s"
                             "paste_placeholder=%s")
                           "&paste_format=%s"
                           "&paste_name=%s"
                           "&paste_code=%s"))
                  ((equal path "/pastebin.php")
                   (concat "paste=Send"
                           "&private=0"
                           "&expiry=N"
                           "&subdomain=%s"
                           "&format=%s"
                           "&poster=%s"
                           "&code2=%s"))
                  ('t
                   (signal 
                    'pastebin-version-error 
                    "pastebin.el doesn't support that version of pastebin"))))
         (data (buffer-substring-no-properties start end))
         (pastebin-url (format "http://%s%s" domain path))
         (url-request-method "POST")
         (url-request-extra-headers
          '(("Content-Type" . "application/x-www-form-urlencoded")))
         (url-request-data
          (concat (format 
                   params 
                   domain
                   (or (assoc-default major-mode pastebin-type-assoc) "text")
                   (url-hexify-string (user-full-name))
                   (url-hexify-string data))))
         (content-buf (url-retrieve 
                       pastebin-url
                       (lambda (arg)
                         (cond
                          ((equal :error (car arg))
                           (signal 'pastebin-error (cdr arg)))
                          (t
                           (re-search-forward "\n\n")
                           (clipboard-kill-ring-save (point) (point-max))
                           (message "Pastebin URL: %s" (buffer-substring (point) (point-max)))))))))))

(provide 'pastebin)
;;; pastebin.el ends here
