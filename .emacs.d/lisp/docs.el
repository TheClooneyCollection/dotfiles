;;; docs.el --- Documentation editing support -*- lexical-binding: t; -*-

;; Markdown mode gives headings, code fences, and lists proper highlighting.
(use-package markdown-mode
  :mode (("README\\.md\\'" . gfm-mode)
         ("\\.md\\'" . markdown-mode)
         ("\\.markdown\\'" . markdown-mode))
  ;; Keep long prose readable while editing docs and notes.
  :hook ((markdown-mode . visual-line-mode)
         (gfm-mode . visual-line-mode)))

(provide 'docs)

;;; docs.el ends here
