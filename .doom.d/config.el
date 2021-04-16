;;; $DOOMDIR/config.el -*- lexical-binding: t; -*-

;; Place your private configuration here! Remember, you do not need to run 'doom
;; sync' after modifying this file!


;; Some functionality uses this to identify you, e.g. GPG configuration, email
;; clients, file templates and snippets.
(setq user-full-name "Brandon Pollack"
      user-mail-address "brandonpollack23@gmail.com")

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
(setq doom-theme 'doom-one)

;; If you use `org' and don't want your org files in the default location below,
;; change `org-directory'. It must be set before org loads!
(setq org-directory "~/org/")

;; This determines the style of line numbers in effect. If set to `nil', line
;; numbers are disabled. For relative line numbers, set this to `relative'.
(setq display-line-numbers-type t)


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

;; ~~~~~~~~~~~~~~~~~~~~~~~~~~~ Begin Custom Config ~~~~~~~~~~~~~~~~~~~~~~~~~~~

;; Japanese input
;; 日本語！
(use-package! mozc
  :defer t
  :custom (mozc-candidate-style 'echo-area))

;; Bindings reference:
;; https://github.com/hlissner/doom-emacs/blob/2d140a7a80996cd5d5abc084db995a8c4ab6d7f4/modules/config/default/%TBevil-bindings.el

;; Enable word wrapping and don't scroll horizontally
(auto-fill-mode 1)
(setq-default truncate-lines nil)
(setq-default word-wrap t)


(setq
 ;; Evil emacs mode cursor tells me it isn't evil
 evil-emacs-state-cursor '("purple" box)
 ;; Always confirm (even on splash and other not "real" buffers)
 confirm-kill-emacs 'y-or-n-p
 projectile-project-search-path '("$HOME/src"))

;; imap mappings
(use-package! evil-escape
  :init
  (setq evil-escape-delay 0.5)
  (setq evil-escape-key-sequence "jj"))

;; Use emacs navigation in info mode
(evil-set-initial-state 'Info-mode 'emacs)

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
      cmdExeArgs '("/c" "start" "") )
     (setq
      browse-url-generic-program  cmdExeBin
      browse-url-generic-args     cmdExeArgs
      browse-url-browser-function 'browse-url-generic)
     )))
