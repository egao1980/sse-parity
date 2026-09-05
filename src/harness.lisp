(in-package #:sse-parity)

(defun %bind-lisp-client ()
  (setf http-protocol:*http-backend*
        (http-backend-dexador:make-dexador-backend))
  (sse-backend-http:use-http-sse-backend))

(defun event-plist (ev)
  (list :id (sse-protocol:sse-event-id ev)
        :event (or (sse-protocol:sse-event-type ev) "message")
        :data (sse-protocol:sse-event-data ev)))

(defun lisp-open-events (url &key last-event-id include-empty)
  (%bind-lisp-client)
  (let ((conn (sse-protocol:open-sse url :last-event-id last-event-id)))
    (unwind-protect
         (mapcar #'event-plist
                 (sse-protocol:collect-sse-events conn
                                                  :include-empty include-empty))
      (sse-protocol:close-sse conn))))

(defun %json-key (key)
  (intern (string-upcase (etypecase key
                           (string key)
                           (symbol (symbol-name key))
                           (character (string key))))
          :keyword))

(defun %json-to-plist (value)
  (cond
    ((hash-table-p value)
     (let ((acc '()))
       (maphash (lambda (k v)
                  (setf acc (list* (%json-key k) (%json-to-plist v) acc)))
                value)
       acc))
    ((and (vectorp value) (not (stringp value)))
     (map 'list #'%json-to-plist value))
    ((eq value :null) nil)
    (t value)))

(defun parse-json-line (line)
  (when (and line (plusp (length (string-trim '(#\space) line))))
    (%json-to-plist (json-protocol:decode line))))

(defun foreign-client-events (kind url)
  (let* ((cmd (client-command kind url))
         (out (uiop:run-program cmd
                                :output :string
                                :error-output :string
                                :ignore-error-status t)))
    (loop for line in (uiop:split-string out :separator '(#\newline))
          for parsed = (ignore-errors (parse-json-line line))
          when parsed
            collect parsed)))

(defun events-match-p (got expected)
  "Compare event plists. Missing keys in EXPECTED are ignored."
  (and (= (length got) (length expected))
       (every (lambda (g e)
                (flet ((chk (k)
                         (or (not (member k e))
                             (equal (getf g k) (getf e k)))))
                  (and (chk :data) (chk :id) (chk :event))))
              got expected)))

(defun expected-for (route-key)
  (ecase route-key
    (:basic '((:data "hello" :event "message")))
    (:multiline '((:data "one
two" :event "message")))
    (:typed '((:data "ok" :event "ping")))
    (:id '((:data "x" :id "7" :event "message")))
    (:utf8 '((:data "αβγ ✔" :event "message")))
    (:comment '((:data "after" :event "message")))
    (:last-first '((:data "first" :id "1" :event "message")))
    (:last-resume '((:data "resume" :id "2" :event "message")))))

(defun route-url (base route-key &optional (last nil last-p))
  (declare (ignore last last-p))
  (let ((path (if (eq route-key :last-resume)
                  "/last"
                  (if (eq route-key :last-first)
                      "/last"
                      (second (find route-key +routes+ :key #'first))))))
    (concatenate 'string base path)))
