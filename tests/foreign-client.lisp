(in-package #:sse-parity/tests)

(defparameter *foreign-client-routes*
  '(:basic :multiline :typed :id :utf8 :comment))

(defun check-foreign-client (client-kind)
  (with-peer-server (base :lisp)
    (dolist (route *foreign-client-routes*)
      (testing (format nil "~a <- lisp ~a" client-kind route)
        (ok (events-match-p (foreign-client-events client-kind (route-url base route))
                            (expected-for route)))))
    (testing (format nil "~a <- lisp last-first" client-kind)
      (ok (events-match-p (foreign-client-events client-kind
                                                 (concatenate 'string base "/last"))
                          (expected-for :last-first))))))

(deftest node-client-lisp-server
  (if (peer-available-p :node)
      (check-foreign-client :node)
      (skip "node peer not available")))

(deftest python-client-lisp-server
  (if (peer-available-p :python)
      (check-foreign-client :python)
      (skip "python peer not available")))
