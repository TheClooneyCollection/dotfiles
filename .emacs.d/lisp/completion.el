;;; completion.el --- Minibuffer completion stack -*- lexical-binding: t; -*-

;; Helm powers the older Spacemacs-style pickers you liked for files/search.
(use-package helm
  :init
  (setq helm-M-x-fuzzy-match t
        helm-buffers-fuzzy-matching t
        helm-recentf-fuzzy-match t
        helm-split-window-inside-p t
        helm-move-to-line-cycle-in-source t
        helm-ff-search-library-in-sexp t
        helm-scroll-amount 8
        helm-echo-input-in-header-line t)
  :config
  (helm-mode 1))

;; Helm-flx improves fuzzy matching inside Helm sources.
(use-package helm-flx
  :after helm
  :init
  (setq helm-flx-for-helm-find-files t
        helm-flx-for-helm-locate t)
  :config
  (helm-flx-mode 1))

;; Helm-ls-git provides the repo-file picker behind the old SPC f f workflow.
(use-package helm-ls-git
  :after helm
  :commands (helm-ls-git)
  :config
  ;; The current upstream package defaults to a multi-source Git dashboard.
  ;; Restrict it to tracked files so SPC f f keeps the older Spacemacs feel.
  (setq helm-ls-git-default-sources '(helm-source-ls-git)))

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
