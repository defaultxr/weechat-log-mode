;;; weechat-log-mode.el --- Mode for viewing weechat logs -*- lexical-binding: t -*-

;; Copyright (C) 2022 modula t.

;; Author: modula t. <defaultxr at gmail dot com>
;; Homepage: https://github.com/defaultxr/weechat-log-mode
;; Version: 0.5
;; Keywords: 
;; Package-Requires: ((emacs "25.1"))

;; This file is not part of GNU Emacs.

;;; License:

;; WeeChat-Log-Mode is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; WeeChat-Log-Mode is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with WeeChat-Log-Mode.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:
;;
;; This package provides a simple mode for viewing WeeChat log
;; files. Its main feature is basic syntax highlighting to make them
;; easier to read.
;;
;; Unfortunately it is not possible to use the same highlighting as
;; the WeeChat UI or weechat.el since those colors are usually
;; provided directly by WeeChat itself and are not stored in the log
;; files.

;;; Code:

;;; font-locking/highlighting

(defface weechat-log-mode-timestamp-face
  '((t :inherit font-lock-comment-face))
  "Face used to highlight the timestamp at the start of each line."
  :group 'weechat-log)

(defface weechat-log-mode-nick-face
  '((t :inherit font-lock-type-face :weight bold))
  "Face used to highlight the nick of the user acting or speaking."
  :group 'weechat-log)

(defface weechat-log-mode-status-face
  '((t :foreground "blue"))
  "Face used to highlight status events."
  :group 'weechat-log)

(defface weechat-log-mode-join-face
  '((t :foreground "green"))
  "Face used to highlight join events."
  :group 'weechat-log)

(defface weechat-log-mode-part-face
  '((t :foreground "red"))
  "Face used to highlight part events."
  :group 'weechat-log)

(defvar weechat-log-mode-syntax-table (let ((table (make-syntax-table)))
                                        (modify-syntax-entry ?\" "w" table)
                                        table)
  "Syntax table for `weechat-log-mode'.")

(defvar weechat-log-mode-font-lock-timestamp-regexp "^[0-9]+-[0-9]+-[0-9]+ [0-9:]+")

(defvar weechat-log-mode-font-lock
  `((,weechat-log-mode-font-lock-timestamp-regexp . 'weechat-log-mode-timestamp-face)
    (,(concat weechat-log-mode-font-lock-timestamp-regexp "\t\\(\\(<--\\|-->\\)\t\\)?\\([^<>[:blank:]]+\\)[[:blank:]]+") 3 'weechat-log-mode-nick-face)
    (,(concat weechat-log-mode-font-lock-timestamp-regexp "\t\\(-->\\)\t") 1 'weechat-log-mode-join-face)
    (,(concat weechat-log-mode-font-lock-timestamp-regexp "\t\\(<--\\)\t") 1 'weechat-log-mode-part-face)
    (,(concat weechat-log-mode-font-lock-timestamp-regexp "\t\\(--\\)\t") 1 'weechat-log-mode-status-face t)))

;;; utility functionality

(defcustom weechat-logs-directory "~/.weechat/logs/"
  "Location that WeeChat stores its logs in. Used for `weechat-open-log'."
  :type '(directory)
  :group 'weechat-log)

(defun weechat-open-log (&optional channel)
  "Open the WeeChat log for CHANNEL, or the one for the current buffer if none provided.

See also: `weechat-logs-directory', `weechat-log-mode-open-channel'"
  (interactive)
  (let* ((channel (or channel (buffer-name)))
         (files (directory-files weechat-logs-directory t (regexp-quote channel)))
         (files-len (length files)))
    (if (= files-len 0)
        (user-error "No matching log file found for `%s' in `%s'" channel weechat-logs-directory)
      (find-file (if (= files-len 1)
                     (car files)
                   (let ((collection (mapcar (lambda (file)
                                               (cons (file-name-nondirectory file) file))
                                             files)))
                     (cdr (assoc (completing-read "Multiple files match; select which to open:" collection nil t)
                                 collection))))))))

(defun weechat-log-mode-open-channel (&optional file)
  "Open the equivalent weechat-mode buffer for the WeeChat log FILE, or the current buffer if none provided.

See also: `weechat-open-log'"
  (interactive)
  (let ((filename (file-name-nondirectory (or file (buffer-file-name)))))
    (if (string-match "^[^.]+\.\\(.+\\)\.weechatlog$" filename)
        (let ((channel-buffer-name (match-string-no-properties 1 filename)))
          (when-let ((buffer (get-buffer channel-buffer-name)))
            (display-buffer buffer)))
      (user-error "No buffer found for file `%s'" file))))

;;; keymap

(defvar weechat-log-mode-map
  (let ((map (make-sparse-keymap "WeeChat-Log-Mode")))
    (define-key map (kbd "C-c C-l") 'weechat-log-mode-open-channel)
    map)
  "Keymap for `weechat-log-mode'.")

;;; define the mode

;;;###autoload
(define-derived-mode weechat-log-mode fundamental-mode "weechat-log"
  "Major mode for WeeChat log files."
  (use-local-map tracker-mode-map)
  (set-syntax-table weechat-log-mode-syntax-table)
  (setq font-lock-defaults '(weechat-log-mode-font-lock)))

;;;###autoload
(add-to-list 'auto-mode-alist '("\\.weechatlog\\'" . weechat-log-mode))

(provide 'weechat-log-mode)

;;; weechat-log-mode.el ends here
