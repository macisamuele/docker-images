#!/bin/bash
set -euo pipefail -o posix -o functrace

declare -a not_executable_bash_scripts

for file in "$@"; do
    if [ ! -x "${file}" ]; then
        not_executable_bash_scripts+=("${file}")
    fi
done

if [ ${#not_executable_bash_scripts[@]} -ne 0 ]; then
    echo "The following scripts are not executable: ${not_executable_bash_scripts[*]}" > /dev/stderr
    exit 1
else
    exit 0
fi
