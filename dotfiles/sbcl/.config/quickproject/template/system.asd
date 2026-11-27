;;;; (#| TMPL_VAR name |#).asd

(asdf:defsystem #:(#| TMPL_VAR name |#)(#| TMPL_IF description |#)
  :description (#| TMPL_VAR description-lisp |#)(#| /TMPL_IF |#)
  :author (#| TMPL_VAR author-lisp |#)
  :license (#| TMPL_VAR license-lisp |#)
  :version (#| TMPL_VAR version-lisp |#)
  :serial t(#| TMPL_IF depends-on |#)
  :depends-on (#| TMPL_VAR dependencies-string |#)(#| /TMPL_IF |#)
  :components ((:file "package")
               (:file "(#| TMPL_VAR name |#)"))
  ;; `mise run build`: an executable, bin/(#| TMPL_VAR name |#), that runs MAIN.
  :build-operation "program-op"
  :build-pathname "bin/(#| TMPL_VAR name |#)"
  :entry-point "(#| TMPL_VAR name |#):main"
  :in-order-to ((test-op (test-op "(#| TMPL_VAR name |#)/tests"))))

(asdf:defsystem #:(#| TMPL_VAR name |#)/tests
  :depends-on (#:(#| TMPL_VAR name |#) #:fiveam)
  :components ((:module "tests" :components ((:file "main"))))
  :perform (test-op (o c) (uiop:symbol-call '#:(#| TMPL_VAR name |#)/tests '#:run-tests)))
