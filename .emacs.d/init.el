(require 'package)
(setq package-enable-at-startup nil
      load-prefer-newer t)
(add-to-list 'package-archives '("melpa" . "http://melpa.org/packages/"))

(package-initialize)

(defun l (f)
  (load-file (concat user-emacs-directory f)))

(l "packages.el")
(l "ui.el")
(l "evil.el")
