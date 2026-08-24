(in-package #:sse-parity)

(defun print-matrix ()
  (format t "~&sse-parity matrix~%")
  (format t "  peers: node=~a python=~a~%"
          (if (node-available-p) "yes" "no")
          (if (python-available-p) "yes" "no"))
  (format t "  lisp client × foreign server: basic/multiline/typed/id/utf8/comment/last~%")
  (format t "  foreign client × lisp server: same routes~%")
  (format t "  gaps: long-lived chunked emit (clack finite body), reconnect/backoff, MIME~%")
  (values))
