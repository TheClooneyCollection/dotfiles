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
  (general-create-definer leader-key
    :states '(normal visual motion emacs)
    :keymaps 'override
    :prefix "SPC")

  ;; Keep the initial leader map small and close to your Spacemacs muscle memory.
  (leader-key
    "" '(execute-extended-command :which-key "M-x")
    "b" '(:ignore t :which-key "buffers")
    "bb" '(consult-buffer :which-key "switch buffer")
    "f" '(:ignore t :which-key "files")
    "ff" '(find-file :which-key "find file")
    "fs" '(save-buffer :which-key "save file")
    "g" '(:ignore t :which-key "git")
    "gg" '(magit-status :which-key "magit")
    "q" '(:ignore t :which-key "quit")
    "qq" '(save-buffers-kill-terminal :which-key "quit emacs")))

(provide 'keys)

;;; keys.el ends here
