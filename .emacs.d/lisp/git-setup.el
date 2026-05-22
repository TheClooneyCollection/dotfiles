;;; git-setup.el --- Git tools -*- lexical-binding: t; -*-

(defun open-magit-status-cleanly ()
  "Open Magit and hide an empty scratch buffer if it launched from there."
  (interactive)
  (let ((start-directory default-directory)
        (scratch-buffer (current-buffer))
        (from-empty-scratch
         (and (equal (buffer-name) "*scratch*")
              (= (point-min) (point-max)))))
    (magit-status-setup-buffer start-directory)
    (delete-other-windows)
    (when (and from-empty-scratch
               (buffer-live-p scratch-buffer))
      ;; Keep scratch available as the previous buffer so quitting Magit has a
      ;; sane place to return, but bury it so it stays out of the way.
      (bury-buffer scratch-buffer))))

(defun open-magit-status-on-startup ()
  "Open Magit once startup has finished drawing the initial frame."
  (unless (or noninteractive
              (minibufferp (current-buffer)))
    (open-magit-status-cleanly)))

;; Magit is the main Git interface we want to preserve from Spacemacs.
(use-package magit
  :init
  ;; Make Magit status feel like a primary view instead of a side panel.
  (setq magit-display-buffer-function
        #'magit-display-buffer-same-window-except-diff-v1)
  :commands (magit-status))

(add-hook 'emacs-startup-hook #'open-magit-status-on-startup)

(provide 'git-setup)

;;; git-setup.el ends here
