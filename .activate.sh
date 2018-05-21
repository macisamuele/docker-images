#!/bin/bash
if ! test -f .tox/pre-commit/bin/activate; then
    make install-hooks
fi
source .tox/pre-commit/bin/activate
