(setq gc-cons-threshold 100000000) ; Do GC when every 100MB are allocated

(setq-default indent-tabs-mode nil) ; Don't indent with tabs.
(setq custom-file "~/.emacs.d/custom.el")

; UI
(setq
  ring-bell-function #'ignore
  inhibit-startup-screen t ; Skip the startup screen
  initial-scratch-message "; Hello there!\n; Happy hacking!\n")

(fset 'yes-or-no-p #'y-or-n-p) ; Change yes/no -> y/n
(fset 'display-startup-echo-area-message #'ignore) ; No more startup message

(menu-bar-mode -1) ; Hide menu bar at top

; Load packages
(require 'package)
(setq package-enable-at-startup nil
      load-prefer-newer t)
(add-to-list 'package-archives '("melpa" . "http://melpa.org/packages/"))

(package-initialize)

; Bootstrap use-package

(unless (package-installed-p 'use-package)
  (package-refresh-contents)
  (package-install 'use-package))

(eval-when-compile
  (require 'use-package))

; Always install all the packages
(setq use-package-always-ensure t
      use-package-verbose t)

; Use :diminish with use-package
; to remove/abbreviate a mode indicator in the modeline
(require 'diminish)
; Use :bind-key with use-package
; to bind keys easily in a tidy way
(require 'bind-key)

; Asynchronous compilation

(use-package async
  :init (setq async-bytecomp-allowed-packages '(all))
  :config
    (dired-async-mode 1) ; Enable aysnc commands for directory editor, also for helm
    (async-bytecomp-package-mode 1) ; See https://github.com/jwiegley/emacs-async for explanation
)

; UI
(use-package whitespace ; Built-in
  :diminish (whitespace-mode global-whitespace-mode)
  :init (setq whitespace-style '(face tabs trailing empty tab-mark))
  :config (global-whitespace-mode))

(use-package powerline
  :config (powerline-default-theme))

(use-package airline-themes
  :after powerline
  :init (setq powerline-utf-8-separator-left        #xe0b0
              powerline-utf-8-separator-right       #xe0b2
              airline-utf-glyph-separator-left      #xe0b0
              airline-utf-glyph-separator-right     #xe0b2
              airline-utf-glyph-subseparator-left   #xe0b1
              airline-utf-glyph-subseparator-right  #xe0b3
              airline-utf-glyph-branch              #xe0a0
              airline-utf-glyph-readonly            #xe0a2
              airline-utf-glyph-linenumber          #xe0a1)
  :config (load-theme 'airline-light t))

(use-package zenburn-theme)

; Packages

; Keys

(use-package guide-key
  :diminish guide-key-mode
  :config
  (setq guide-key/guide-key-sequence t) ; Enable guide-key for all key sequences
  (guide-key-mode)) ; Enable guide-key-mode

(use-package general
  :init
  (setq general-default-keymaps '(
                                 evil-normal-state-map
                                 evil-visual-state-map
                                 evil-operator-state-map
                                 )
        general-default-prefix "<SPC>")
  :config

  (defun dot-emacs/reload ()
    (interactive)
    (load-file (concat user-emacs-directory "init.el")))

  (general-define-key "r" 'eval-buffer)

  (defun dot-emacs/copy-to-clipboard ()
    (interactive)
    (if (region-active-p)
        (progn
          (shell-command-on-region (region-beginning) (region-end) "pbcopy")
          (message "Yanked region to clipboard!")
          (deactivate-mark))
      (message "No region active; can't yank to clipboard!")))

  (general-define-key "y" 'dot-emacs/copy-to-clipboard)

  (defun dot-emacs/paste-from-clipboard ()
    (interactive)
      (insert (shell-command-to-string "pbpaste")))

  (general-define-key "p" 'dot-emacs/paste-from-clipboard)

  (defun paste-from-clipboard ()
    (interactive)
      (insert (shell-command-to-string "pbpaste")))
  (general-define-key "w" 'save-buffer)
  (general-define-key "0" 'delete-other-windows)
  (general-define-key "qq" 'save-buffers-kill-terminal)

  (general-define-key "hk" 'describe-key)
  (general-define-key "hf" 'describe-function)
  (general-define-key "hv" 'describe-variable)

  (defun dot-emacs/edit (filename)
    (find-file (concat user-emacs-directory filename)))

  (defun dot-emacs/edit-packages ()
    (interactive)
    (dot-emacs/edit "init.el"))

  (general-define-key "ee" 'dot-emacs/edit-packages)
)

(use-package time ; Built-in
  :diminish display-time-mode
  :init
  (general-define-key "it" 'display-time-world)
  (setq display-time-world-list '(
                                  ("Australia/Sydney" "Sydney")
                                  ("Asia/Chongqing" "Chongqing")
                                  ("PST8PDT" "San Francisco")
                                  ("Asia/Calcutta" "Bangalore")
                                  ("Australia/Melbourne" "Melbourne")
                                  ("Europe/London" "London")
                                  ("Europe/Paris" "Paris")
                                  ("Asia/Tokyo" "Tokyo")
                                  ("America/Los_Angeles" "Los Angeles")
                                  ("America/New_York" "New York")
                                  ))
  :config (display-time-mode))

(use-package evil
  :init
  (setq evil-want-C-u-scroll t ; Enable <c-u> to scroll up
        evil-want-C-i-jump nil ; Disable C-i & TAB for jumps forward (conflicting with evil-org's TAB)
        evil-regexp-search t ; Enable regexp search
        )
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
  (setq avy-keys '(?a ?e ?i ?o ?u ?h ?t ?d ?s))
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

(use-package org
  :mode ("\\.org\\'" . org-mode))

(use-package evil-org
  :after (org evil)
  :mode ("\\.org\\'" . org-mode)
  :config
  (add-hook 'org-mode-hook 'evil-org-mode)
  (add-hook 'evil-org-mode-hook
            (lambda ()
              (evil-org-set-key-theme '(navigation insert textobjects rsi additional shift todo heading)))))

(use-package flx)

(use-package projectile
  :init
  (setq projectile-enable-caching t
        projectile-switch-project-action 'helm-ls-git-ls
        projectile-mode-line '(:eval (format " [%s]" (projectile-project-name))))

  :config
  (projectile-discover-projects-in-directory "~/work")
  (projectile-discover-projects-in-directory "~/proj")
  (projectile-global-mode))

(use-package magit
  :diminish auto-revert-mode
  :commands magit-status
  :init
  (general-define-key "s" 'magit-status))

(use-package ggtags
  :commands (ggtags-update-tags))

(use-package auto-complete
  :diminish auto-complete-mode
  :config
  (ac-config-default))

(use-package smartparens
  :diminish smartparens-mode
  :config
  (require 'smartparens-config)
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

; Helm
(use-package helm
  :demand t
  :diminish helm-mode
  :bind ("M-x" . helm-M-x)
  :init
  (setq helm-mode-fuzzy-match t
        helm-completion-in-region-fuzzy-match t
        helm-M-x-fuzzy-match t
        helm-buffers-fuzzy-match t
        helm-candidate-number-limit 20)
  (general-define-key "<SPC>" 'helm-M-x)
  (general-define-key "b" 'helm-buffers-list)
  :config
  (helm-mode))

(use-package helm-flx
  :after (helm flx)
  :init
  (setq helm-flx-for-helm-find-files t
        helm-flx-for-helm-locate t)
  :config (helm-flx-mode))

(use-package helm-projectile
  :after (helm helm-flx)
  :commands (helm-projectile-switch-project)
  :config
  (general-define-key "c" 'helm-projectile-switch-project))

(use-package helm-ls-git
  :commands helm-ls-git-ls
  :init
  ;(setq helm-ls-git-fuzzy-match t)
  (general-define-key "f" 'helm-ls-git-ls))

(use-package helm-gtags
  :commands (helm-gtags-select
             helm-gtags-find-rtag
             helm-gtags-parse-file)
  :bind (:map evil-normal-state-map
              ("t" . helm-gtags-select)
              ("r" . helm-gtags-find-rtag))
  :init
  (setq helm-gtags-fuzzy-match t)
  (general-define-key "t" 'helm-gtags-parse-file))
