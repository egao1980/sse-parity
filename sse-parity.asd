(defsystem "sse-parity"
  :version "0.1.0"
  :description "Interop canary: sse-protocol vs Node/Python SSE servers and clients"
  :author "egao1980"
  :license "MIT"
  :depends-on ("sse-protocol"
               "sse-backend-http"
               "sse-backend-clack"
               "http-protocol"
               "http-backend-dexador"
               "http-server-protocol"
               "http-server-backend-hunchentoot"
               "alexandria"
               "babel"
               "uiop"
               "usocket"
               "yason"
               "rove")
  :serial t
  :pathname "src"
  :components ((:file "package")
               (:file "peers")
               (:file "lisp-server")
               (:file "harness")
               (:file "report"))
  :in-order-to ((test-op (test-op "sse-parity/tests"))))

(defsystem "sse-parity/tests"
  :depends-on ("sse-parity" "rove")
  :pathname "tests"
  :serial t
  :components ((:file "package")
               (:file "lisp-client")
               (:file "foreign-client"))
  :perform (test-op (o c)
             (unless (symbol-call :rove :run c)
               (error "sse-parity tests failed"))))
