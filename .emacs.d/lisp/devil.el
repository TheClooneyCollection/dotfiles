; VIM! I mean EVIL!

(use-package evil
  :init
    (setq evil-want-C-u-scroll t) ; Enable <c-u> to scroll up
  :config
    (define-key evil-normal-state-map ";" #'evil-ex)
    (define-key evil-normal-state-map ":" #'evil-repeat-find-char)
    (evil-mode))

(use-package evil-escape
  :diminish evil-escape-mode
  :init (setq-default evil-escape-key-sequence "kj")
  :config
  (evil-escape-mode))

(use-package evil-magit
  :after evil
  :config (evil-magit-init))
