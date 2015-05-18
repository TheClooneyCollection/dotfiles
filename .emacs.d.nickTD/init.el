;;;;; configurations

;; reduce the frequency of garbage collection by making it happen on
;; each 50MB of allocated data (the default is on every 0.76MB)
(setq gc-cons-threshold 50000000)



;;; user interfaces

(set-frame-font "Source Code Pro-14")

(when (fboundp 'tool-bar-mode) (tool-bar-mode -1))
(when (fboundp 'scroll-bar-mode) (scroll-bar-mode -1))

;; No blinking and beeping
(blink-cursor-mode -1)
(setq ring-bell-function #'ignore
      ;; no startup screen, no scratch message
      inhibit-startup-screen t
      initial-scratch-message "Hello there!\n")
(fset 'yes-or-no-p #'y-or-n-p) ;; short Yes/No questions.
;; Opt out from the startup message in the echo area by simply disabling this
;; ridiculously bizarre thing entirely.
(fset 'display-startup-echo-area-message #'ignore)

;;; default modes

(setq-default indent-tabs-mode nil)

(electric-pair-mode)
(show-paren-mode)
(global-hl-line-mode) ;; highlight current line

;;; custom functions

(defun dot-emacs/location ()
  (concat user-emacs-directory "init.el"))

(defun dot-emacs/find-dotfile ()
  (interactive)
  (find-file-existing (dot-emacs/location)))

;;; package management

;; Please don't load outdated byte code
(setq load-prefer-newer t)

(require 'package)
(setq package-enable-at-startup nil)
(add-to-list 'package-archives '("melpa" . "http://melpa.org/packages/"))

(package-initialize)

;; Bootstrap `use-package'
(unless (package-installed-p 'use-package)
  (package-refresh-contents)
  (package-install 'use-package))

(eval-when-compile
  (require 'use-package))

(require 'diminish)                ;; if you use :diminish
(require 'bind-key)                ;; if you use any :bind variant


;;; packages

;; misc

(use-package magit
  :ensure t
  :init
  (setq magit-last-seen-setup-instructions "1.4.0"))

;; ui

(use-package solarized-theme
  :ensure t
  :config (load-theme 'solarized-light 'no-confirm))

(use-package zenburn-theme
  :disabled t
  :ensure t)

(use-package nyan-mode
  :ensure t
  :config
  (nyan-mode))

;; project

(use-package projectile
  :ensure t
  :diminish projectile-mode
  :config
  (projectile-global-mode))

(use-package helm-projectile
  :ensure t
  :config
  (setq projectile-completion-system 'helm)
  (helm-projectile-on))

;; behaviour

(use-package guide-key
  :ensure t
  :diminish guide-key-mode
  :config
  (setq guide-key/guide-key-sequence t)
  (guide-key-mode))

(use-package helm
  :ensure t
  :diminish helm-mode
  :config
  (require 'helm-config)
  (helm-mode)
  (helm-autoresize-mode))

;; evil

(use-package evil
  :ensure t
  :init (setq evil-want-C-u-scroll t)
  :config
  ;;; ace-jump-mode
  (setq ace-jump-mode-scope 'window)

  ; (use-package evil-rebellion
  ;   :ensure t)

  ;;; key mappings
  (define-key evil-motion-state-map (kbd "f") #'evil-ace-jump-char-mode)
  (define-key evil-motion-state-map (kbd "t") #'evil-ace-jump-char-to-mode)
  ;;; TODO: find out why f and t in operator mode is so slow
  ;;; `df<char>' or `ct<char>' is so slow compared to `vf<char' or `vt<char>'
  ;;; TODO: find out why visual state map is mixed up with operator state
  (define-key evil-visual-state-map (kbd "f") #'evil-ace-jump-char-mode)
  (define-key evil-visual-state-map (kbd "t") #'evil-ace-jump-char-to-mode)

  (use-package evil-escape
    :ensure t
    :diminish evil-escape-mode
    :config
    (setq-default evil-escape-key-sequence "kj")
    (evil-escape-mode))
  (use-package evil-leader
    :ensure t
    :config
    (use-package evil-easymotion
      :ensure t)
    (global-evil-leader-mode)
    (evil-leader/set-leader "<SPC>")
    (evil-leader/set-key
      "." 'eval-buffer
      ; eval-region
      "=" 'text-scale-increase
      "-" 'text-scale-decrease
      "1" 'delete-other-windows
      "b" 'switch-to-buffer
      "c" 'evil-ace-jump-char-mode
      "j" (evilem-create 'next-line
             nil nil ((temporary-goal-column (current-column))
             (line-move-visual nil)))
      "ev" 'dot-emacs/find-dotfile
      "f" 'find-file
      "l" 'evil-ace-jump-line-mode
      ; projectile
      "t" 'evil-ace-jump-char-to-mode
      "w" 'save-buffer
      "q" 'save-buffers-kill-emacs
      ))
  (evil-mode))

;; auto-completion, flycheck

(use-package company                    ; Graphical (auto-)completion
  :ensure t
  :diminish company-mode
  :config
  ;; Use Company for completion
  (bind-key [remap completion-at-point] #'company-complete company-mode-map)

  (setq company-tooltip-align-annotations t
        ;; Easy navigation to candidates with M-<n>
        company-show-numbers t)
  (global-company-mode))

(use-package company-quickhelp          ; Documentation popups for Company
  :ensure t
  :config
  (company-quickhelp-mode))

(use-package flycheck                   ; On-the-fly syntax checking
  :ensure t
  :config
                                        ;   (setq flycheck-completion-system 'ido)

  ;; Use italic face for checker name
  (set-face-attribute 'flycheck-error-list-checker-name nil :inherit 'italic)
  (global-flycheck-mode)

  (use-package flycheck-pos-tip           ; Show Flycheck messages in popups
    :ensure t
    :config
    (eval-after-load 'flycheck
      '(custom-set-variables
        '(flycheck-display-errors-function #'flycheck-pos-tip-error-messages)))))