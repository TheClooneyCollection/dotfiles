(require 'package)
(setq package-enable-at-startup nil
      load-prefer-newer t)
(add-to-list 'package-archives '("melpa" . "http://melpa.org/packages/"))

(package-initialize)


(add-to-list 'load-path "~/.emacs.d/lisp/")

(require 'packages)
(require 'devil)
(require 'ui)

(setq custom-file "~/.emacs.d/custom.el")

(defun dot-emacs/reload ()
  (interactive)
  (load-file (concat user-emacs-directory "init.el")))
