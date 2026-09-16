;;; $DOOMDIR/config.el -*- lexical-binding: t; -*-

;; Place your private configuration here! Remember, you do not need to run 'doom
;; sync' after modifying this file!


;; Some functionality uses this to identify you, e.g. GPG configuration, email
;; clients, file templates and snippets. It is optional.
;; (setq user-full-name "John Doe"
;;       user-mail-address "john@doe.com")

;; Doom exposes five (optional) variables for controlling fonts in Doom:
;;
;; - `doom-font' -- the primary font to use
;; - `doom-variable-pitch-font' -- a non-monospace font (where applicable)
;; - `doom-big-font' -- used for `doom-big-font-mode'; use this for
;;   presentations or streaming.
;; - `doom-symbol-font' -- for symbols
;; - `doom-serif-font' -- for the `fixed-pitch-serif' face
;;
;; See 'C-h v doom-font' for documentation and more examples of what they
;; accept. For example:
;;
;;(setq doom-font (font-spec :family "Fira Code" :size 12 :weight 'semi-light)
;;      doom-variable-pitch-font (font-spec :family "Fira Sans" :size 13))
;;
;; If you or Emacs can't find your font, use 'M-x describe-font' to look them
;; up, `M-x eval-region' to execute elisp code, and 'M-x doom/reload-font' to
;; refresh your font settings. If Emacs still can't find your font, it likely
;; wasn't installed correctly. Font issues are rarely Doom issues!

;; There are two ways to load a theme. Both assume the theme is installed and
;; available. You can either set `doom-theme' or manually load a theme with the
;; `load-theme' function. This is the default:
(setq doom-theme 'doom-one)

;; This determines the style of line numbers in effect. If set to `nil', line
;; numbers are disabled. For relative line numbers, set this to `relative'.
(setq display-line-numbers-type t)

;; If you use `org' and don't want your org files in the default location below,
;; change `org-directory'. It must be set before org loads!
(setq org-directory "~/org/")


;; Whenever you reconfigure a package, make sure to wrap your config in an
;; `with-eval-after-load' block, otherwise Doom's defaults may override your
;; settings. E.g.
;;
;;   (with-eval-after-load 'PACKAGE
;;     (setq x y))
;;
;; The exceptions to this rule:
;;
;;   - Setting file/directory variables (like `org-directory')
;;   - Setting variables which explicitly tell you to set them before their
;;     package is loaded (see 'C-h v VARIABLE' to look them up).
;;   - Setting doom variables (which start with 'doom-' or '+').
;;
;; Here are some additional functions/macros that will help you configure Doom.
;;
;; - `load!' for loading external *.el files relative to this one
;; - `add-load-path!' for adding directories to the `load-path', relative to
;;   this file. Emacs searches the `load-path' when you load packages with
;;   `require' or `use-package'.
;; - `map!' for binding new keys
;;
;; To get information about any of these functions/macros, move the cursor over
;; the highlighted symbol at press 'K' (non-evil users must press 'C-c c k').
;; This will open documentation for it, including demos of how they are used.
;; Alternatively, use `C-h o' to look up a symbol (functions, variables, faces,
;; etc).
;;
;; You can also try 'gd' (or 'C-c c d') to jump to their definition and see how
;; they are implemented.
(map! :leader
      :desc "Hermes Agent"
      "h a" #'(lambda () (interactive) (vterm "hermes")))

;; Auto-insert in vterm so Hermes is ready to type immediately.
(add-hook 'vterm-mode-hook #'evil-insert-state)

(defun +my/open-hermes-dashboard ()
  "Open all Hermes profile vterms in a 3x2 dashboard layout."
  (interactive)
  (let* ((profiles '(("market" . "Market")
                     ("content" . "Content")
                     ("operation" . "Operation")
                     ("finance" . "Finance")
                     ("compliance" . "Compliance")
                     ("supplychain" . "Supply Chain")))
         bufs top-row)
    ;; Pre-create vterm buffers first.
    (dolist (p profiles)
      (let ((name (format "Hermes %s" (cdr p))))
        (push (vterm name) bufs)
        (vterm-send-string (format "hermes -p %s\n" (car p)))))
    (setq bufs (nreverse bufs))
    (delete-other-windows)
    ;; Build 3x2 grid: top row of 3, each split below for bottom row.
    (setq top-row (list (selected-window)))
    (dotimes (_ 2)
      (let ((new-win (split-window (car top-row) nil 'right)))
        (setq top-row (cons new-win top-row))))
    (setq top-row (nreverse top-row))
    (dolist (win top-row)
      (set-window-buffer win (pop bufs))
      (let ((bot-win (split-window win nil 'below)))
        (set-window-buffer bot-win (pop bufs))))
    (balance-windows)
    (select-window (frame-root-window (selected-frame)))))

(map! :leader
      :desc "Hermes Dashboard (all profiles)"
      "h d" #'+my/open-hermes-dashboard)

(defun +my/capture-hermes-output ()
  (interactive)
  (let ((text (current-kill 0)))
    (org-capture nil "h")
    (org-insert-item)
    (insert text)
    (org-capture-finalize)))

(map! :leader
      :desc "Capture Hermes output to Org"
      "h c" #'+my/capture-hermes-output)

;;;;;;;;;;
;;;;;;;;;;
(toggle-frame-maximized)


(after! corfu
  (setq corfu-auto t
        corfu-auto-delay 0.1
        corfu-auto-prefix 1
        corfu-preview-current t)
  (corfu-popupinfo-mode 1)
  (setq corfu-popupinfo-delay '(0.2 . 0.1)))

;; 手动将 Rust 工具链路径注入 Emacs 查找链
(add-to-list 'exec-path (expand-file-name "~/.cargo/bin"))
(setenv "PATH" (concat (expand-file-name "~/.cargo/bin") ":" (getenv "PATH")))

;; 如果你使用的是 lsp-mode（即 (rust +lsp) 默认搭配）
(after! lsp-rust
  (setq lsp-rust-analyzer-server-display-inlay-hints t
        lsp-rust-analyzer-display-parameter-hints t
        lsp-rust-analyzer-display-lifetime-elision-hints-enable "always"
        lsp-rust-analyzer-display-closure-return-type-hints t))

;; 如果你使用的是内置的 eglot
(after! eglot
  (add-hook 'rust-mode-hook #'eglot-inlay-hints-mode)
  (add-hook 'rust-ts-mode-hook #'eglot-inlay-hints-mode))

;;
(use-package! popterm
  :commands (popterm-toggle popterm-toggle-cd)
  :init
  ;; 将默认的 SPC o t 重新绑定为 Child-frame 浮动终端
  (map! :leader
        :prefix "o"
        :desc "Toggle floating terminal" "t" #'popterm-toggle
        :desc "Toggle floating terminal (cd)" "T" #'popterm-toggle-cd)
  :config
  ;; 1. 指定后端：vterm 或 eshell（根据你的 Doom 启用的终端选择）
  (setq popterm-backend 'vterm)         ; 若未配置 vterm，可改为 'eshell

  ;; 2. 显示方式设定为 Child-frame (posframe)
  (setq popterm-display-method 'posframe)

  ;; 3. 悬浮窗尺寸设置 (屏幕宽高的 65%)
  (setq popterm-posframe-width-ratio 0.65
        popterm-posframe-height-ratio 0.65
        popterm-posframe-border-width 2))


;; 启动时启用 doom-big-font-mode
;;(add-hook 'after-init-hook #'doom-big-font-mode)

;; 可选：自定义 doom-big-font 的大小
;;(setq doom-big-font (font-spec :family "JetBrains Mono" :size 36))


(load! "lisp/dddd-agent-workspace.el")

;;; bind key in vterm-mod
;;(evil-define-key 'normal vterm-mode-map (kbd "C-c i") #'dddd/vterm-sendto-inbox)
;;(evil-define-key 'visual vterm-mode-map (kbd "C-c i") #'dddd/vterm-sendto-inbox)

(define-key evil-normal-state-map (kbd "SPC t a") #'dddd/agent-setup-layout)
(define-key evil-normal-state-map (kbd "SPC t z") #'dddd/agent-reset-layout)

(global-set-key (kbd "C-c i") #'dddd/vterm-sendto-inbox)
(global-set-key (kbd "C-c d") #'dddd/vterm-sendto-todo)
(global-set-key (kbd "C-c f") #'dddd/inbox-promote-to-formal)
