(in-package #:sse-parity)

(defun print-matrix ()
  (format t "~&sse-parity matrix~%")
  (format t "  peers: node=~a python=~a~%"
          (if (node-available-p) "yes" "no")
          (if (python-available-p) "yes" "no"))
  (format t "  lisp client × foreign server: basic/multiline/typed/id/utf8/comment/last/retry/hold/reconnect~%")
  (format t "  foreign client × lisp server: same plus /retry /hold (reconnect skip)~%")
  (format t "  gaps: MIME/charset skip; foreign EventSource reconnect skip~%")
  (values))
