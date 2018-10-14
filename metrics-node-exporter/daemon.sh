#!/bin/sh
# Script adapted from https://github.com/fahlke/raspberrypi_exporter/
set -eu

trap 'exit 2' 2 3 6 9 15  # SIGINT SIGQUIT SIGABRT SIGKILL SIGTERM

DAEMON_INTERVAL=${DAEMON_INTERVAL:-0.5}
DAEMON_SCRIPT=${DAEMON_SCRIPT:-/code/metrics.sh}

while true; do
  echo "$(date) Running ${DAEMON_SCRIPT}" > /dev/stderr
  sh "${DAEMON_SCRIPT}"
  sleep "${DAEMON_INTERVAL}"
done
