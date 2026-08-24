(in-package #:sse-parity)

(defun ev (&rest args)
  (apply #'sse-protocol:make-sse-event args))

(defparameter +routes+
  '((:basic "/basic" ((:data "hello")))
    (:multiline "/multiline" ((:data "one
two")))
    (:typed "/typed" ((:event "ping" :data "ok")))
    (:id "/id" ((:id "7" :data "x")))
    (:utf8 "/utf8" ((:data "αβγ ✔")))
    (:comment "/comment" ((:comment "keep" :data "after"))))
  "Finite SSE routes shared by Lisp/Node/Python servers.")

(defun %events-for (spec)
  (mapcar (lambda (plist)
            (apply #'ev plist))
          spec))

(defun last-event-id-from-env (env)
  (sse-backend-clack:request-last-event-id env))

(defun make-parity-app ()
  "Clack app implementing the interop route table."
  (lambda (env)
    (let* ((path (or (getf env :path-info) "/"))
           (last (last-event-id-from-env env)))
      (cond
        ((string= path "/last")
         (funcall (sse-backend-clack:make-sse-app
                   (if (equal last "1")
                       (list (ev :id "2" :data "resume"))
                       (list (ev :id "1" :data "first"))))
                  env))
        (t
         (let ((row (find path +routes+ :key #'second :test #'string=)))
           (if row
               (funcall (sse-backend-clack:make-sse-app (%events-for (third row)))
                        env)
               '(404 (:content-type "text/plain") ("not found")))))))))

(defun call-with-lisp-server (fn)
  (http-server-backend-hunchentoot:use-hunchentoot-backend)
  (sse-backend-clack:use-clack-sse-backend)
  (let ((port (%free-port)))
    (http-server-protocol:with-server (s (make-parity-app)
                                         :host "127.0.0.1" :port port)
      (sleep 0.15)
      (funcall fn (format nil "http://127.0.0.1:~a" port)))))
