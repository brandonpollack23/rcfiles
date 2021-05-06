;; Some functionality uses this to identify you, e.g. GPG configuration, email
;; clients, file templates and snippets.
(setq user-full-name "Brandon Pollack"
      user-mail-address "brandonpollack23@gmail.com")

(setq
 ;; Evil emacs mode cursor tells me it isn't evil
 evil-emacs-state-cursor '("purple" box)
 ;; Always confirm (even on splash and other not "real" buffers)
 confirm-kill-emacs 'y-or-n-p
 projectile-project-search-path '(
                                  ;; Local Source files
                                  "~/src/" "~/org/"
                                  ))
;; Start fullscreen
(add-to-list 'initial-frame-alist '(fullscreen . maximized))
;; Doom exposes five (optional) variables for controlling fonts in Doom. Here
;; are the three important ones:
;;
;; + `doom-font'
;; + `doom-variable-pitch-font'
;; + `doom-big-font' -- used for `doom-big-font-mode'; use this for
;;   presentations or streaming.
;;
;; They all accept either a font-spec, font string ("Input Mono-12"), or xlfd
;; font string. You generally only need these two:
;; (setq doom-font (font-spec :family "monospace" :size 12 :weight 'semi-light)
;;       doom-variable-pitch-font (font-spec :family "sans" :size 13))

;; There are two ways to load a theme. Both assume the theme is installed and
;; available. You can either set `doom-theme' or manually load a theme with the
;; `load-theme' function. This is the default:
(setq doom-theme 'doom-tomorrow-night)

;; make it so horizontal scroll is not a thing
(setq-default truncate-lines nil)
(setq-default word-wrap t)

;; Allow prompting for root whenever editing unpriveleged file
(auto-sudoedit-mode 1)

(setq
 tramp-shell-prompt-pattern
 "\\(?:^\\|\\)[^]#$%>\n]*#?[]#$%>].* *\\(\\[[0-9;]*[a-zA-Z] *\\)*")

(after! mozc
  (setq-default mozc-candidate-style 'echo-area))

(use-package! evil-org
  :when (featurep! :editor evil +everywhere)
  :config
  (map! :map evil-org-mode-map
        :i "RET" (cmds! mozc-mode (cmd! (mozc-handle-event last-command-event))
                        (cmd! (org-return electric-indent-mode)))
        :i [return] (cmds! mozc-mode (cmd! (mozc-handle-event last-command-event))
                           (cmd! (org-return electric-indent-mode)))))

(setq display-line-numbers-type t)

(set-popup-rules!
  '(("^\\*\\([Hh]elp\\|Apropos\\)"
     :slot 2 :vslot -8 :size 0.45 :select t)))

(defun break-window-into-workspace ()
  "Takes current window and moves it to its own workspace/perspective"
  (interactive)
  (let ((buff (current-buffer)))
    (+workspace/close-window-or-workspace)
    (+workspace/new)
    (switch-to-buffer buff)
    (when (+popup-buffer-p)
      (+popup/raise (selected-window)))))
(map! :leader
      :prefix "TAB"
      :nv "b" 'break-window-into-workspace) ; b for break

(after! spell-fu
  (setq-default ispell-dictionary "en")
  (setq ispell-personal-dictionary "/home/brpol/.doom.d/etc/english.pws")
  (setf (alist-get 'markdown-mode +spell-excluded-faces-alist)
        '(markdown-code-face
          markdown-reference-face
          markdown-link-face
          markdown-url-face
          markdown-markup-face
          markdown-html-attr-value-face
          markdown-html-attr-name-face
          markdown-html-tag-name-face)))

(setq fancy-splash-image "~/.doom.d/logo.png")
(defun doom-dashboard-print-under-fancy-splash ()
  (when (display-graphic-p)
    (let* ((banner
            '(" _____                          "
              "| ____|_ __ ___   __ _  ___ ___ "
              "|  _| | '_ ` _ \\ / _` |/ __/ __|"
              "| |___| | | | | | (_| | (__\\__ \\"
              "|_____|_| |_| |_|\\__,_|\\___|___/"))
           (longest-line (apply #'max (mapcar #'length banner))))
      (put-text-property
       (point)
       (dolist (line banner (point))
         (insert (+doom-dashboard--center
                  +doom-dashboard--width
                  (concat
                   line (make-string (max 0 (- longest-line (length line)))
                                     32)))
                 "\n"))
       'face 'doom-dashboard-banner))))
(setq +doom-dashboard-functions
      '(doom-dashboard-widget-banner
        doom-dashboard-print-under-fancy-splash
        doom-dashboard-widget-shortmenu
        doom-dashboard-widget-loaded
        doom-dashboard-widget-footer))

(defun get-string-from-file (filePath)
  "Return filePath's file content."
  (with-temp-buffer
    (insert-file-contents filePath)
    (buffer-string)))

(defun my-move-window-to-mini-repl ()
  "Move window to bottm and give it a height of 15px"
  (interactive)
  (+evil/window-move-down)
  (evil-window-set-height 15))
(map! :leader
      ;; m for mini
      :n "M" #'my-move-window-to-mini-repl)

(map! :leader
      :prefix "v"
      :v "v" #'er/expand-region
      :v "SPC" #'er/contract-region)

(map!
 :nvi "C-M-," 'sp-backward-slurp-sexp
 :nvi "C-M-." 'sp-forward-slurp-sexp
 :nvi "C-M-j" 'sp-beginning-of-next-sexp
 :nvi "C-M-k" 'sp-beginning-of-previous-sexp
 :nvi "C-M-u" 'backward-up-list
 :nvi "C-M-h" 'down-list)

(after! evil-easymotion
  ;; evil-easymotion (built on avy) jump keys
  (setq avy-keys '(?a ?s ?d ?f ?g ?h ?i ?k ?l ?\; ?t ?u ?v ?b ?n ?m ?i ?,))
  ;; evil-easymotion use first column
  (evilem-make-motion
   evilem-motion-next-line #'next-line
   :pre-hook (setq evil-this-type 'line)
   :bind ((temporary-goal-column 0)
          (line-move-visual nil)))
  (evilem-make-motion
   evilem-motion-previous-line #'previous-line
   :pre-hook (setq evil-this-type 'line)
   :bind ((temporary-goal-column 0)
          (line-move-visual nil))))

(use-package! evil-escape
  :init
  (setq evil-escape-delay 0.3)
  (setq evil-escape-key-sequence "jj"))

(custom-set-faces!
  '(aw-leading-char-face
    :foreground "white" :background "red"
    :weight bold :height 2.5 :box (:line-width 7 :color "red")))

;; Utility since %s is ignored in todo prefix format.
(defun myorg-get-scheduled-date-for-todo ()
  (let ((scheduled (org-get-scheduled-time (point))))
    (if scheduled
        (format-time-string "%Y-%m-%d %I:%M %p => " scheduled)
      "")))

(after! org
  ;; If you use `org' and don't want your org files in the default location below,
  ;; change `org-directory'. It must be set before org loads!
  (setq org-directory "~/org/"
        org-agenda-files `(,org-directory ,(concat org-directory "gmail_calendars"))
        org-todo-keywords '((sequence "TODO(t)" "INPROGRESS(i)" "WAITING(w)" "|" "DONE(d)" "CANCELLED(c)")
                            (sequence "[ ](T)" "[-](S)" "[?](W)" "|" "[X](D)")
                            (sequence "|" "OKAY(o)" "YES(y)" "NO(n)"))
        org-todo-keyword-faces '(("TODO" :foreground "forestgreen" :weight bold :underline t)
                                 ("INPROGRESS" :foreground "darkorange" :weight bold :underline t)
                                 ("WAITING" :foreground "yellow" :weight normal :underline nil)
                                 ("CANCELLED" :foreground "red" :weight bold :underline t))
        org-log-done 'time


        org-refile-targets '((nil :maxlevel . 4)
                             (org-agenda-files :maxlevel . 4))
        ;; Show that whitespace
        org-cycle-separator-lines -1
        ;; Show only top level TODO items.
        org-agenda-todo-list-sublevels nil
        ;; Modified from default to show schedules in TODO items
        org-agenda-prefix-format '((agenda . " %i %-12:c%?-12t% s")
                                   (todo . " %i %-12:c%(myorg-get-scheduled-date-for-todo)")
                                   (tags . " %i %-12:c")
                                   (search . " %i %-12:c"))
        ;; Checklist cookies take into account full heirarchy.
        org-checkbox-hierarchical-statistics nil))

(after! org-capture
  :config
  ;; Quick captures
  (setq org-capture-templates '(("x" "Inbox" entry
                                 (file+headline "~/org/inbox.org" "Tasks To Sort")
                                 "* %i%?")
                                ("t" "TODO Item" entry
                                 (file+headline "~/org/todo.org" "To Do List")
                                 "* TODO %i%?")
                                ("r" "Add (R)eminder" entry
                                 (file+headline "~/org/reminders.org" "Reminders")
                                 "* TODO %?\nSCHEDULED: %(org-insert-time-stamp (org-read-date t t nil \"When would you like to be reminded?\") t)"))))

(after! (:and evil-smartparens org-mode)
  :init
  (add-hook 'org-mode-hook #'turn-off-smartparens-mode))

(after! org-id
  ;; This function allows id link completion
  (defun org-id-complete-link (&optional arg)
    "Create an id: link using completion using ARG."
    (concat "id:" (org-id-get-with-outline-path-completion)))
  (org-link-set-parameters "id" :complete #'org-id-complete-link))

(use-package! org-depend :after org)

(defun myorg-archive-done-tasks ()
  (interactive)
  (org-map-entries 'org-archive-subtree "/DONE" 'tree))
(map! :localleader
      :n "m" #'myorg-archive-done-tasks)

;; TODO this doesnt work yet.
;; TODO when it does at it to save hook for org files with a check if it within org directory.
(defun myorg-get-title (dirfile-buffer)
  "org helper to extract the #+TITLE string"
  "DUMMY TITLE"
  )

(defun myorg-get-description (dirfile-buffer)
  "org helper to extract the #+DESCRIPTION string"
  "DUMMY DESCRIPTION"
  )

(defun myorg-export-files-insert-heading (buffer dirfile)
  "Inserts a single file with sub headings based on path in org directory"
  (let* ((index-buffer (current-buffer))
         (path-list (split-string dirfile "/")))
    (while (not (null path-list))
      (if (= (length path-list) 1)
          ;; This is the file itself
          (let*
              ((dirfile-buffer (find-file-read-only dirfile))
               ;; TODO extract the TITLE and DESCRIPTION functions (maybe org-capture/org-collect-keywords)
               (title (myorg-get-title dirfile-buffer))
               (description (myorg-get-description dirfile-buffer)))
            (progn
              (set-buffer index-buffer)
              (org-insert-heading)
              (insert title "\n" description)
              (pop path-list)))
        (progn
          (org-insert-heading)
          (org-metaright)
          (insert (pop path-list) "\n")))
      )))

(defun myorg-export-files-insert-headings (buffer) "Inserts all files by directory into subheadings into an index file"
       (dolist (dirfile (directory-files-recursively org-directory))
         myorg-export-files-insert-heading buffer dirfile))


(defun myorg-export-files-as-index ()
  "Export all the files in org as top level linked headings with the
descriptions as subtext into an org file with directories indicating subheadings"
  (interactive)
  (with-temp-buffer
    (insert "#+TITLE: Index" ?\n
            "#+DESCRIPTION: This is an autogenerated "
            "index of all the org files in the org-directory" ?\n ?\n)
    (myorg-export-files-insert-headings (current-buffer))
    ;; TODO save buffer to org-directory/index.org
    (message (buffer-string))))

(use-package! org-wild-notifier
  :config
  (setq org-wild-notifier-alert-time 10
        org-wild-notifier-alert-times-property "WILD_NOTIFIER_NOTIFY_BEFORE: 5"
        org-wild-notifier-notification-title "Reminder Notification!"
        org-wild-notifier-keyword-whitelist '("TODO")
        org-wild-notifier-tags-blacklist nil
        org-wild-notifier-tags-whitelist nil
        org-wild-notifier-keyword-whitelist nil)
  (org-wild-notifier-mode))

(after! alert
  (setq alert-default-style 'libnotify))

(use-package! org-gcal
  :config
  (defvar gmail_dir (concat org-directory "gmail_calendars/"))
  (setq
   org-gcal-client-id "936800008942-so0ctu4f2029386ujcfcp9ke3af91la2.apps.googleusercontent.com"
   org-gcal-client-secret (if (file-exists-p (concat gmail_dir "gcal_client_secret"))
                              (s-trim (get-string-from-file (concat gmail_dir "gcal_client_secret"))) "")
   org-gcal-fetch-file-alist `(("brandonpollack23@gmail.com" . ,(concat gmail_dir "personal.org"))
                               ("dnu3qs4g5pp6h4m9rfhsppgbik@group.calendar.google.com" . ,(concat gmail_dir "study.org")))
   org-gcal-down-days 365
   org-gcal-recurring-events-mode 'nested))

(use-package calfw-org
  :init
  (defun my-open-calendar ()
    (interactive)
    (cfw:open-calendar-buffer
     :contents-sources
     (list
      (cfw:org-create-source "Green")  ; org-agenda source
      ;; (cfw:org-create-file-source "Gmail Personal Calendar" (concat gmail_dir "personal.org") "Green")  ; other org source
      ;; (cfw:howm-create-source "Blue")  ; howm source
      ;; (cfw:cal-create-source "Orange") ; diary source
      ;; (cfw:ical-create-source "Moon" "~/moon.ics" "Gray")  ; ICS source1
      ;; (cfw:ical-create-source "gcal" "https://..../basic.ics" "IndianRed") ; google calendar ICS
      )))
  :config
  (map! :leader
        :prefix "o"
        :n "c" #'my-open-calendar))

;; Before date is 5 days from now (so within a work week)
(use-package! org-super-agenda
  :after org-agenda
  :config
  (org-super-agenda-mode)
  (let ((before-date (format-time-string "%F" (+ (* 60 60 24 5) (float-time)))))
    (setq org-super-agenda-groups `((:name "RIGHT NOW TODO List"
                                     :and (:priority "A"))

                                    (:name "TODO List"
                                     :file-path "org/todo.org")

                                    (:name "Upcoming Deadline Reminders In the next 5 days"
                                     :and (:deadline (before ,before-date)
                                           :file-path "org/reminders.org"))

                                    (:name "Upcoming Scheduled Reminders In the next 5 days"
                                     :and (:scheduled (before ,before-date)
                                           :file-path "org/reminders.org"))

                                    (:name "Technical Project Stuff"
                                     :and (:not (:priority "C")
                                           :file-path "org/technical_projects.org"))

                                    (:name "Deepspace9 Tasks"
                                     :file-path "org/deepspace9.org")

                                    (:name "Japan Move"
                                     :and (:file-path "org/moving_to_japan.org"
                                           :not (:todo "WAITING")))

                                    (:name "Backlog" :priority "C")

                                    (:name "Blocked Items"
                                     :todo "WAITING"))))
  org-super-agenda-header-separator (concat "\n" (make-string 80 ?=) "\n")
  ;; Workaround for keybinding problems
  org-super-agenda-header-map (make-sparse-keymap))

(use-package! org-journal
  :config
  (setq
   org-extend-today-until 3
   org-journal-file-format "jnl_Week_Of_%F"
   org-journal-file-type 'weekly
   org-journal-time-format "%I:%M %p"))

(unless (eq system-type 'windows-nt)
  (after! mu4e
    :config
    (setq +mu4e-backend 'offlineimap)
    (setq mu4e-get-mail-command "offlineimap -o -q")
    (setq mu4e-index-update-error-continue t)
    (setq mu4e-index-update-error-warning t)
    (setq mu4e-maildir "~/mail")
    (setq mu4e-update-interval (* 60 5))
    (set-email-account! "Gmail"
                        '((mu4e-sent-folder       . "/Gmail/All Mail")
                          (mu4e-drafts-folder     . "/Gmail/Drafts")
                          (mu4e-trash-folder      . "/Gmail/Trash")
                          (mu4e-refile-folder     . "/Gmail/All Mail")
                          (smtpmail-smtp-user     . "brandonpollack23@gmail.com")
                          (user-mail-address      . "brandonpollack23@gmail.com")
                          (mu4e-compose-signature
                           . "---\nBrandon Pollack\n ブランドンポラック"))
                        t)
    (setq mu4e-bookmarks `(("x:\\\\Inbox" "Inbox" ?i)
                           ("x:\\\\Inbox AND flag:unread" "Inbox Unread" ?n)
                           ("flag:flagged" "Flagged messages" ?f)
                           (,(concat "flag:unread AND "
                                     "NOT flag:trashed AND "
                                     "NOT maildir:/[Gmail].Spam AND "
                                     "NOT maildir:/[Gmail].Bin")
                            "Unread messages" ?u)))
    (add-hook 'mu4e-mark-execute-pre-hook
              (lambda (mark msg)
                (cond ((member mark '(refile trash))
                       (mu4e-action-retag-message msg "-\\Inbox"))
                      ((equal mark 'flag)
                       (mu4e-action-retag-message msg "\\Starred"))
                      ((equal mark 'unflag)
                       (mu4e-action-retag-message msg "-\\Starred")))))
    ))

(use-package! aggressive-indent
  :config
  (global-aggressive-indent-mode 1)
  (setq aggressive-indent-comments-too 1))

(defun my-buffer-face-mode-variable ()
  "Set font to a variable width (proportional) fonts in current buffer"
  (interactive)
  (setq buffer-face-mode-face '(:family "DejaVuSans" :height 150 :width semi-condensed))
  (buffer-face-mode))
(add-hook 'Info-mode-hook 'my-buffer-face-mode-variable)

(use-package! command-log-mode
  :config
  (map! :leader
        :prefix "v"
        :nv "l" 'clm/toggle-command-log-buffer)
  (setq command-log-mode-window-size 80)
  (setq command-log-mode-open-log-turns-on-mode t))

(use-package! emr
  :config
  (map!
   :nvi "M-RET" #'emr-show-refactor-menu))

(map! :after racket-mode
      :map racket-mode-map
      :localleader
      :n "n" #'racket-debug-step-over
      :n "N" #'racket-debug-step)

(use-package! cider-mode
  :hook ((cider-mode . cider-company-enable-fuzzy-completion)
         (cider-mode . cider-enlighten-mode)))
(use-package! cider-repl-mode
  :hook ((cider-mode . cider-company-enable-fuzzy-completion)
         (cider-mode . cider-enlighten-mode)))

;; Determine the specific system type.
;; Emacs variable system-type doesn't yet have a "wsl/linux" value,
;; so I'm front-ending system-type with my variable: sysTypeSpecific.
;; I'm no elisp hacker, so I'm diverging from the elisp naming convention
;; to ensure that I'm not stepping on any pre-existing variable.
(setq-default sysTypeSpecific  system-type) ;; get the system-type value

(cond
 ;; If type is "gnu/linux", override to "wsl/linux" if it's WSL.
 ((eq sysTypeSpecific 'gnu/linux)
  (when (string-match "Linux.*Microsoft.*Linux"
                      (shell-command-to-string "uname -a"))

    (setq-default sysTypeSpecific "wsl/linux") ;; for later use.
    (setq
     cmdExeBin "/mnt/c/Windows/System32/cmd.exe"
     cmdExeArgs '("/c" "start"))
    (setq
     browse-url-generic-program  cmdExeBin
     browse-url-generic-args     cmdExeArgs
     browse-url-browser-function 'browse-url-generic)

    ;; Create custom alert style that uses BurntToast
    (alert-define-style 'burnttoastwsl :title "WSL Burnt Toast"
                        :notifier
                        (lambda (info)
                          (let
                              ;; The message text is :message
                              ((msg (plist-get info :message))
                               ;; The :title of the alert
                               (title (plist-get info :title))
                               ;; The :category of the alert
                               (cat (plist-get info :category)))
                            (message (concat "ALERT!!!!\n\t" title "\n\t" cat "\n\t" msg))
                            (shell-command
                             (concat "powershell.exe \"New-BurntToastNotification -Text \\\"" title "\n" cat "\n" msg "\\\"\"")))))
    (after! alert
      (setq alert-default-style 'burnttoastwsl)))))

(if (file-exists-p "~/.emacs.local")
    (load-file "~/.emacs.local"))
