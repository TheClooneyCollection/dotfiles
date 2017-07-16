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
(setq-default indent-tabs-mode nil) ; Don't indent with tabs.
(setq gc-cons-threshold 50000000) ; Do GC when every 50MB are allocated
