;;;; tests/main.lisp: `mise run test`, or (asdf:test-system "(#| TMPL_VAR name |#)") at the REPL.

(defpackage #:(#| TMPL_VAR name |#)/tests
  (:use #:cl #:fiveam)
  (:import-from #:(#| TMPL_VAR name |#) #:greeting)
  (:export #:run-tests))

(in-package #:(#| TMPL_VAR name |#)/tests)

(def-suite (#| TMPL_VAR name |#))
(in-suite (#| TMPL_VAR name |#))

(defun run-tests ()
  "Run every test; true when they all pass."
  (run! '(#| TMPL_VAR name |#)))

(test greets
  (is (string= "Hello, world!" (greeting '())))
  (is (string= "Hello, a b!" (greeting '("a" "b")))))
