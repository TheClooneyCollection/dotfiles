;;; init.el --- Main entry point for Emacs config -*- lexical-binding: t; -*-

;; Restore more reasonable GC settings after startup.
(setq gc-cons-threshold (* 64 1024 1024) ; 64 MiB.
      gc-cons-percentage 0.1)            ; 10% heap growth before GC runs.

;; Keep Customize output out of handwritten config.
(setq custom-file (expand-file-name "custom.el" user-emacs-directory))
(when (file-exists-p custom-file)
  (load custom-file nil 'nomessage))

;; Load small local modules from ~/.emacs.d/lisp.
(add-to-list 'load-path (expand-file-name "lisp" user-emacs-directory))

(require 'package)

;; Use the main community package archives.
(setq package-archives
      '(("gnu" . "https://elpa.gnu.org/packages/")
        ("nongnu" . "https://elpa.nongnu.org/nongnu/")
        ("melpa" . "https://melpa.org/packages/")))

(package-initialize)

;; Bootstrap use-package so package declarations stay concise.
(unless (package-installed-p 'use-package)
  (package-refresh-contents)
  (package-install 'use-package))

(require 'use-package)

(eval-when-compile
  (require 'use-package))

(setq use-package-always-ensure t)

;; Load the config in broad responsibility order.
(require 'core)
(require 'ui)
(require 'completion)
(require 'evil-setup)
(require 'git-setup)
(require 'keys)

;;; init.el ends here
