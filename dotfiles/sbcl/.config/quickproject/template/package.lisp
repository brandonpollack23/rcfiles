;;;; package.lisp

(defpackage #:(#| TMPL_VAR name |#)
  (:use #:cl)
  (:export #:main #:greeting))
