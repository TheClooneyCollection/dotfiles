; Bootstrap use-package

(unless (package-installed-p 'use-package)
  (package-refresh-contents)
  (package-install 'use-package))

(eval-when-compile
  (require 'use-package))

; Always install all the packages
(setq use-package-always-ensure t)

; Use :diminish with use-package
; to remove/abbreviate a mode indicator in the modeline
(require 'diminish)
; Use :bind-key with use-package
; to bind keys easily in a tidy way
(require 'bind-key)

; Packages

; Keys

(use-package guide-key
  :diminish guide-key-mode
  :config
  (setq guide-key/guide-key-sequence t) ; Enable guide-key for all key sequences
  (guide-key-mode)) ; Enable guide-key-mode

(use-package general
  :init
    (setq general-default-keymaps 'evil-normal-state-map
          general-default-prefix "<SPC>")
  :config
    (general-define-key "r" 'dot-emacs/reload)
    (general-define-key "w" 'save-buffer)
    (general-define-key "qq" 'save-buffers-kill-terminal)

    (general-define-key "hf" 'describe-function)
    (general-define-key "hk" 'describe-key)
    (general-define-key "hv" 'describe-variable)
)

; Languages

(use-package swift-mode
  :mode "\\.swift\\'"
  :interpreter "swift")

; Functionality

(use-package magit
  :commands magit-status
  :init (general-define-key "s" 'magit-status))

(use-package auto-complete
  :diminish auto-complete-mode
  :config
    (ac-config-default))

(use-package smartparens
  :config
  (show-smartparens-global-mode)
  (smartparens-global-mode))

(use-package ace-jump-mode
  :commands (evil-ace-jump-line-mode evil-ace-jump-char-mode)
  :init
  (setq ace-jump-mode-move-keys (number-sequence ?a ?z))
  (general-define-key :prefix nil "f" 'evil-ace-jump-char-mode)
  (general-define-key "l" 'evil-ace-jump-line-mode)
)

(use-package async
  :init (setq async-bytecomp-allowed-packages '(all))
  :config
    (dired-async-mode 1) ; Enable aysnc commands for directory editor, also for helm
    (async-bytecomp-package-mode 1) ; See https://github.com/jwiegley/emacs-async for explanation
)

; Helm
(use-package helm
  :bind ("M-x" . helm-M-x)
  :init
    ; ; Enable fuzzy matching globally
    ; (setq helm-mode-fuzzy-match t
    ;       helm-completion-in-region-fuzzy-match t)
    (general-define-key "<SPC>" 'helm-M-x)
    (general-define-key "b" 'helm-buffers-list)
  :config
    (helm-mode))

(use-package helm-ls-git
  :commands helm-ls-git-ls
  :init
    (general-define-key "f" 'helm-ls-git-ls))


(provide 'packages)
