;;; completion.el --- Minibuffer completion stack -*- lexical-binding: t; -*-

;; Vertico shows completion candidates in a compact vertical list.
(use-package vertico
  :init
  (vertico-mode 1))

;; Orderless allows flexible matching by space-separated fragments.
(use-package orderless
  :init
  (setq completion-styles '(orderless basic)
        completion-category-defaults nil
        completion-category-overrides '((file (styles basic partial-completion)))))

;; Marginalia adds lightweight annotations to completion candidates.
(use-package marginalia
  :init
  (marginalia-mode 1))

;; Consult provides useful minibuffer-driven commands for search and navigation.
(use-package consult
  :bind (("C-s" . consult-line)
         ("C-x b" . consult-buffer)
         ("M-y" . consult-yank-pop)))

(provide 'completion)

;;; completion.el ends here
