(in-package #:sse-parity/tests)

(defparameter *lisp-client-routes*
  '(:basic :multiline :typed :id :utf8 :comment))

(defun check-lisp-client (server-kind)
  (with-peer-server (base server-kind)
    (dolist (route *lisp-client-routes*)
      (testing (format nil "~a ~a" server-kind route)
        (ok (events-match-p (lisp-open-events (route-url base route))
                            (expected-for route)))))
    (testing (format nil "~a last-first" server-kind)
      (ok (events-match-p (lisp-open-events (route-url base :last-first))
                          (expected-for :last-first))))
    (testing (format nil "~a last-resume" server-kind)
      (ok (events-match-p (lisp-open-events (concatenate 'string base "/last")
                                            :last-event-id "1")
                          (expected-for :last-resume))))))

(deftest lisp-client-lisp-server
  (check-lisp-client :lisp))

(deftest lisp-client-node-server
  (if (peer-available-p :node)
      (check-lisp-client :node)
      (skip "node peer not available")))

(deftest lisp-client-python-server
  (if (peer-available-p :python)
      (check-lisp-client :python)
      (skip "python peer not available")))
