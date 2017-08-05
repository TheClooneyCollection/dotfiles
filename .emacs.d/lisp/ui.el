(use-package whitespace ; Built-in
  :diminish (whitespace-mode global-whitespace-mode)
  :init (setq whitespace-style '(face tabs trailing empty tab-mark))
  :config (global-whitespace-mode))

(use-package time ; Built-in
  :diminish display-time-mode
  :init
  (general-define-key "it" 'display-time-world)
  (setq display-time-world-list '(
                                  ("Australia/Sydney" "Sydney")
                                  ("Asia/Chongqing" "Chongqing")
                                  ("PST8PDT" "San Francisco")
                                  ("Asia/Calcutta" "Bangalore")
                                  ("Australia/Melbourne" "Melbourne")
                                  ("Europe/London" "London")
                                  ("Europe/Paris" "Paris")
                                  ("Asia/Tokyo" "Tokyo")
                                  ("America/Los_Angeles" "Los Angeles")
                                  ("America/New_York" "New York")
                                  ))
  :config (display-time-mode))

(use-package powerline
  :config (powerline-default-theme))

(use-package airline-themes
  :after powerline
  :init (setq powerline-utf-8-separator-left        #xe0b0
              powerline-utf-8-separator-right       #xe0b2
              airline-utf-glyph-separator-left      #xe0b0
              airline-utf-glyph-separator-right     #xe0b2
              airline-utf-glyph-subseparator-left   #xe0b1
              airline-utf-glyph-subseparator-right  #xe0b3
              airline-utf-glyph-branch              #xe0a0
              airline-utf-glyph-readonly            #xe0a2
              airline-utf-glyph-linenumber          #xe0a1)
  :config (load-theme 'airline-light t))
