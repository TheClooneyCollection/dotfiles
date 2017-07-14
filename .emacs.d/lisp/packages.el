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

; Languages

(use-package swift-mode
  :mode "\\.swift\\'"
  :interpreter "swift")

; Functionality

(use-package guide-key
  :diminish guide-key-mode
  :config
  (setq guide-key/guide-key-sequence t) ; Enable guide-key for all key sequences
  (guide-key-mode)) ; Enable guide-key-mode
(use-package async
  :init (setq async-bytecomp-allowed-packages '(all))
  :config
    (dired-async-mode 1) ; Enable aysnc commands for directory editor, also for helm
    (async-bytecomp-package-mode 1) ; See https://github.com/jwiegley/emacs-async for explanation
)

(use-package general
  :init
    (setq general-default-keymaps 'evil-normal-state-map
          general-default-prefix "<SPC>")
  :config
    (general-define-key "r" 'dot-emacs/reload)
)

(use-package magit
  :commands magit-status)

; Helm
(use-package helm
  :bind ("M-x" . helm-M-x)
  :init
    ; ; Enable fuzzy matching globally
    ; (setq helm-mode-fuzzy-match t
    ;       helm-completion-in-region-fuzzy-match t)
    (general-define-key "<SPC>" 'helm-M-x)
  :config
    (helm-mode))

(use-package helm-ls-git
  :config
    (general-define-key "f" 'helm-ls-git-ls))


(provide 'packages)
