;; Some functionality uses this to identify you, e.g. GPG configuration, email
;; clients, file templates and snippets.
(setq user-full-name "Brandon Pollack"
      user-mail-address "brandonpollack23@gmail.com")

(setq
 ;; Evil emacs mode cursor tells me it isn't evil
 evil-emacs-state-cursor '("purple" box)
 ;; Always confirm (even on splash and other not "real" buffers)
 confirm-kill-emacs 'y-or-n-p
 projectile-project-search-path '("$HOME/src", "$HOME/org"))
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

(setq display-line-numbers-type 'relative)

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

(after! org
  ;; If you use `org' and don't want your org files in the default location below,
  ;; change `org-directory'. It must be set before org loads!
  (setq org-directory "~/org/"
        org-todo-keywords '((sequence "TODO(t)" "INPROGRESS(i)" "WAITING(w)" "|" "DONE(d)" "CANCELLED(c)")
                            (sequence "[ ](T)" "[-](S)" "[?](W)" "|" "[X](D)")
                            (sequence "|" "OKAY(o)" "YES(y)" "NO(n)"))
        org-todo-keyword-faces '(("TODO" :foreground "forestgreen" :weight bold :underline t)
                                 ("INPROGRESS" :foreground "darkorange" :weight bold :underline t)
                                 ("WAITING" :foreground "yellow" :weight normal :underline nil)
                                 ("CANCELLED" :foreground "red" :weight bold :underline t)
                                 )
        org-log-done 'time

        ;; Quick captures
        org-capture-templates '(("x" "[inbox]" entry
                                 (file+headline "~/org/inbox.org" "Tasks")
                                 "* %i%?")
                                ("t" "Todo [inbox]" entry
                                 (file+headline "~/org/inbox.org" "Tasks")
                                 "* TODO %i%?")
                                ("T" "Tickler" entry
                                 (file+headline "~/org/tickler.org" "Tickler")
                                 "* %i%? \n %U"))
        org-refile-targets '((nil :maxlevel . 4)
                             (org-agenda-files :maxlevel . 4))
        ;; Show that whitespace
        org-cycle-separator-lines -1
        ;; Show only top level TODO items.
        org-agenda-todo-list-sublevels nil
        ;; Checklist cookies take into account full heirarchy.
        org-checkbox-hierarchical-statistics nil))

(after! (:and evil-smartparens org-mode)
  :init
  (add-hook 'org-mode-hook #'turn-off-smartparens-mode))

(after! org-id
  ;; This function allows id link completion
  (defun org-id-complete-link (&optional arg)
    "Create an id: link using completion using ARG."
    (concat "id:" (org-id-get-with-outline-path-completion)))
  (org-link-set-parameters "id" :complete #'org-id-complete-link))

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
     cmdExeBin"/mnt/c/Windows/System32/cmd.exe"
     cmdExeArgs '("/c" "start"))
    (setq
     browse-url-generic-program  cmdExeBin
     browse-url-generic-args     cmdExeArgs
     browse-url-browser-function 'browse-url-generic)
    )))
