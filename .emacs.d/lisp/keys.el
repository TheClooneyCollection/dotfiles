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
  (defun open-init-file ()
    "Open the main init file."
    (interactive)
    (find-file (expand-file-name "init.el" user-emacs-directory)))

  (defun reload-emacs-config ()
    "Reload the Emacs config from init.el."
    (interactive)
    (load-file (expand-file-name "init.el" user-emacs-directory)))

  (general-create-definer leader-key
    :states '(normal visual motion emacs)
    :keymaps 'override
    :prefix "SPC")

  ;; Keep the initial leader map small and close to your Spacemacs muscle memory.
  (leader-key
    "SPC" '(execute-extended-command :which-key "M-x")
    "0" '(delete-other-windows :which-key "delete other windows")
    "1" '(delete-window :which-key "delete window")
    "b" '(:ignore t :which-key "buffers")
    "bb" '(consult-buffer :which-key "switch buffer")
    "f" '(:ignore t :which-key "files")
    "fe" '(:ignore t :which-key "emacs")
    "fed" '(open-init-file :which-key "open init.el")
    "fer" '(reload-emacs-config :which-key "reload config")
    "ff" '(find-file :which-key "find file")
    "fs" '(save-buffer :which-key "save file")
    "g" '(:ignore t :which-key "git")
    "gg" '(open-magit-status-cleanly :which-key "magit")
    "q" '(:ignore t :which-key "quit")
    "qq" '(save-buffers-kill-terminal :which-key "quit emacs")
    "w" '(:ignore t :which-key "windows")
    "wd" '(delete-window :which-key "delete window")
    "wo" '(delete-other-windows :which-key "delete other windows")
    "ww" '(other-window :which-key "other window")))

(provide 'keys)

;;; keys.el ends here
