;;; languages.el --- Language and review helpers -*- lexical-binding: t; -*-

;; Diff-hl shows Git changes in the fringe while reviewing edits in a buffer.
(use-package diff-hl
  :hook ((prog-mode . diff-hl-mode)
         (text-mode . diff-hl-mode)
         (dired-mode . diff-hl-dired-mode))
  :config
  (diff-hl-flydiff-mode 1))

;; Hl-todo makes TODO/FIXME/NOTE comments easy to spot during review.
(use-package hl-todo
  :hook ((prog-mode . hl-todo-mode)
         (text-mode . hl-todo-mode)))

;; Rainbow delimiters make nested code structures easier to scan quickly.
(use-package rainbow-delimiters
  :hook (prog-mode . rainbow-delimiters-mode))

;; Swift mode gives proper highlighting and indentation for Swift files.
(use-package swift-mode
  :mode "\\.swift\\'")

;; Web mode covers templated HTML, especially Nunjucks files.
(use-package web-mode
  :mode (("\\.njk\\'" . web-mode)
         ("\\.html?\\'" . web-mode))
  :init
  ;; Keep indentation predictable across markup, CSS, and inline JS.
  (setq web-mode-markup-indent-offset 2
        web-mode-code-indent-offset 2
        web-mode-css-indent-offset 2))

;; Json mode gives a cleaner dedicated major mode for JSON files.
(use-package json-mode
  :mode "\\.json\\'")

;; Use the built-in JavaScript mode for .js files and keep indentation simple.
(setq js-indent-level 2)
(add-to-list 'auto-mode-alist '("\\.js\\'" . js-mode))

(provide 'languages)

;;; languages.el ends here
