; Set up packages.el
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

; Bootstrap org
; All configuration for org is in the configuration.org file
(use-package org
  :mode ("\\.org\\'" . org-mode))

; Load all other configurations in the configuration.org file

(defun dot-emacs/load-configuration-dot-org ()
  (interactive)
  (save-some-buffers)
  (org-babel-load-file "~/.emacs.d/configuration.org"))

(dot-emacs/load-configuration-dot-org)
