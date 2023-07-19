;;; flycheck-buf-lint.el --- Flycheck checker for protobuf with buf.build  -*- lexical-binding: t; -*-

;; Author: Aaron Ji <shuxiao9058@gmail.com>
;; Keywords: convenience, tools, buf, protobuf
;; URL: https://github.com/shuxiao9058/flycheck-buf-lint
;; Version: 0.0.1
;; Package-Requires: ((emacs "26.1") (flycheck "0.22") (s "1.12.0"))

;;
;; This file is not part of GNU Emacs.

;; This program is free software; you can redistribute it and/or
;; modify it under the terms of the GNU General Public License
;; as published by the Free Software Foundation; either version 3
;; of the License, or (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to the
;; Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
;; Boston, MA 02110-1301, USA.
;;
;;; Commentary:

;; Flycheck checker for protocol with buf-build
;;
;; Usage:
;;
;;     (eval-after-load 'flycheck
;;       '(add-hook 'flycheck-mode-hook #'flycheck-buf-lint-setup))

;;; Code:

(require 'flycheck)
(require 's)

(defun flycheck-buf-lint--project-root (&optional _checker)
  "Return the nearest directory holding the buf.yaml configuration."
  (and buffer-file-name
       (locate-dominating-file buffer-file-name "buf.yaml")))

(defun flycheck-buf-lint--parse-flycheck (output checker buffer)
  "Parse OUTPUT as bento JSON.
CHECKER and BUFFER are supplied by Flycheck and indicate the checker that ran
and the buffer that were checked."
  (when-let* ((ss (s-split "\n" output))
	      (ss (cl-remove-if (lambda(x) (not (s-present? x))) ss)))
    (mapcar
     (apply-partially #'flycheck-buf-lint--item-to-flycheck checker buffer)
     ss)))

(defun flycheck-buf-lint--item-to-flycheck (checker _buffer message)
  "Convert MESSAGE into a Flycheck error found by CHECKER in BUFFER."
  (when-let* ((finding (flycheck-parse-json message))
	      (finding (car finding)))
    (let-alist finding
      (flycheck-error-new-at
       .start_line
       .start_column
       (pcase .type
	 ("COMPILE" 'error)
	 (_ 'warning))
       (format "[%s] %s" .type .message)
       ;; :id .check_id
       :end-line .end_line
       :end-column .end_column
       :checker checker
       ;; :buffer buffer
       :filename (expand-file-name .path (flycheck-buf-lint--project-root))))))

(flycheck-define-checker buf-lint
  "A Protobuf lint checker using buf

See URL `https://buf.build/docs/lint/usage/'."
  :command ("buf" "lint" (eval (concat (buffer-file-name) "#include_package_files=true")) "--error-format" "json"
	    (eval (let ((project-root (flycheck-buf-lint--project-root)))
		    (when project-root
		      `("--config" ,(expand-file-name "buf.yaml" project-root))))))
  :error-parser flycheck-buf-lint--parse-flycheck
  :working-directory (lambda (_checker) (flycheck-buf-lint--project-root))
  :enabled (lambda () (flycheck-buf-lint--project-root))
  :modes protobuf-mode)

;;;###autoload
(defun flycheck-buf-lint-setup ()
  "Setup Flycheck buf-lint.
Add `buf-lint' to `flycheck-checkers'."
  (interactive)
  (add-to-list 'flycheck-checkers 'buf-lint))

(provide 'flycheck-buf-lint)
;;; flycheck-buf-lint.el ends here
