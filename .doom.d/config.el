;;; $DOOMDIR/config.el -*- lexical-binding: t; -*-

;; Place your private configuration here! Remember, you do not need to run 'doom
;; sync' after modifying this file!

;; Here are some additional functions/macros that could help you configure Doom:
;;
;; - `load!' for loading external *.el files relative to this one
;; - `use-package!' for configuring packages
;; - `after!' for running code after a package has loaded
;; - `add-load-path!' for adding directories to the `load-path', relative to
;;   this file. Emacs searches the `load-path' when you load packages with
;;   `require' or `use-package'.
;; - `map!' for binding new keys
;;
;; To get information about any of these functions/macros, move the cursor over
;; the highlighted symbol at press 'K' (non-evil users must press 'C-c c k').
;; This will open documentation for it, including demos of how they are used.
;;
;; You can also try 'gd' (or 'C-c c d') to jump to their definition and see how
;; they are implemented.

;; Some functionality uses this to identify you, e.g. GPG configuration, email
;; clients, file templates and snippets.
(setq user-full-name "Brandon Pollack"
      user-mail-address "brandonpollack23@gmail.com")

;; General Doom Setup Functions
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

;; org mode
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
                                 )))


;; This determines the style of line numbers in effect. If set to `nil', line
;; numbers are disabled. For relative line numbers, set this to `relative'.
(setq display-line-numbers-type 'relative)

;; Help window embiggening (default in DOOM is .35)
(set-popup-rules!
  '(("^\\*\\([Hh]elp\\|Apropos\\)"
     :slot 2 :vslot -8 :size 0.45 :select t)))

;; Custom Dashboard and Logo!
(setq fancy-splash-image "~/.doom.d/logo.png")
;; TODO if fancy splash displayed then emit Emacs in ascii
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

;; General Custom Bindings
;; Bindings reference:
;; https://github.com/hlissner/doom-emacs/blob/2d140a7a80996cd5d5abc084db995a8c4ab6d7f4/modules/config/default/%TBevil-bindings.el

;; Expand/contract selections
(map! :leader
      :prefix "v"
      :v "v" #'er/expand-region
      :v "SPC" #'er/contract-region)

;; evil-easymotion
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

;; Lisp helper bindings
(map!
 :nvi "C-M-," 'sp-backward-slurp-sexp
 :nvi "C-M-." 'sp-forward-slurp-sexp
 :nvi "C-M-j" 'sp-beginning-of-next-sexp
 :nvi "C-M-k" 'sp-beginning-of-previous-sexp
 :nvi "C-M-u" 'backward-up-list
 :nvi "C-M-h" 'down-list)

;; imap mappings
(use-package! evil-escape
  :init
  (setq evil-escape-delay 0.3)
  (setq evil-escape-key-sequence "jj"))

;; Use emacs navigation in info mode
;; NOTE this sucked, it's easer to just C-z when I need it.
;; (evil-set-initial-state 'Info-mode 'emacs)

;; Japanese input
;; 日本語！ テスト
(after! mozc
  (setq-default mozc-candidate-style 'echo-area))

;; mu4e email setup
;; Inspired by: https://groups.google.com/g/mu-discuss/c/BpGtwVHMd2E
(unless (eq system-type 'windows-nt)
  (after! mu4e
    :config
    (setq +mu4e-backend 'offlineimap)
    (setq mu4e-get-mail-command "offlineimap -o -q")
    (setq mu4e-index-update-error-continue t)
    (setq mu4e-index-update-error-warning t)
    (setq mu4e-root-maildir "~/mail")
    (setq mu4e-update-interval (* 60 5))
    (set-email-account! "Gmail"
                        '((mu4e-sent-folder       . "/Gmail/All Mail")
                          (mu4e-drafts-folder     . "/Gmail/Drafts")
                          (mu4e-trash-folder      . "/Gmail/Trash")
                          (mu4e-refile-folder     . "/Gmail/All Mail")
                          (smtpmail-smtp-user     . "brandonpollack23@gmail.com")
                          (user-mail-address      . "brandonpollack23@gmail.com")
                          (mu4e-compose-signature
                           . "---\nBrandon Pollack\nブランドンポラック"))
                        t)
    ;; TODO more for my tags
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

;; Aggressive indent mode setup
(use-package! aggressive-indent
  :config
  (global-aggressive-indent-mode 1)
  (setq aggressive-indent-comments-too 1))

;; Enable word wrapping and don't scroll horizontally
(auto-fill-mode 1)
(setq-default truncate-lines nil)
(setq-default word-wrap t)

;; Ace Window config
(custom-set-faces!
  '(aw-leading-char-face
    :foreground "white" :background "red"
    :weight bold :height 2.5 :box (:line-width 7 :color "red")))

;; Info Mode better font
(defun my-buffer-face-mode-variable ()
  "Set font to a variable width (proportional) fonts in current buffer"
  (interactive)
  (setq buffer-face-mode-face '(:family "DejaVuSans" :height 150 :width semi-condensed))
  (buffer-face-mode))
(add-hook 'Info-mode-hook 'my-buffer-face-mode-variable)

;; Org mode disable smartparens so I can autocomplete buffers
(after! (:and smartparens-mode org-mode)
  :init
  (add-hook 'org-mode-hook #'turn-off-smartparens-mode))

;; WSL Crap
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
