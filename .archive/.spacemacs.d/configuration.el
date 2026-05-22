;(spacemacs/recompile-elpa t) ; FORCE recompele all files with SPC u

(setenv "SHELL" "/opt/homebrew/bin/fish")
(setq shell-file-name "/opt/homebrew/bin/fish"
      explicit-shell-file-name shell-file-name)

(defun spacemacs/objective-c-file-p ()
  (and buffer-file-name
       (string= (file-name-extension buffer-file-name) "m")
       (re-search-forward "@interface"
                          magic-mode-regexp-match-limit t)))

(add-to-list 'magic-mode-alist
             (cons #'spacemacs/objective-c-file-p #'objc-mode))

(define-key evil-normal-state-map (kbd "TAB") #'evil-toggle-fold)

(global-set-key ":" #'(lambda () (interactive) (insert ";")))
(global-set-key ";" #'(lambda () (interactive) (insert ":")))

(let ((goto-char #'evil-avy-goto-char-timer))
  (define-key evil-normal-state-map "f" goto-char)
  (define-key evil-motion-state-map "f" goto-char))
(define-key evil-visual-state-map "f" #'evil-avy-goto-char-in-line)
(define-key evil-operator-state-map "f" #'evil-avy-goto-char-in-line)

(defun evil-avy-find-char-to-in-line ()
  "Somehow this magically makes `evil-avy-goto-char' works as `evil-find-char-to'"
  (interactive)
  (evil-avy-goto-char-in-line))

(define-key evil-visual-state-map "t" #'evil-avy-find-char-to-in-line)
(define-key evil-operator-state-map "t" #'evil-avy-find-char-to-in-line)

(spacemacs/set-leader-keys "0" #'delete-other-windows)
(spacemacs/set-leader-keys "7" #'async-shell-command)
(spacemacs/set-leader-keys "9" #'td/zen)

(spacemacs/set-leader-keys "bs" #'td/switch-to-project-s-scratch-buffer)

(spacemacs/set-leader-keys "fee" #'td/edit-configuration)

(evil-define-avy-motion avy-goto-line-above line)
(evil-define-avy-motion avy-goto-line-below line)

(spacemacs/set-leader-keys
  "jj" #'evil-avy-goto-line-below
  "jk" #'evil-avy-goto-line-above)

(spacemacs/set-leader-keys-for-major-mode 'slack-mode
  "u" #'slack-select-unread-rooms)

(spacemacs/set-leader-keys "on" #'(lambda ()
                                   (interactive)
                                   (find-file (org-file-path (format-time-string "%Y-%m-%d.org")))))

(spacemacs/set-leader-keys "oo" #'(lambda ()
                                   (interactive)
                                   (find-file (or (org-file-path-or-nil "work/notes.org")
                                                  org-default-notes-file))))

(spacemacs/set-leader-keys "ow" #'(lambda ()
                                    (interactive)
                                    (find-file (or (org-file-path-or-nil "work/work.org")
                                                   (org-file-path-or-nil "work.org")))))

(setq evil-ex-substitute-case t
      evil-ex-search-case nil)

(setq evil-kill-on-visual-paste nil)

(evil-ex-define-cmd "wq" #'(lambda ()
                             (interactive)
                             (save-buffer)
                             (kill-this-buffer)))
(evil-ex-define-cmd "q[uit]" 'evil-quit )
(evil-ex-define-cmd "wqa" 'evil-write-all )

(defun with-editor-evil-setup ()
  (evil-ex-define-cmd "wq" 'with-editor-finish))

(add-hook 'with-editor-mode-hook 'with-editor-evil-setup)
(add-hook 'org-source-mode-hook #'(lambda ()
                                    (interactive)
                                    (org-edit-src-exit)))

(spacemacs/toggle-auto-fill-mode-on)

(spacemacs/toggle-golden-ratio-on)

(spacemacs/toggle-centered-point-globally-on)

(defun td/yesterday ()
  "The time now, but yesterday"
  (let ((day (* (* 60 60) 24)))
    (time-subtract (current-time) day)))

(defun td/format-time-string (&optional time)
  "Format the time TIME, or now if omitted or nil,
into strings like \"Tuesday, 16 October 2018, Week 42\"."
  (format-time-string "%A, %d %B %Y, Week %W" time))

(defun td/edit (filename)
  (find-file (concat dotspacemacs-directory filename)))

(defun td/edit-configuration ()
  (interactive)
  (td/edit "configuration.org"))

(with-eval-after-load 'window-purpose-core
  (defun td/dedicate-window-purpose ()
    (interactive)
    (purpose-set-window-purpose-dedicated-p nil t)))

(setq split-width-threshold 0
      split-height-threshold nil)

(add-hook 'focus-out-hook #'(lambda () (save-some-buffers t)))

(defun td/swift/format-oneline-params-into-multiline (param-string)
  (format "\n%s\n" (replace-regexp-in-string ", *" ",\n" param-string)))

(print
 (td/swift/format-oneline-params-into-multiline "name: String,age: Int, sex: Sex")
 )
(print
 (td/swift/format-oneline-params-into-multiline "name: String, age: Int, sex: Sex")
 )
(print
 (td/swift/format-oneline-params-into-multiline "either: Either<Left, right>, name: String, age: Int")
 )

(defun td/swift/current-line-has-parentheses-p ()
  (interactive)
  (let ((line (thing-at-point 'line)))
    (td/swift//line-has-parentheses-p line)))

(defun td/swift//line-has-parentheses-p (line)
  (let* ((index-of-start (string-match-p "(" line))
         (index-of-end (string-match-p ")" line)))

     (and index-of-start
          index-of-end
          (< index-of-start index-of-end))))


(defun td/swift/split-oneline-params-into-multiline ()
  (interactive)
  (let* ((line (buffer-substring-no-properties (line-beginning-position) (line-end-position)))
         (has-starting-parenthesis (string-match-p "(" line))
         (has-ending-parenthesis (string-match-p ")" line)))

    (print has-starting-parenthesis)
    (print has-ending-parenthesis)
    )
  )

(print
 (td/swift//line-has-parentheses-p "()"))
(print
 (td/swift//line-has-parentheses-p "("))
(print
 (td/swift//line-has-parentheses-p ")"))
(print
 (td/swift//line-has-parentheses-p ")("))

(defun td/swift/visual/split-oneline-params-into-multiline ()
  (interactive)
  (let* ((visual-range (evil-visual-range))
         (start (evil-range-beginning visual-range))
         (end (evil-range-end visual-range))
         (param-string (buffer-substring start end))
         (multiline-param-string (td/swift/format-oneline-params-into-multiline param-string)))

    (delete-region start end)
    (insert multiline-param-string)
    (forward-line)

    (indent-region start (point))))

(defun td/swift/param-pairs-from (param-string)
  (let*
      ((string-pairs (split-string param-string ", ")))

    (mapcar #'(lambda (string) (split-string string ": ")) string-pairs))
)

(defun td/swift/lets-from (param-string)
  (let*
      ((param-pairs (td/swift/param-pairs-from param-string))
       (lets (mapcar #'(lambda (pair) (format "public let %s: %s" (car pair) (cadr pair))) param-pairs)))

    (string-join lets "\n")))

(defun td/swift/assigns-from (param-string)
  (let*
      ((param-pairs (td/swift/param-pairs-from param-string))
       (assigns (mapcar#'(lambda (pair) (format "self.%s = %s" (car pair) (car pair))) param-pairs)))

    (string-join assigns "\n")))

(print
 (td/swift/assigns-from "name: String, age: Int, sex: Sex")
 )

(print
 (td/swift/lets-from "name: String, age: Int, sex: Sex")
 )

(defun td/alert-notifier-notify (info)
  "Derived from the `alert-notifier-notify' function with added `-timeout' parameter"
  (if alert-notifier-command
      (let ((args
             (list "-title"   (alert-encode-string (plist-get info :title))
                   "-appIcon" (or (plist-get info :icon) alert-notifier-default-icon)
                   "-message" (alert-encode-string (plist-get info :message))
                   "-timeout" (number-to-string alert-fade-time))))
        ;; Adding the `timeout' param will cause `terminal-notifier' to block the process.
        ;; Thus we are calling `async-start-process' here.
        (apply #'async-start-process "emamcs-alert" alert-notifier-command nil args)
    (alert-message-notify info))))

(with-eval-after-load 'alert
  (alert-define-style 'td-notifier :title "Notify using terminal-notifier"
                      :notifier #'td/alert-notifier-notify))

(setq alert-default-style 'td-notifier)

(setq avy-keys '(?a ?e ?i ?o ?u ?h ?t ?d ?s ?y))

(global-company-mode)

(company-tng-configure-default)

(spacemacs|add-company-backends
  :backends (company-capf company-dabbrev)
  :modes text-mode)

(spacemacs|add-company-backends
  :backends (company-capf company-dabbrev)
  :modes swift-mode)

(spacemacs|add-company-backends
  :backends (company-capf company-dabbrev)
  :modes fish-mode)

;(setq company-flx-limit 20)

(add-hook 'emacs-lisp-mode-hook #'company-flx-mode)

(with-eval-after-load 'compile

(setq compilation-filter-hook nil)

(setq alert-fade-time 10)

(add-to-list 'compilation-error-regexp-alist-alist
             '(swift-fastlane "^\\(\\/.*?\\.swift\\):\\([0-9]+\\)" 1 2))
(add-to-list 'compilation-error-regexp-alist 'swift-fastlane)

(add-to-list 'compilation-finish-functions
            #'(lambda (buffer string)
               (alert string :title "Compilation finished")))

)

(add-hook 'csv-mode-hook #'csv-align-fields)

(when (memq window-system '(mac ns x))
  (exec-path-from-shell-initialize))

(when (daemonp)
  (exec-path-from-shell-initialize))

(setq flycheck-python-pycompile-executable "python3")
(use-package flycheck-mode
  :config
  (setq flycheck-python-pycompile-executable "python3"))

(setq helm-mode-fuzzy-match t
      helm-completion-in-region-fuzzy-match t
      helm-M-x-fuzzy-match t
      helm-buffers-fuzzy-matching t)

(setq helm-candidate-number-limit 20)

(with-eval-after-load 'helm
  (define-key helm-map (kbd "C-u") #'helm-previous-page)
  (define-key helm-map (kbd "C-d") #'helm-next-page))

(setq helm-grep-ag-command "rg --color=always --colors 'match:fg:black' --colors 'match:bg:yellow' --smart-case --no-heading --line-number %s %s %s")
(setq helm-grep-ag-pipe-cmd-switches '("--colors 'match:fg:black'" "--colors 'match:bg:yellow'"))

(spacemacs/set-leader-keys "ff" #'helm-ls-git)

(setq rcirc-server-alist '(("irc.freenode.net" :channels ("#emacs") :nick "nickTD")))

(spacemacs/set-leader-keys "gg" #'magit-status)

(setq magit-delta-delta-args
      (append magit-delta-delta-args '("--features" "magit-delta")))

(with-eval-after-load 'org

(require 'org-tempo)
(require 'ob-shell)

(setq org-ellipsis "⤵")

(setq org-M-RET-may-split-line nil)

(setq org-directory "~/Dropbox/data/org/")

(defun org-file-path (filename)
  (concat (file-name-as-directory org-directory) filename))

(defun org-file-path-or-nil (filename)
  "Return the absolute address of an org file, given its relative name."
  (let ((file-path (org-file-path filename)))
    (if (file-exists-p file-path)
        file-path nil)))

(setq org-default-notes-file (org-file-path "notes.org"))
(setq org-agenda-files (cl-remove-if #'null (list org-directory
                                                  (org-file-path-or-nil "work/"))))
(setq org-archive-location (format "%s::"
      (org-file-path "archive.org")))

(dolist (item '(("e" . "src emacs-lisp :results output")
                ("ex" . "example")
                ("s" . "src swift")
                ("f" . "src sh :results output")
                ("sh" . "src sh :results output")
                ("ss" . "src")
                ("r" . "src ruby :results output")
                ("p" . "src python :results output")))
  (add-to-list 'org-structure-template-alist item))

(add-hook 'org-mode-hook #'spacemacs/toggle-auto-fill-mode-on)

(setq org-babel-python-command "/opt/homebrew/bin/python3")

(add-to-list 'org-babel-shell-names "fish")
(org-babel-shell-initialize)

(setq org-confirm-babel-evaluate nil)

(defun org-babel-execute:swift (body params)
  "Execute a block of Swift code with org-babel."
  (message "executing Swift source code block")
  (ob-swift--eval body))

(defun ob-swift--eval (body)
  (with-temp-buffer
    (insert body)
    (shell-command-on-region (point-min) (point-max) "swift -" nil 't)
    (buffer-string)))

(provide 'ob-swift)

(org-babel-do-load-languages
 'org-babel-load-languages
 '(
   (swift . t)
   (python . t)
   (ruby . t)

   (shell . t)
   ))

)

(setq persp-nil-name "@home")

(defun td/switch-to-project-s-scratch-buffer ()
  (interactive)
  (let ((buffer-name (format "*scratch: %S*" (projectile-project-name))))
    (if-let (buffer (get-buffer buffer-name)) ; buffer exists
        (switch-to-buffer buffer)
      (progn                            ; buffer does not exist
        (switch-to-buffer (get-buffer-create buffer-name))
        (org-mode)
        (insert (format "\
#+TITLE %S

#+BEGIN_SRC swift

#+END_SRC

#+BEGIN_SRC emacs-lisp

#+END_SRC

#+BEGIN_SRC python :results output

#+END_SRC

#+BEGIN_SRC fish :results output

#+END_SRC
" (projectile-project-name)))))))

(defun td/zen ()
  (interactive)
  (progn
    (td/switch-to-project-s-scratch-buffer)
    (delete-other-windows)
    (td/dedicate-window-purpose)))

(setq projectile-enable-caching t)
(setq projectile-switch-project-action #'td/zen)

(setq projectile-tags-backend 'etags)

(projectile-discover-projects-in-directory "~/work")
(projectile-discover-projects-in-directory "~/proj")

(setq purpose-user-mode-purposes '((magit-mode . util)
                                   (slack-mode . util)))
(setq purpose-user-regexp-purposes '(
                                     ;("^*scratch: [\"a-zA-Z0-9]" . edit)
                                     ))

(with-eval-after-load 'purpose
  (purpose-compile-user-configuration))

(add-hook 'magit-mode-setup-hook #'td/dedicate-window-purpose)

(add-hook 'prog-mode-hook #'emr-initialize)

(use-package enh-ruby-mode)
   ;; :mode ("\\.rb\\'" "Brewfile" "Fastfile" "Appfile" "Scanfile" "Matchfile"))

(setq slack-prefer-current-team t
      slack-buffer-function #'switch-to-buffer)

(spacemacs|use-package-add-hook slack
  :post-config
  (progn
    ;; Turn off centered-point-mode in slack mode
    (add-hook 'slack-mode-hook #'(lambda () (centered-cursor-mode -1)))

    ;; Workaround for channels containing unsupported message format
    (defun sbw/slack-mode--catch-message-to-string-error (orig-fun &rest args)
      (condition-case nil
          (apply orig-fun args)
        (error "<error parsing message>\n")))

    (advice-add 'slack-message-to-string :around #'sbw/slack-mode--catch-message-to-string-error)

    (let* ((auth-info (car (auth-source-search :max 1
                                               :user "work"
                                               :host "slack")))

           (team-name (plist-get auth-info :team-name))
           (client-id (plist-get auth-info :client-id))
           (client-secret (plist-get auth-info :client-secret))
           (token (plist-get auth-info :token)))

      (slack-register-team
       :default t
       :name team-name
       :client-id client-id
       :client-secret client-secret
       :token token))

    (defun td/slack-update-all ()
      (interactive)
      (slack-im-list-update)
      (slack-group-list-update)
      (slack-channel-list-update))
    ))

(setq
 swift-mode:multiline-statement-offset 4
 swift-mode:parenthesized-expression-offset 4)

(setq winum-scope 'frame-local)

(with-eval-after-load 'yasnippet

(add-hook 'text-mode-hook #'yas-minor-mode)

(setq yas-snippet-dirs '("~/.spacemacs.d/snippets"))
(yas-reload-all)

;; Bind `SPC' to `yas-expand' when snippet expansion available (it
;; will still call `self-insert-command' otherwise).
(define-key yas-minor-mode-map (kbd "SPC") yas-maybe-expand)
(define-key yas-minor-mode-map (kbd "C-c C-c") yas-maybe-expand)

)

(td/zen)
