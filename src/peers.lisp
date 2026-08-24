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

(defun python-venv ()
  (let ((root (merge-pathnames "python/" *peer-root*)))
    (find-if #'probe-file
             (list (merge-pathnames ".venv/bin/python" root)
                   (merge-pathnames ".venv/bin/python3" root)
                   (merge-pathnames ".venv/Scripts/python.exe" root)))))

(defun python-available-p ()
  (and (peers-enabled-p)
       (or (python-venv) (which "uv") (which "python3"))
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
      (loop while (ignore-errors (listen stream))
            for line = (read-line stream nil nil)
            do (when (and line (search "SSE_PARITY_LISTEN" line))
                 (return-from %read-listen-line line)))
      (sleep 0.05))))

(defun %slurp-available (stream)
  (when stream
    (with-output-to-string (out)
      (loop while (ignore-errors (listen stream))
            for line = (read-line stream nil nil)
            while line
            do (write-line line out)))))

(defun python-cmd (script &rest args)
  "Prefer the uv-sync venv. `uv run` on macos-latest CI can exceed 8s before
   the listen line; server.py is stdlib-only so python3 is enough as fallback."
  (let* ((script-path (uiop:native-namestring
                       (merge-pathnames script (merge-pathnames "python/" *peer-root*))))
         (venv (python-venv)))
    (cond
      (venv
       (list* (uiop:native-namestring venv) script-path args))
      ((and (string= script "server.py") (which "python3"))
       (list* (which "python3") script-path args))
      ((which "uv")
       (list* (which "uv") "run" "--no-sync"
              "--project" (uiop:native-namestring (merge-pathnames "python/" *peer-root*))
              "python" script-path args))
      ((which "python3")
       (list* (which "python3") script-path args))
      (t
       (error "no python runtime for peer ~a" script)))))

(defun peer-command (kind port)
  (ecase kind
    (:node
     (list (which "node")
           (uiop:native-namestring (merge-pathnames "node/server.mjs" *peer-root*))
           (princ-to-string port)))
    (:python
     (python-cmd "server.py" (princ-to-string port)))))

(defun client-command (kind url)
  (ecase kind
    (:node
     (list (which "node")
           (uiop:native-namestring (merge-pathnames "node/client.mjs" *peer-root*))
           url))
    (:python
     (python-cmd "client.py" url))))

(defun start-peer-server (kind &key (port (%free-port)) (timeout 30))
  (let* ((cmd (peer-command kind port))
         (proc (uiop:launch-program cmd
                                    :output :stream
                                    :error-output :stream
                                    :element-type 'character)))
    (handler-case
        (%read-listen-line (uiop:process-info-output proc) timeout)
      (error (e)
        (let ((err (%slurp-available (uiop:process-info-error-output proc)))
              (out (%slurp-available (uiop:process-info-output proc))))
          (ignore-errors (uiop:terminate-process proc :urgent t))
          (error "~a~%cmd: ~s~%stderr:~%~a~%stdout:~%~a" e cmd err out))))
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
