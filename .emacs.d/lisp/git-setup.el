;;; git-setup.el --- Git tools -*- lexical-binding: t; -*-

(defun open-magit-status-cleanly ()
  "Open Magit and clean up an empty scratch buffer if it launched from there."
  (interactive)
  (let ((scratch-buffer (current-buffer))
        (from-empty-scratch
         (and (equal (buffer-name) "*scratch*")
              (= (point-min) (point-max)))))
    (call-interactively #'magit-status)
    (when from-empty-scratch
      (kill-buffer scratch-buffer))))

;; Magit is the main Git interface we want to preserve from Spacemacs.
(use-package magit
  :commands (magit-status))

(provide 'git-setup)

;;; git-setup.el ends here
