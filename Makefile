include $(CURDIR)/makefiles/docker-builder.make

.PHONY: install-hooks
install-hooks:
	tox -e pre-commit -- install -f --install-hooks
