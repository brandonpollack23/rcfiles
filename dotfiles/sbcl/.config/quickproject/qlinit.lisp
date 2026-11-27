;;;; qlinit.lisp: what the qlinit zsh function (.zshrc) runs, with
;;;; `sbcl --non-interactive --load`. It makes a quickproject skeleton from
;;;; template/ next to this file, with what qlinit asked for, in QLINIT_*
;;;; variables (environment variables, so nothing is quoted into Lisp).

(ql:quickload "quickproject" :silent t)

(defun qlinit-env (name &optional (default ""))
  (let ((value (sb-ext:posix-getenv name)))
    (if (plusp (length value)) value default)))

(let* ((dir (sb-ext:parse-native-namestring (qlinit-env "QLINIT_DIR")
                                            nil *default-pathname-defaults*
                                            :as-directory t))
       (author (qlinit-env "QLINIT_AUTHOR" quickproject:*author*))
       (license (qlinit-env "QLINIT_LICENSE" "MIT"))
       (description (qlinit-env "QLINIT_DESCRIPTION" nil)) ; nil leaves it out
       (version (qlinit-env "QLINIT_VERSION" "0.0.1"))
       (depends-on (mapcar (lambda (system) (intern (string-upcase system) :keyword))
                           (uiop:split-string (qlinit-env "QLINIT_DEPENDS")
                                              :separator '(#\Space #\Tab))))
       (depends-on (remove (intern "" :keyword) depends-on)))
  (quickproject:make-project
   dir
   :name (qlinit-env "QLINIT_NAME")
   :author author
   :license license
   :depends-on depends-on
   :template-directory (merge-pathnames "template/"
                                        (uiop:pathname-directory-pathname *load-truename*))
   ;; The template writes the *-lisp ones as Lisp strings, quotes and
   ;; backslashes escaped, into the .asd; the plain ones go in the README.
   :template-parameters (list :description description
                              :description-lisp (prin1-to-string description)
                              :author-lisp (prin1-to-string author)
                              :license-lisp (prin1-to-string license)
                              :version-lisp (prin1-to-string version)))
  ;; Download the dependencies now, and FiveAM for the tests. One Quicklisp
  ;; doesn't have stays in the .asd, with a warning.
  (dolist (system (append depends-on '(:fiveam)))
    (handler-case (ql:quickload system :silent t)
      (error (e)
        (format *error-output* "qlinit: couldn't load ~(~a~): ~a~%" system e)))))
