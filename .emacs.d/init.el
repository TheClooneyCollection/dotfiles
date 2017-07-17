(require 'package)
(setq package-enable-at-startup nil
      load-prefer-newer t)
(add-to-list 'package-archives '("melpa" . "http://melpa.org/packages/"))

(package-initialize)

(defun load-directory (dir)
  (let ((load-it (lambda (f)
                   (load-file (concat (file-name-as-directory dir) f)))
                 ))
    (mapc load-it (directory-files dir nil "\\.el$"))))
(load-directory "~/.emacs.d/lisp/")

(setq custom-file "~/.emacs.d/custom.el")
(setq-default indent-tabs-mode nil) ; Don't indent with tabs.
(setq gc-cons-threshold 50000000) ; Do GC when every 50MB are allocated
