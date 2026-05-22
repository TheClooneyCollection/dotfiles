;;; keys.el --- Leader keybindings -*- lexical-binding: t; -*-

;; Which-key shows available key sequences after a short delay.
(use-package which-key
  :init
  (setq which-key-idle-delay 0.4 ; Fast enough to feel immediate without flicker.
        which-key-sort-order #'which-key-key-order-alpha)
  :config
  (which-key-mode 1))

;; General makes it easy to define a Spacemacs-style leader key layout.
(use-package general
  :after evil
  :config
  (defun switch-to-project-scratch-buffer ()
    "Switch to a simple project scratch buffer."
    (interactive)
    (let* ((project-root (when-let ((project (project-current nil)))
                           (expand-file-name (project-root project))))
           (project-name (if project-root
                             (file-name-nondirectory (directory-file-name project-root))
                           "scratch"))
           (buffer-name (format "*scratch: %s*" project-name)))
      (switch-to-buffer (get-buffer-create buffer-name))
      (unless (derived-mode-p 'org-mode)
        (org-mode))
      (when (= (point-min) (point-max))
        (insert (format "#+TITLE: %s\n\n" project-name)))))

  (defun zen ()
    "Switch to a project scratch buffer and focus it."
    (interactive)
    (switch-to-project-scratch-buffer)
    (delete-other-windows))

  (defun open-init-file ()
    "Open the main init file."
    (interactive)
    (find-file (expand-file-name "init.el" user-emacs-directory)))

  (defun reload-emacs-config ()
    "Reload the Emacs config from init.el."
    (interactive)
    ;; `init.el` mostly uses `require`, so unload local modules first to force
    ;; their code and keybindings to be evaluated again on reload.
    (dolist (feature '(keys
                       git-setup
                       evil-setup
                       languages
                       docs
                       completion
                       modeline
                       theme
                       ui
                       core
                       bootstrap))
      (when (featurep feature)
        (unload-feature feature t)))
    (load-file (expand-file-name "init.el" user-emacs-directory)))

  ;; Talk to the macOS pasteboard directly so Emacs and other apps share text.
  (defun copy-to-pasteboard ()
    "Copy the active region, or the current line, to the macOS pasteboard."
    (interactive)
    (let ((start (if (use-region-p) (region-beginning) (line-beginning-position)))
          (end (if (use-region-p) (region-end) (line-beginning-position 2))))
      (call-process-region start end "pbcopy")
      (deactivate-mark)
      (message "Copied to pasteboard")))

  (defun paste-from-pasteboard ()
    "Paste text from the macOS pasteboard at point."
    (interactive)
    (insert-for-yank (shell-command-to-string "pbpaste")))

  (general-create-definer leader-key
    :states '(normal visual motion emacs)
    :keymaps 'override
    :prefix "SPC")

  ;; Keep the initial leader map small and close to your Spacemacs muscle memory.
  (leader-key
    "SPC" '(execute-extended-command :which-key "M-x")
    "0" '(delete-other-windows :which-key "delete other windows")
    "1" '(delete-window :which-key "delete window")
    "9" '(zen :which-key "zen")
    "b" '(:ignore t :which-key "buffers")
    "bb" '(consult-buffer :which-key "switch buffer")
    "f" '(:ignore t :which-key "files")
    "fe" '(:ignore t :which-key "emacs")
    "fed" '(open-init-file :which-key "open init.el")
    "fer" '(reload-emacs-config :which-key "reload config")
    "fF" '(helm-find-files :which-key "find file anywhere")
    "ff" '(helm-ls-git :which-key "find git file")
    "fs" '(save-buffer :which-key "save file")
    "g" '(:ignore t :which-key "git")
    "gg" '(open-magit-status-cleanly :which-key "magit")
    "p" '(paste-from-pasteboard :which-key "paste from pasteboard")
    "q" '(:ignore t :which-key "quit")
    "qq" '(save-buffers-kill-terminal :which-key "quit emacs")
    "w" '(:ignore t :which-key "windows")
    "wd" '(delete-window :which-key "delete window")
    "wo" '(delete-other-windows :which-key "delete other windows")
    "ww" '(other-window :which-key "other window")
    "y" '(copy-to-pasteboard :which-key "copy to pasteboard")))

(provide 'keys)

;;; keys.el ends here
