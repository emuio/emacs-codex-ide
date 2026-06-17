;;; codex-ide-images-tests.el --- Tests for codex-ide image input -*- lexical-binding: t; -*-

;;; Commentary:

;; Focused tests for local image and clipboard image attachment helpers.

;;; Code:

(require 'cl-lib)
(require 'ert)
(require 'codex-ide-test-fixtures)
(require 'codex-ide)

(defun codex-ide-images-test--display-image-file (display)
  "Return DISPLAY's image file, or nil."
  (and (consp display)
       (eq (car display) 'image)
       (plist-get (cdr display) :file)))

(defun codex-ide-images-test--string-has-image-display-p (string path)
  "Return non-nil when STRING has an image display for PATH."
  (catch 'found
    (dotimes (index (length string))
      (when (equal (codex-ide-images-test--display-image-file
                    (get-text-property index 'display string))
                   path)
        (throw 'found t)))
    nil))

(defun codex-ide-images-test--buffer-has-image-display-p (path)
  "Return non-nil when the current buffer has an image display for PATH."
  (catch 'found
    (let ((pos (point-min)))
      (while (< pos (point-max))
        (when (equal (codex-ide-images-test--display-image-file
                      (get-text-property pos 'display))
                     path)
          (throw 'found t))
        (setq pos (or (next-single-property-change pos 'display nil (point-max))
                      (point-max)))))
    nil))

(ert-deftest codex-ide-submit-image-attaches-local-image-without-submitting ()
  (let* ((project-dir (codex-ide-test--make-temp-project))
         (image-path (codex-ide-test--make-project-file
                      project-dir
                      "screenshot.png"
                      "fake-png")))
    (codex-ide-test-with-fixture project-dir
      (codex-ide-test-with-fake-processes
        (let ((session (codex-ide--create-process-session)))
          (with-current-buffer (codex-ide-session-buffer session)
            (codex-ide--insert-input-prompt session nil)
            (cl-letf (((symbol-function 'codex-ide--session-for-current-project)
                       (lambda () session))
                      ((symbol-function 'codex-ide--ensure-session-for-current-project)
                       (lambda () session))
                      ((symbol-function 'codex-ide--submit-prompt)
                       (lambda (&rest _)
                         (ert-fail "Attaching an image should not submit"))))
              (codex-ide-submit-image image-path))
            (should (equal (codex-ide--pending-local-images session)
                           (list image-path)))
            (should (equal (codex-ide--current-input session)
                           ""))
            (should (string-match-p
                     "\\[Image #1\\]"
                     (overlay-get
                      (codex-ide--session-metadata-get
                       session
                       :pending-local-images-overlay)
                      'before-string)))))))))

(ert-deftest codex-ide-pending-local-images-display-includes-thumbnail ()
  (let* ((project-dir (codex-ide-test--make-temp-project))
         (image-path (codex-ide-test--make-project-file
                      project-dir
                      "screenshot.png"
                      "fake-png")))
    (codex-ide-test-with-fixture project-dir
      (codex-ide-test-with-fake-processes
        (let ((session (codex-ide--create-process-session)))
          (with-current-buffer (codex-ide-session-buffer session)
            (codex-ide--insert-input-prompt session nil)
            (cl-letf (((symbol-function 'create-image)
                       (lambda (file &rest _args)
                         `(image :file ,file))))
              (codex-ide--add-pending-local-image session image-path))
            (let ((display (overlay-get
                            (codex-ide--session-metadata-get
                             session
                             :pending-local-images-overlay)
                            'before-string)))
              (should (string-match-p "\\[Image #1\\]" display))
              (should (codex-ide-images-test--string-has-image-display-p
                       display
                       image-path)))))))))

(ert-deftest codex-ide-submit-clipboard-image-attaches-image-without-submitting ()
  (let ((project-dir (codex-ide-test--make-temp-project)))
    (codex-ide-test-with-fixture project-dir
      (codex-ide-test-with-fake-processes
        (let ((session (codex-ide--create-process-session)))
          (with-current-buffer (codex-ide-session-buffer session)
            (codex-ide--insert-input-prompt session nil)
            (cl-letf (((symbol-function 'codex-ide--save-clipboard-image)
                       (lambda () "/tmp/clipboard.png"))
                      ((symbol-function 'codex-ide--session-for-current-project)
                       (lambda () session))
                      ((symbol-function 'codex-ide--ensure-session-for-current-project)
                       (lambda () session))
                      ((symbol-function 'codex-ide--submit-prompt)
                       (lambda (&rest _)
                         (ert-fail "Attaching an image should not submit"))))
              (codex-ide-submit-clipboard-image))
            (should (equal (codex-ide--pending-local-images session)
                           '("/tmp/clipboard.png")))
            (should (string-match-p
                     "\\[Image #1\\]"
                     (overlay-get
                      (codex-ide--session-metadata-get
                       session
                       :pending-local-images-overlay)
                      'before-string)))))))))

(ert-deftest codex-ide-delete-backward-removes-last-attached-image ()
  (let* ((project-dir (codex-ide-test--make-temp-project))
         (first-image (codex-ide-test--make-project-file
                       project-dir
                       "first.png"
                       "fake-png"))
         (second-image (codex-ide-test--make-project-file
                        project-dir
                        "second.png"
                        "fake-png")))
    (codex-ide-test-with-fixture project-dir
      (codex-ide-test-with-fake-processes
        (let ((session (codex-ide--create-process-session)))
          (with-current-buffer (codex-ide-session-buffer session)
            (codex-ide--insert-input-prompt session nil)
            (codex-ide--add-pending-local-image session first-image)
            (codex-ide--add-pending-local-image session second-image)
            (goto-char (codex-ide--input-end-position session))
            (codex-ide-delete-backward-or-remove-attached-image)
            (should (equal (codex-ide--pending-local-images session)
                           (list first-image)))
            (should (equal (codex-ide--current-input session)
                           ""))
            (let ((display (overlay-get
                            (codex-ide--session-metadata-get
                             session
                             :pending-local-images-overlay)
                            'before-string)))
              (should (string-match-p "\\[Image #1\\]" display))
              (should-not (string-match-p "\\[Image #2\\]" display)))))))))

(ert-deftest codex-ide-delete-backward-removes-image-token-at-input-end ()
  (let* ((project-dir (codex-ide-test--make-temp-project))
         (image-path (codex-ide-test--make-project-file
                      project-dir
                      "screenshot.png"
                      "fake-png")))
    (codex-ide-test-with-fixture project-dir
      (codex-ide-test-with-fake-processes
        (let ((session (codex-ide--create-process-session)))
          (with-current-buffer (codex-ide-session-buffer session)
            (codex-ide--insert-input-prompt session "abc")
            (codex-ide--add-pending-local-image session image-path)
            (goto-char (codex-ide--input-end-position session))
            (codex-ide-delete-backward-or-remove-attached-image)
            (should (equal (codex-ide--current-input session)
                           "abc"))
            (should-not (codex-ide--pending-local-images session))))))))

(ert-deftest codex-ide-delete-backward-inside-text-keeps-attached-image ()
  (let* ((project-dir (codex-ide-test--make-temp-project))
         (image-path (codex-ide-test--make-project-file
                      project-dir
                      "screenshot.png"
                      "fake-png")))
    (codex-ide-test-with-fixture project-dir
      (codex-ide-test-with-fake-processes
        (let ((session (codex-ide--create-process-session)))
          (with-current-buffer (codex-ide-session-buffer session)
            (codex-ide--insert-input-prompt session "abc")
            (codex-ide--add-pending-local-image session image-path)
            (goto-char (1- (codex-ide--input-end-position session)))
            (codex-ide-delete-backward-or-remove-attached-image)
            (should (equal (codex-ide--current-input session)
                           "ac"))
            (should (equal (codex-ide--pending-local-images session)
                           (list image-path)))))))))

(ert-deftest codex-ide-delete-backward-after-text-following-image-keeps-image ()
  (let* ((project-dir (codex-ide-test--make-temp-project))
         (image-path (codex-ide-test--make-project-file
                      project-dir
                      "screenshot.png"
                      "fake-png")))
    (codex-ide-test-with-fixture project-dir
      (codex-ide-test-with-fake-processes
        (let ((session (codex-ide--create-process-session)))
          (with-current-buffer (codex-ide-session-buffer session)
            (codex-ide--insert-input-prompt session "aaa")
            (codex-ide--add-pending-local-image session image-path)
            (insert "bbb")
            (should (< (overlay-start
                        (codex-ide--session-metadata-get
                         session
                         :pending-local-images-overlay))
                       (codex-ide--input-end-position session)))
            (goto-char (codex-ide--input-end-position session))
            (codex-ide-delete-backward-or-remove-attached-image)
            (should (equal (codex-ide--current-input session)
                           "aaabb"))
            (should (equal (codex-ide--pending-local-images session)
                           (list image-path)))))))))

(ert-deftest codex-ide-delete-backward-falls-back-to-text-deletion ()
  (let ((project-dir (codex-ide-test--make-temp-project)))
    (codex-ide-test-with-fixture project-dir
      (codex-ide-test-with-fake-processes
        (let ((session (codex-ide--create-process-session)))
          (with-current-buffer (codex-ide-session-buffer session)
            (codex-ide--insert-input-prompt session "abc")
            (goto-char (codex-ide--input-end-position session))
            (codex-ide-delete-backward-or-remove-attached-image)
            (should (equal (codex-ide--current-input session)
                           "ab"))))))))

(provide 'codex-ide-images-tests)

;;; codex-ide-images-tests.el ends here
