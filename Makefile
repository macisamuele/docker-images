.DEFAULT_GOAL := cat_this

.PHONY: cat_this
cat_this:
	echo Defult targets are not supported. This is the content of the targeted Makefile
	cat Makefile
	@false

.PHONY: install-hooks
install-hooks:
	tox -e pre-commit -- install -f --install-hooks
