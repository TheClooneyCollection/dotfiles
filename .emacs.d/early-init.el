;;; early-init.el --- Early startup settings -*- lexical-binding: t; -*-

;; Keep package activation under the control of init.el.
(setq package-enable-at-startup nil)

;; Make the vendored Spacemacs theme available before the first frame is drawn.
(let ((theme-directory
       (expand-file-name "lisp/vendor/spacemacs-theme" user-emacs-directory)))
  (add-to-list 'load-path theme-directory)
  (add-to-list 'custom-theme-load-path theme-directory)
  (when (locate-file "spacemacs-dark-theme.el" custom-theme-load-path)
    (load-theme 'spacemacs-dark t)))

;; Suppress the default GNU Emacs startup echo before the first frame appears.
(setq inhibit-startup-screen t
      inhibit-startup-message t
      inhibit-startup-echo-area-message user-login-name
      initial-scratch-message nil)

;; Some terminal startups still try to print the GNU info hint in the echo
;; area; override it explicitly so startup stays quiet.
(defun display-startup-echo-area-message ()
  nil)

;; Relax GC during startup to reduce early pauses.
;; `most-positive-fixnum` effectively gets GC out of the way during init.
(setq gc-cons-threshold most-positive-fixnum)
(setq gc-cons-percentage 0.6) ; 60% heap growth allowed before GC runs.

;; Disable heavy GUI chrome before the first frame is drawn.
(menu-bar-mode -1)
(tool-bar-mode -1)
(scroll-bar-mode -1)

;;; early-init.el ends here
