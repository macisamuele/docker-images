# Default goals definition
.DEFAULT_GOAL := cat_this

.PHONY: cat_this
cat_this:
	echo Defult targets are not supported. This is the content of the targeted Makefile
	cat Makefile
	@false

# Functions and utilities definition

# Example of use $(call wildcard-abspath, *.txt *.md)
define wildcard-abspath
$(sort $(abspath $(wildcard $1)))
endef

ifeq ($(shell uname -s),Linux)
CPU_COUNT_COMMAND := nproc --all
else
CPU_COUNT_COMMAND := sysctl -n hw.ncpu
endif
