;;; flycheck-buf-lint.el --- Flycheck checker for protobuf with buf.build  -*- lexical-binding: t; -*-

;; Copyright (C) 2023  Aaron Ji

;; Author: Aaron Ji <shuxiao9058@gmail.com>
;; Keywords: convenience, tools, buf, protobuf
;; URL: https://github.com/shuxiao9058/flycheck-buf-lint
;; Version: 0.0.1
;; Package-Requires: ((emacs "26.1") (flycheck "0.22") (s "1.12.0"))

;;
;; Permission is hereby granted, free of charge, to any person obtaining a copy
;; of this software and associated documentation files (the "Software"), to deal
;; in the Software without restriction, including without limitation the rights
;; to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
;; copies of the Software, and to permit persons to whom the Software is
;; furnished to do so, subject to the following conditions:
;;
;; The above copyright notice and this permission notice shall be included in all
;; copies or substantial portions of the Software.
;;
;; THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
;; IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
;; FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
;; AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
;; LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
;; OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
;; SOFTWARE.
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
