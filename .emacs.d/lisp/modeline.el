;;; modeline.el --- Lightweight custom mode line -*- lexical-binding: t; -*-

(defface mode-line-evil-normal-face
  '((t (:inherit mode-line :background "#8c6bb1" :foreground "#111111" :weight bold)))
  "Face for Evil normal state in the mode line.")

(defface mode-line-evil-insert-face
  '((t (:inherit mode-line :background "#7aa25c" :foreground "#111111" :weight bold)))
  "Face for Evil insert state in the mode line.")

(defface mode-line-evil-visual-face
  '((t (:inherit mode-line :background "#d08770" :foreground "#111111" :weight bold)))
  "Face for Evil visual state in the mode line.")

(defface mode-line-evil-emacs-face
  '((t (:inherit mode-line :background "#5e81ac" :foreground "#111111" :weight bold)))
  "Face for non-modal state in the mode line.")

(defface mode-line-buffer-face
  '((t (:inherit mode-line :foreground "#d087ff" :weight bold)))
  "Face for the current buffer segment.")

(defface mode-line-accent-face
  '((t (:inherit mode-line :foreground "#c0a7ff")))
  "Accent face for emphasized mode line metadata.")

(defface mode-line-subtle-face
  '((t (:inherit mode-line :foreground "#b0b0b0")))
  "Subtle face for lower-priority mode line metadata.")

(defun mode-line-evil-tag ()
  "Return the current Evil state tag."
  (if (bound-and-true-p evil-local-mode)
      (pcase evil-state
        ('normal (propertize " N " 'face 'mode-line-evil-normal-face))
        ('insert (propertize " I " 'face 'mode-line-evil-insert-face))
        ('visual (propertize " V " 'face 'mode-line-evil-visual-face))
        ('replace (propertize " R " 'face 'mode-line-evil-visual-face))
        (_ (propertize " E " 'face 'mode-line-evil-emacs-face)))
    (propertize " - " 'face 'mode-line-evil-emacs-face)))

(defun mode-line-buffer-segment ()
  "Return the current buffer name segment."
  (propertize (format-mode-line mode-line-buffer-identification)
              'face 'mode-line-buffer-face))

(defun mode-line-modified-segment ()
  "Return a marker when the current buffer has unsaved changes."
  (when (buffer-modified-p)
    (propertize " [+]" 'face 'mode-line-accent-face)))

(defun mode-line-major-mode-segment ()
  "Return the current major mode segment."
  (propertize (format-mode-line mode-name)
              'face 'mode-line-accent-face))

(defun mode-line-vc-segment ()
  "Return the current VC branch segment, if any."
  (when vc-mode
    (propertize (format " %s" (format-mode-line vc-mode))
                'face 'mode-line-subtle-face)))

(defun mode-line-right-segment ()
  "Return the right-aligned mode line metadata."
  (concat
   (propertize "%l:%c" 'face 'mode-line-subtle-face)
   (propertize "  " 'face 'mode-line-subtle-face)
   (mode-line-major-mode-segment)
   (or (mode-line-vc-segment) "")))

(defun mode-line-align-right ()
  "Return spacing that right-aligns the trailing mode line segment."
  (propertize
   " "
   'display
   `(space :align-to (- right
                        ,(string-width
                          (format-mode-line
                           '(:eval (mode-line-right-segment))))))))

;; Spacemacs used a custom modeline; keep ours lighter, but still segmented.
(setq-default mode-line-format
              '("%e"
                (:eval (mode-line-evil-tag))
                " "
                (:eval (mode-line-buffer-segment))
                (:eval (or (mode-line-modified-segment) ""))
                " "
                (:eval (mode-line-align-right))
                (:eval (mode-line-right-segment))
                " "))

;; Hide noisy minor-mode lighters such as WK and ElDoc from the modeline.
(setq minor-mode-alist nil)

(provide 'modeline)

;;; modeline.el ends here
