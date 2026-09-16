;;; lisp/dddd-agent-workspace.el -*- lexical-binding: t; -*-

;;; ========= configuration ==========
(defvar dddd/workspace-dir "~/.config/doom/lisp"
  "work folder")

(defvar dddd/todo-file
  "TODO.org"
  "TODO file name")

(defvar dddd/formal-file
  "Formal.md"
  "Formal file name")

;;; ==================================
;;;
(defvar dddd/workspace-initialized nil
  "whether the dddd workspace has been initialized.")




(defun dddd/expand-file (filename)
  (expand-file-name filename dddd/workspace-dir))


(defun dddd/agent-create-buffers ()
  " agent work space need 3 buffers : *TODO*, *INBOX*, *Formal*,"
  (interactive)
  (get-buffer-create "*Inbox*")
  (get-buffer-create "*Todo*")
  (get-buffer-create "*Formal*")

)

(provide 'dddd-agent-workspace)

;; (defun dddd/agent-split-windows ()
;;   (interactive)
;;   (dddd/agent-setup-layout)
;;     ; 1. 先左右 split
;;   (let ((left-window (selected-window)))
;;     (split-window-right)
;;     (let ((right-window (selected-window)))
;;       ; 2. 在右边窗口里上下 split
;;       (select-window right-window)
;;       (split-window-below)
;;       (let ((top-right-window (selected-window))
;;             (bottom-window (next-window)))
;;         ; 3. 在右上窗口里左右 split
;;         (select-window top-right-window)
;;         (split-window-right)
;;         ; 现在我们有四个窗口：
;;         ; left-window, top-right-left, top-right-right, bottom-window
;;         ))))

(defun dddd/agent-setup-layout ()
  "split windows: Left: Hermes Agent, Right: Topleft: Inbox, Topright: Todo, Bottom: Formal"
  (interactive)
  ;;; make sure 3 buffers exist
  (dddd/agent-create-buffers)

  (if (and dddd/workspace-initialized
           (get-buffer-window "*Inbox*")
           (get-buffer-window "*Formal*"))
      (message "DDDD Agent workspace already exists! Use M-x dddd/agent-reset-layout to reset.")
    (setq dddd/workspace-initialized t)
  )

  ;; 1. left right split
  (let ((left-window (selected-window)))
    (split-window-right)
    (let ((left-window (selected-window))
          (right-window (next-window))
          (top-right-window nil)
          (top-right-left-window nil)
          (top-right-right-window nil)
          (bottom-window nil))

      ;; 2. right window, up-down split
      (select-window right-window)
      (split-window-below)
      (setq bottom-window (next-window))
      (setq top-right-window (selected-window))


      ;;; 3. top-right window left-right split
      (select-window top-right-window)
      (split-window-right)
      (setq top-right-left-window (selected-window))
      (setq top-right-right-window (next-window))

      ;;; 4. allocate buffers to windows
      (set-window-buffer top-right-left-window "*Inbox*")
      (set-window-buffer top-right-right-window (find-file-noselect (dddd/expand-file dddd/todo-file)));;"~/.config/doom/lisp/TODO.org"));;;"*Todo*")
      (set-window-buffer bottom-window "*Formal*")

      ;;; 5. Set cursor on the left window for Hermes
      (select-window left-window)

      ;;; 6. set protection parameter
      (set-window-parameter top-right-left-window 'no-delete-other-windows t)
      (set-window-parameter top-right-right-window 'no-delete-other-windows t)
      (set-window-parameter bottom-window 'no-delete-other-windows t)

      ;;; set dedicated
      (set-window-dedicated-p top-right-left-window t)
      (set-window-dedicated-p top-right-right-window t)
      (set-window-dedicated-p bottom-window t)

      (setq window-state-ignore-user-configuration t)

      (set-window-parameter left-window 'no-delete t)
      (set-window-parameter top-right-left-window 'no-delete t)
      (set-window-parameter top-right-right-window 'no-delete t)
      (set-window-parameter bottom-window 'no-delete t)

      ;;; 7. Launch Hermes
      (select-window left-window)
      (vterm "hermes")
      (vterm-copy-mode)
      ))
  )

;;;;;;;;;;;;;;;;
(defun dddd/agent-reset-layout ()
  "Reset the dddd workspace layout."
  (interactive)
  (setq dddd/workspace-initialized nil)
  ;; close the related windows
  ;; (dolist (buf-name '("*Inbox" "*Formal"))
  ;;   (when (get-buffer-window buf-name)
  ;;     (quit-window nil (get-buffer-window buf-name))))
  ;; (message "DDDD Agent workspace reset")
  (delete-other-windows)
  (message "DDDD Agent workspace reset")
)
;;;;;;;;;;;;;;;;
(defun dddd/inbox-insert-from-killring ()
  "insert the content which from kill ring into *Inbox*"
  (interactive)
  (let ((text (current-kill 0)))
    (with-current-buffer (get-buffer "*Inbox*")
      (goto-char (point-max))
      (insert "\n---\n" text "\n")
      (goto-char (point-max))))
)


;;;;;;;;;;;;;;;;;;;
(defun dddd/vterm-sendto-inbox ()
  "send the selected content in vterm to Buffer *Inbox*"
  (interactive)
  (vterm-copy-mode)
  (dddd/inbox-insert-from-killring))

(defun dddd/vterm-auto-sendto-inbox ()
  "in Vterm automatic sent the content which user is copied to Buffer Inbox"
  (interactive)
  (call-interactively 'vterm-copy-mode))

;;;;;;;;;;;;;;;;;;
(defun dddd/sendto-todo (text)
  "Insert TEXT into TODO.org with hierarchical checkboxes."
    ;; 1. Strip ANSI escape sequences
  (setq text (replace-regexp-in-string "\x1b\\[[0-9;]*[a-zA-Z]" "" text))
  ;; 2. Convert carriage returns to newlines
  (setq text (replace-regexp-in-string "\r" "\n" text))
  ;; 3. Split into lines and process
  (let ((lines (split-string text "\n")))
    (with-current-buffer (find-file-noselect (dddd/expand-file dddd/todo-file));;"~/.config/doom/lisp/TODO.org")
      (goto-char (point-max))
      (dolist (line lines)
        (if (string-match-p "^\\s-*$" line)
            ;;
            ()
          ;; keep indent and add - [] prefix
          (string-match "^\\(\\s-*\\)\\(.*\\)" line)
          (insert (format "\n%s- [ ] %s"
                          (match-string 1 line)
                          (match-string 2 line)))))
      (save-buffer))))

(defun dddd/vterm-sendto-todo ()
  "copy selected content in term and send to TODO.org with checkboxes."
  (interactive)
  (vterm-copy-mode)
  (let ((text (current-kill 0)))
    (dddd/sendto-todo text)))

;;;;;;;;;;;;;;;;;;

(defun dddd/format-timestamp ()
  "generate time stamp codes"
  (format-time-string "----------%d.%m.%Y %H:%M:%S %A----------"))

(defun dddd/inbox-promote-to-formal (begin end)
  "send selected content in the buffer Inbox to the buffer Formal with time stamp. append to the FORMAL.md"
  (interactive "r")
  (let* ((timestamp (dddd/format-timestamp))
         (text (buffer-substring-no-properties begin end))
         (content (concat timestamp "\n" text "\n" timestamp "\n\n")))
    ;; insert content into formal buffer
    (with-current-buffer (get-buffer "*Formal*")
      (goto-char (point-max))
      (insert content))
    ;; append to file FORMAL.md
    (with-temp-buffer
      (insert content)
      (setq write-region-inhibit-fsync t)
      (write-region (point-min) (point-max) (dddd/expand-file dddd/formal-file) t));; "~/.config/doom/lisp/Formal.md" t))
    ;; delete the content after append to formal buffer
    (delete-region begin end)
    ))

(defvar inbox-mode-map (make-sparse-keymap)
  "Keymap for *Inbox* Buffer")

;;(define-key inbox-mode-map (kbd "C-c i") #'dddd/inbox-insert-from-killring)
;;(define-key inbox-mode-map (kbd "C-c f") #'dddd/inbox-promote-to-formal)

;; 在 vterm 里也用 C-c i 发送到 Inbox
;;(define-key vterm-mode-map (kbd "C-c i") #'dddd/vterm-sendto-inbox)
;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;

;;; dddd-agent-workspace.el end here
