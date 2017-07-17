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
