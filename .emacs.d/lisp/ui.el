;;; ui.el --- UI defaults -*- lexical-binding: t; -*-

;; Trim visual distractions while keeping basic editing feedback.
(blink-cursor-mode -1)
(column-number-mode 1)
(global-display-line-numbers-mode 1)
(show-paren-mode 1)

(setq display-line-numbers-type 'relative)

;; Turn off line numbers in terminal-like buffers where they get in the way.
(dolist (hook '(term-mode-hook
                eshell-mode-hook
                shell-mode-hook
                vterm-mode-hook))
  (add-hook hook (lambda () (display-line-numbers-mode 0))))

(provide 'ui)

;;; ui.el ends here
