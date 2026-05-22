;;; bootstrap.el --- First-boot package bootstrap UI -*- lexical-binding: t; -*-

;; Keep the first package install visible and explicit, similar in spirit to
;; the old Spacemacs startup buffer, but with a much smaller implementation.

(defconst bootstrap-packages
  '(use-package
    markdown-mode
    diff-hl
    hl-todo
    rainbow-delimiters
    swift-mode
    web-mode
    json-mode
    yaml-mode
    helm
    helm-flx
    helm-ls-git
    vertico
    orderless
    marginalia
    consult
    undo-fu
    evil
    evil-collection
    magit
    which-key
    general))

(defconst bootstrap-buffer-name "*bootstrap*")

(defvar bootstrap-log-marker nil)

(defun bootstrap-progress-bar (current total)
  "Return a simple text progress bar for CURRENT out of TOTAL."
  (let* ((width 30)
         (filled (if (zerop total) 0
                   (floor (* width (/ (float current) total)))))
         (empty (max 0 (- width filled))))
    (format "[%s%s] %d/%d"
            (make-string filled ?=)
            (make-string empty ?-)
            current
            total)))

(defun bootstrap-show-buffer ()
  "Display the bootstrap buffer as the only visible window."
  (let ((buffer (get-buffer-create bootstrap-buffer-name)))
    (with-current-buffer buffer
      (setq-local cursor-type nil)
      (setq-local mode-line-format nil)
      (setq-local header-line-format nil)
      (setq-local inhibit-read-only t)
      (erase-buffer)
      (setq-local bootstrap-log-marker nil)
      (special-mode))
    (switch-to-buffer buffer)
    (delete-other-windows)
    buffer))

(defun bootstrap-update-header (current total title)
  "Render the bootstrap progress header with CURRENT, TOTAL, and TITLE."
  (let ((buffer (get-buffer-create bootstrap-buffer-name)))
    (with-current-buffer buffer
      (setq-local header-line-format
                  (format " %s  %s"
                          (bootstrap-progress-bar current total)
                          title))
      (force-mode-line-update))
    (redisplay t)))

(defun bootstrap-append-static-line (text)
  "Append TEXT to the fixed bootstrap intro section."
  (let ((buffer (get-buffer-create bootstrap-buffer-name)))
    (with-current-buffer buffer
      (let ((inhibit-read-only t))
        (goto-char (point-max))
        (insert text "\n")))
    (redisplay t)))

(defun bootstrap-start-log-section ()
  "Mark the start of the bootstrap log section."
  (let ((buffer (get-buffer-create bootstrap-buffer-name)))
    (with-current-buffer buffer
      (let ((inhibit-read-only t))
        (goto-char (point-max))
        (setq-local bootstrap-log-marker (copy-marker (point) nil)))))
  (redisplay t))

(defun bootstrap-append-line (text)
  "Append TEXT to the bootstrap log section."
  (let ((buffer (get-buffer-create bootstrap-buffer-name)))
    (with-current-buffer buffer
      (let ((inhibit-read-only t))
        (goto-char bootstrap-log-marker)
        (insert text "\n")))
    (redisplay t)))

(defun bootstrap-finish-buffer ()
  "Dismiss the bootstrap buffer after startup work completes."
  (let ((buffer (get-buffer bootstrap-buffer-name)))
    (when (buffer-live-p buffer)
      (when (eq (current-buffer) buffer)
        (switch-to-buffer "*scratch*"))
      (kill-buffer buffer))))

(defun ensure-bootstrap-packages-installed ()
  "Install missing packages in a visible bootstrap buffer.

Return non-nil when any packages were installed."
  (let ((missing-packages '()))
    (dolist (package bootstrap-packages)
      (unless (package-installed-p package)
        (push package missing-packages)))
    (setq missing-packages (nreverse missing-packages))
    (when missing-packages
      (bootstrap-show-buffer)
      (bootstrap-update-header 0 (length missing-packages) "Preparing package installation...")
      (bootstrap-append-static-line "Bootstrapping Emacs packages...")
      (bootstrap-append-static-line "")
      (bootstrap-append-static-line "Refreshing package archives...")
      (bootstrap-append-static-line "")
      (bootstrap-start-log-section)
      (package-refresh-contents)
      (let ((package-count (length missing-packages))
            (installed-count 0))
        (dolist (package missing-packages)
          (setq installed-count (1+ installed-count))
          (bootstrap-update-header
           installed-count
           package-count
           (format "Installing %s..." package))
          (bootstrap-append-line
           (format "Installing packages %d/%d: %s"
                   installed-count
                   package-count
                   package))
          (package-install package))
        (bootstrap-update-header
         package-count
         package-count
         "Finished installing packages.")
        (bootstrap-append-line
         (format "Finished installing %d package%s."
                 package-count
                 (if (= package-count 1) "" "s")))
        (sit-for 0.75)
        (bootstrap-finish-buffer))
      t)))

(provide 'bootstrap)

;;; bootstrap.el ends here
