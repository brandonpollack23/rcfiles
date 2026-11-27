;;;; (#| TMPL_VAR name |#).lisp

(in-package #:(#| TMPL_VAR name |#))

(defun greeting (args)
  (format nil "Hello, ~:[world~;~:*~{~a~^ ~}~]!" args))

(defun main ()
  "The entry point, of bin/(#| TMPL_VAR name |#) (`mise run build`) and of `mise run run`.
The program exits 0 if it returns true, 1 if it returns NIL."
  (write-line (greeting (uiop:command-line-arguments)))
  t)
