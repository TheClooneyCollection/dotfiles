; evil.el
; VIM! I mean EVIL!

(use-package evil
  :init (setq evil-want-C-u-scroll t) ; Enable <c-u> to scroll up
  :config (evil-mode))

(use-package evil-escape
  :diminish evil-escape-mode
  :init (setq-default evil-escape-key-sequence "kj")
  :config (evil-escape-mode))

(provide 'evil)
