; Packages

; Keys

(use-package guide-key
  :diminish guide-key-mode
  :config
  (setq guide-key/guide-key-sequence t) ; Enable guide-key for all key sequences
  (guide-key-mode)) ; Enable guide-key-mode

(use-package general
  :init
  (setq general-default-keymaps (list
                                 'evil-normal-state-map
                                 'evil-visual-state-map
                                 'evil-operator-state-map
                                 )
        general-default-prefix "<SPC>")
  :config

    (defun dot-emacs/reload ()
      (interactive)
      (load-file (concat user-emacs-directory "init.el")))

    (general-define-key "r" 'dot-emacs/reload)
    (general-define-key "w" 'save-buffer)
    (general-define-key "0" 'delete-other-windows)
    (general-define-key "qq" 'save-buffers-kill-terminal)

    (general-define-key "hk" 'describe-key)

    (defun dot-emacs/edit (filename)
      (find-file (concat (concat user-emacs-directory "lisp/") filename)))

    (defun dot-emacs/edit-packages ()
      (interactive)
      (dot-emacs/edit "packages.el"))

    (general-define-key "ee" 'dot-emacs/edit-packages)

    (defun dot-emacs/edit-ui ()
      (interactive)
      (dot-emacs/edit "ui.el"))

    (general-define-key "eu" 'dot-emacs/edit-ui)
)

(use-package evil-easymotion
  :after evil
  :config
  ; Evil-easymotion's line movements work perfectly with evil.
  (general-define-key "j" (evilem-create 'evil-next-line))
  (general-define-key "k" (evilem-create 'evil-previous-line))
)

; Avy's line movements do not work with evil too well
; For example, when in visual line selection mode (V), avy does not work at all;
; and when it does work in visual selection mode (v), it selects the line before selection.
(use-package avy
  :commands (avy-goto-char-2 avy-goto-line-above avy-goto-line-below)
  :bind (
        :map evil-normal-state-map
        ("f" . avy-goto-char-2)
        :map evil-visual-state-map
        ("f" . avy-goto-char-2)
        :map evil-operator-state-map
        ("f" . avy-goto-char-2))
  :init
  (setq avy-background t)
  (setq avy-keys (number-sequence ?a ?z))
  )

; Languages

(use-package swift-mode
  :mode "\\.swift\\'"
  :interpreter "swift"
  :config

  (general-define-key :prefix nil
                      :keymaps 'swift-mode-map
                      :states '(insert emacs)
                      ";" '(lambda () (interactive) (insert ":"))
                      ":" '(lambda () (interactive) (insert ";")))

  ; The following two lines are kept here for comparison reasons.
  ; Seems much easier to use define-key.

  ;(define-key swift-mode-map (kbd ";") '(lambda () (interactive) (insert ":")))
  ;(define-key swift-mode-map (kbd ":") '(lambda () (interactive) (insert ";")))
)

(use-package ruby-mode ; Built-in
  :mode ("\\.rb\\'" "\\Brewfile\\'"))

(use-package fish-mode
  :mode "\\.fish\\'")

; Functionality

(use-package flx)

(use-package projectile
  :init
  (setq projectile-enable-caching t
        projectile-switch-project-action 'counsel-git)

  :config
  (projectile-discover-projects-in-directory "~/work")
  (projectile-discover-projects-in-directory "~/proj")
  (projectile-global-mode))

(use-package magit
  :commands magit-status
  :init (general-define-key "s" 'magit-status))

(use-package ggtags
  :commands (ggtags-update-tags))

(use-package auto-complete
  :diminish auto-complete-mode
  :config
    (ac-config-default))

(use-package smartparens
  :config
  (show-smartparens-global-mode)
  (smartparens-global-mode))

(use-package slack
  :commands (slack-start)
  :init
  (setq slack-buffer-emojify t) ;; if you want to enable emoji, default nil
  (setq slack-prefer-current-team t))

(use-package alert
  :commands (alert)
  :init
  (setq alert-default-style 'notifier))
