(in-package #:sse-parity)

(defparameter *peer-root*
  (asdf:system-relative-pathname "sse-parity" "peers/")
  "Directory containing node/ and python/ peer programs.")

(defun %env-off-p (name)
  (member (uiop:getenv name) '("0" "false" "no" "off") :test #'string-equal))

(defun peers-enabled-p ()
  (not (%env-off-p "SSE_PARITY_PEERS")))

(defun which (program)
  (or (uiop:getenv (format nil "SSE_PARITY_~a" (string-upcase program)))
      (ignore-errors
        (string-trim '(#\space #\newline #\return)
                     (uiop:run-program (list "which" program)
                                       :output :string :error-output nil)))))

(defun node-available-p ()
  (and (peers-enabled-p)
       (which "node")
       (probe-file (merge-pathnames "node/server.mjs" *peer-root*))))

(defun python-available-p ()
  (and (peers-enabled-p)
       (or (which "uv") (which "python3"))
       (probe-file (merge-pathnames "python/server.py" *peer-root*))))

(defun peer-available-p (kind)
  (ecase kind
    (:node (node-available-p))
    (:python (python-available-p))
    (:lisp t)))

(defun %free-port ()
  (let* ((sock (usocket:socket-listen "127.0.0.1" 0 :reuseaddress t))
         (port (usocket:get-local-port sock)))
    (usocket:socket-close sock)
    port))

(defun %read-listen-line (stream timeout)
  (let ((deadline (+ (get-internal-real-time)
                     (* timeout internal-time-units-per-second))))
    (loop
      (when (> (get-internal-real-time) deadline)
        (error "peer server did not print listen line within ~a s" timeout))
      (when (listen stream)
        (let ((line (read-line stream nil nil)))
          (when (and line (search "SSE_PARITY_LISTEN" line))
            (return line))))
      (sleep 0.05))))

(defun peer-command (kind port)
  (ecase kind
    (:node
     (list (which "node")
           (uiop:native-namestring (merge-pathnames "node/server.mjs" *peer-root*))
           (princ-to-string port)))
    (:python
     (if (which "uv")
         (list (which "uv") "run"
               "--project" (uiop:native-namestring
                            (merge-pathnames "python/" *peer-root*))
               "python"
               (uiop:native-namestring (merge-pathnames "python/server.py" *peer-root*))
               (princ-to-string port))
         (list (which "python3")
               (uiop:native-namestring (merge-pathnames "python/server.py" *peer-root*))
               (princ-to-string port))))))

(defun client-command (kind url)
  (ecase kind
    (:node
     (list (which "node")
           (uiop:native-namestring (merge-pathnames "node/client.mjs" *peer-root*))
           url))
    (:python
     (if (which "uv")
         (list (which "uv") "run"
               "--project" (uiop:native-namestring
                            (merge-pathnames "python/" *peer-root*))
               "python"
               (uiop:native-namestring (merge-pathnames "python/client.py" *peer-root*))
               url)
         (list (which "python3")
               (uiop:native-namestring (merge-pathnames "python/client.py" *peer-root*))
               url)))))

(defun start-peer-server (kind &key (port (%free-port)))
  (let* ((cmd (peer-command kind port))
         (proc (uiop:launch-program cmd
                                    :output :stream
                                    :error-output :stream
                                    :element-type 'character)))
    (handler-bind ((error (lambda (c)
                            (declare (ignore c))
                            (ignore-errors (uiop:terminate-process proc :urgent t)))))
      (%read-listen-line (uiop:process-info-output proc) 8))
    (values proc port (format nil "http://127.0.0.1:~a" port))))

(defun stop-peer-server (proc)
  (when proc
    (ignore-errors (uiop:terminate-process proc :urgent t))
    (ignore-errors (uiop:wait-process proc))))

(defmacro with-peer-server ((url-var kind) &body body)
  (let ((proc (gensym "PROC"))
        (port (gensym "PORT")))
    `(if (eq ,kind :lisp)
         (call-with-lisp-server (lambda (,url-var) ,@body))
         (multiple-value-bind (,proc ,port ,url-var)
             (start-peer-server ,kind)
           (declare (ignore ,port))
           (unwind-protect (progn ,@body)
             (stop-peer-server ,proc))))))
