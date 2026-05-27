;;; funcs.el --- Interactive helpers used by leader keybindings -*- lexical-binding: t; -*-

;; Keep `keys.el' focused on the leader map. Anything `interactive' that a
;; binding calls lives here so the key file stays a flat lookup table.

(require 'cl-lib)

;;; Scratch / zen ------------------------------------------------------------

(defun switch-to-project-scratch-buffer ()
  "Switch to a simple project scratch buffer."
  (interactive)
  (let* ((project-root (when-let ((project (project-current nil)))
                         (expand-file-name (project-root project))))
         (project-name (if project-root
                           (file-name-nondirectory (directory-file-name project-root))
                         "scratch"))
         (buffer-name (format "*scratch: %s*" project-name)))
    (switch-to-buffer (get-buffer-create buffer-name))
    (unless (derived-mode-p 'org-mode)
      (org-mode))
    (when (= (point-min) (point-max))
      (insert (format "#+TITLE: %s\n\n" project-name)))))

(defun zen ()
  "Switch to a project scratch buffer and focus it."
  (interactive)
  (switch-to-project-scratch-buffer)
  (delete-other-windows))

;;; Config editing -----------------------------------------------------------

(defun open-init-file ()
  "Open the main init file."
  (interactive)
  (find-file (expand-file-name "init.el" user-emacs-directory)))

(defun reload-emacs-config ()
  "Reload the Emacs config from init.el."
  (interactive)
  ;; `init.el` mostly uses `require`, so unload local modules first to force
  ;; their code and keybindings to be evaluated again on reload.
  (dolist (feature '(keys
                     git-setup
                     evil-setup
                     languages
                     docs
                     completion
                     modeline
                     theme
                     ui
                     core
                     funcs
                     bootstrap))
    (when (featurep feature)
      (unload-feature feature t)))
  (load-file (expand-file-name "init.el" user-emacs-directory)))

(defun helm-M-x-fuzzy-matching ()
  "Run `helm-M-x' with Spacemacs-style flex matching enabled."
  (interactive)
  (let ((completion-styles completion-styles))
    (add-to-list 'completion-styles 'flex t)
    (call-interactively #'helm-M-x)))

(defun spacemacs-switch-to-buffer ()
  "Switch buffers with `helm-mini', matching the older Spacemacs Helm UX."
  (interactive)
  (require 'helm-buffers)
  (call-interactively #'helm-mini))

;;; macOS pasteboard ---------------------------------------------------------

(defun copy-to-pasteboard ()
  "Copy the active region, or the current line, to the macOS pasteboard."
  (interactive)
  (let ((start (if (use-region-p) (region-beginning) (line-beginning-position)))
        (end (if (use-region-p) (region-end) (line-beginning-position 2))))
    (call-process-region start end "pbcopy")
    (deactivate-mark)
    (message "Copied to pasteboard")))

(defun paste-from-pasteboard ()
  "Paste text from the macOS pasteboard at point."
  (interactive)
  (insert-for-yank (shell-command-to-string "pbpaste")))

;;; File finding -------------------------------------------------------------

(defun nc/helm-find-all-files ()
  "Fuzzy-find any file using fzf + helm.
Searches from the project root when in a project, otherwise from HOME."
  (interactive)
  (let* ((root (or (when-let ((proj (project-current nil)))
                     (expand-file-name (project-root proj)))
                   (expand-file-name "~")))
         (default-directory root))
    (helm :sources (helm-build-async-source (format "fzf %s" root)
                     :candidates-process
                     (lambda ()
                       (start-process "helm-fzf" helm-buffer
                                      "fzf" "--no-sort" "-f" helm-pattern))
                     :filter-one-by-one #'identity
                     :requires-pattern 1
                     :action #'helm-find-file-or-marked
                     :candidate-number-limit 9999)
          :buffer "*helm-fzf*"
          :prompt "Find file: ")))

;;; Project search ----------------------------------------------------------

;; Direct port of `spacemacs/helm-files-do-rg' from
;; ~/.emacs.d.spacemacs-2026-05-22/layers/+completion/helm/funcs.el.
(defun helm-files-do-rg (&optional dir)
  "Search in files with `rg' via `helm-do-ag'."
  (interactive)
  (helm-do-ag dir))

;; Port of `spacemacs//helm-do-ag-region-or-symbol' from the same file. We
;; drop the `rxt-quote-pcre' wrapping (pcre2el isn't pulled in here) and
;; only seed when there's an active region, matching the UX you described.
(defun search-project-at-point ()
  "Helm-ag rg search of the current project. Mirrors Spacemacs `SPC *'.
With an active region, seed the prompt with that text. Otherwise leave the
prompt empty so you can just type."
  (interactive)
  (require 'helm-ag)
  (let* ((dir (or (when-let ((project (project-current nil)))
                    (expand-file-name (project-root project)))
                  default-directory))
         (region-text (when (use-region-p)
                        (prog1 (buffer-substring-no-properties
                                (region-beginning) (region-end))
                          (deactivate-mark)))))
    (if region-text
        (cl-letf* ((orig (symbol-function 'thing-at-point))
                   ((symbol-value 'helm-ag-insert-at-point) 'symbol)
                   ((symbol-function 'thing-at-point)
                    (lambda (_thing &optional _no-props) region-text)))
          (helm-files-do-rg dir))
      (helm-files-do-rg dir))))

(provide 'funcs)

;;; funcs.el ends here
