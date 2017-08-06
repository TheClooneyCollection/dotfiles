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
(use-package org
  :mode ("\\.org\\'" . org-mode)
  :init
  (setq org-ellipsis "⤵"
        org-src-tab-acts-natively t)
  :config
  (dolist (item '(("el" "#+BEGIN_SRC emacs-lisp\n?\n#+END_SRC")
                  ("re" "#+END_SRC\n?\n#+BEGIN_SRC emacs-lisp")))
    (add-to-list 'org-structure-template-alist item))
  (add-hook 'org-mode-hook (lambda () (org-indent-mode t)))
  (eval-after-load 'org-indent '(diminish 'org-indent-mode)))

; Load all other configurations in the configuration.org file

(org-babel-load-file "~/.emacs.d/configuration.org")
