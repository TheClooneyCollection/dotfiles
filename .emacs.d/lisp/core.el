;;; core.el --- Core behavior and defaults -*- lexical-binding: t; -*-

;; Keep the editor quiet and predictable by default.
(setq inhibit-startup-screen t
      inhibit-startup-message t
      inhibit-startup-echo-area-message user-login-name
      initial-scratch-message nil
      ring-bell-function #'ignore
      use-dialog-box nil
      visible-bell nil
      make-backup-files nil
      auto-save-default nil
      create-lockfiles nil
      confirm-kill-processes nil
      sentence-end-double-space nil
      tab-always-indent 'complete)

(fset 'yes-or-no-p #'y-or-n-p)

;; Persist useful session state without extra prompts.
(save-place-mode 1)
(savehist-mode 1)
(recentf-mode 1)
(global-auto-revert-mode 1)

(setq recentf-max-saved-items 200 ; Keep a long enough file history to be useful.
      auto-revert-verbose nil)

;; Save dirty buffers when Emacs loses focus.
(add-hook 'focus-out-hook #'save-some-buffers)

;; Default to spaces and a moderate text width.
(setq-default indent-tabs-mode nil
              tab-width 2
              fill-column 80) ; Conventional readable line width.

;; Treat UTF-8 as the default everywhere.
(prefer-coding-system 'utf-8-unix)

(provide 'core)

;;; core.el ends here
