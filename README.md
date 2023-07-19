# flycheck-buf-lint


## Installation

### straight-use-package

Add following code to your configuration.

```elisp
(use-package flycheck-buf-lint
  :straight (:host github :repo "shuxiao9058/flycheck-buf-lint")
  :hook ((protobuf-mode protobuf-ts-mode) .
	 (lambda()
           (flycheck-buf-lint-setup))))
```

## License

Licensed under GPLv3.
