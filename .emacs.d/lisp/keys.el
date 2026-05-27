;;; keys.el --- Leader keybindings -*- lexical-binding: t; -*-

;; This file is the leader-map lookup table only. Any `interactive' helper a
;; binding calls lives in `funcs.el'.

(require 'funcs)

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
    "SPC" '(helm-M-x-fuzzy-matching :which-key "M-x")
    "*" '(search-project-at-point :which-key "search project w/ symbol")
    "0" '(delete-other-windows :which-key "delete other windows")
    "1" '(delete-window :which-key "delete window")
    "9" '(zen :which-key "zen")
    "b" '(:ignore t :which-key "buffers")
    "bb" '(spacemacs-switch-to-buffer :which-key "switch buffer")
    "d" '(evil-scroll-down :which-key "scroll down")
    "f" '(:ignore t :which-key "files")
    "fe" '(:ignore t :which-key "emacs")
    "fed" '(open-init-file :which-key "open init.el")
    "fer" '(reload-emacs-config :which-key "reload config")
    "fF" '(nc/helm-find-all-files :which-key "find file anywhere (fzf)")
    "ff" '(helm-ls-git :which-key "find git file")
    "fs" '(save-buffer :which-key "save file")
    "g" '(:ignore t :which-key "git")
    "gg" '(open-magit-status-cleanly :which-key "magit")
    "p" '(paste-from-pasteboard :which-key "paste from pasteboard")
    "q" '(:ignore t :which-key "quit")
    "qQ" '(kill-emacs :which-key "kill emacs")
    "qq" '(save-buffers-kill-terminal :which-key "quit emacs")
    "qr" '(restart-emacs :which-key "restart emacs")
    "u" '(evil-scroll-up :which-key "scroll up")
    "w" '(:ignore t :which-key "windows")
    "wd" '(delete-window :which-key "delete window")
    "wo" '(delete-other-windows :which-key "delete other windows")
    "ww" '(other-window :which-key "other window")
    "y" '(copy-to-pasteboard :which-key "copy to pasteboard")))

(provide 'keys)

;;; keys.el ends here
