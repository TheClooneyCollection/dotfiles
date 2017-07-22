(setq gc-cons-threshold 100000000) ; Do GC when every 100MB are allocated

(setq-default indent-tabs-mode nil) ; Don't indent with tabs.
(setq custom-file "~/.emacs.d/custom.el")

; UI
(setq
  ring-bell-function #'ignore
  inhibit-startup-screen t ; Skip the startup screen
  initial-scratch-message "Hello there!\nStart happy hacking!\n")

(fset 'yes-or-no-p #'y-or-n-p) ; Change yes/no -> y/n
(fset 'display-startup-echo-area-message #'ignore) ; No more startup message

(menu-bar-mode -1) ; Hide menu bar at top

; Load packages
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
