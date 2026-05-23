;;; evil-setup.el --- Evil configuration -*- lexical-binding: t; -*-

;; Undo-fu provides a simple undo backend that works well with Evil.
(use-package undo-fu)

;; Evil supplies Vim-style modal editing.
(use-package evil
  :init
  (setq evil-want-keybinding nil
        evil-want-integration t
        evil-want-C-u-scroll t
        evil-want-C-i-jump nil
        evil-undo-system 'undo-fu
        evil-kill-on-visual-paste nil
        evil-ex-substitute-case t
        evil-ex-search-case nil)
  :config
  ;; Swap ":" and ";" when inserting text to match the old Spacemacs habit.
  (global-set-key ":" (lambda () (interactive) (insert ";")))
  (global-set-key ";" (lambda () (interactive) (insert ":")))

  ;; Save and close the current buffer for :wq in normal editing sessions.
  (defun save-and-kill-current-buffer ()
    (interactive)
    (save-buffer)
    (kill-current-buffer))

  ;; Finish commit/edit sessions cleanly when with-editor is active.
  (defun finish-editor-session ()
    (interactive)
    (save-buffer)
    (when (fboundp 'with-editor-finish)
      (with-editor-finish)))

  (evil-mode 1)
  (define-key evil-normal-state-map (kbd "TAB") #'evil-toggle-fold)
  ;; In modal states, ";" should open Ex and ":" should repeat the last find.
  (define-key evil-normal-state-map ";" #'evil-ex)
  (define-key evil-normal-state-map ":" #'evil-repeat-find-char)
  (define-key evil-motion-state-map ":" #'evil-repeat-find-char)
  (define-key evil-visual-state-map ":" #'evil-repeat-find-char)
  (evil-ex-define-cmd "q[uit]" #'evil-quit)
  (evil-ex-define-cmd "wq" #'save-and-kill-current-buffer)
  (evil-ex-define-cmd "wqa" #'save-some-buffers))

;; Restore the old `f' jump motion from the archived Spacemacs setup.
(use-package avy
  :after evil
  :config
  (setq avy-keys '(?a ?e ?i ?o ?u ?h ?t ?d ?s ?y))
  (let ((goto-char #'evil-avy-goto-char-timer))
    (define-key evil-normal-state-map "f" goto-char)
    (define-key evil-motion-state-map "f" goto-char))
  (define-key evil-visual-state-map "f" #'evil-avy-goto-char-in-line)
  (define-key evil-operator-state-map "f" #'evil-avy-goto-char-in-line))

;; Evil-collection teaches many built-in and package modes to respect Evil keys.
(use-package evil-collection
  :after evil
  :config
  (evil-collection-init))

;; Rebind :wq inside transient editor buffers such as Git commit messages.
(with-eval-after-load 'with-editor
  (add-hook 'with-editor-mode-hook
            (lambda ()
              (evil-ex-define-cmd "wq" #'finish-editor-session))))

(provide 'evil-setup)

;;; evil-setup.el ends here
