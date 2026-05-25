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
  :config
  ;; Evil reserves `Z` as a prefix for commands like `ZZ` and `ZQ`, which
  ;; prevents Magit's single-key worktree popup from firing in status buffers.
  ;; Restore Magit's native binding locally so `Z` opens `magit-worktree`.
  (with-eval-after-load 'evil
    (evil-define-key 'normal magit-mode-map (kbd "Z") #'magit-worktree))
  :commands (magit-status))

;; Magit's transient panels default to `C-g` for quitting, but the old
;; Magit-Popup/Spacemacs muscle memory used `q`.  Re-enable that globally for
;; transients and add single-key Escape to back out of any Magit panel.
(with-eval-after-load 'transient
  (transient-bind-q-to-quit)
  (keymap-set transient-base-map "<escape>" #'transient-quit-one)
  (keymap-set transient-edit-map "<escape>" #'transient-quit-one)
  (keymap-set transient-sticky-map "<escape>" #'transient-quit-seq))

(add-hook 'emacs-startup-hook #'open-magit-status-on-startup)

(provide 'git-setup)

;;; git-setup.el ends here
