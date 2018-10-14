#!/bin/bash
set -eu

PREFIX="${PREFIX:-amd64_}"

if test -z "${OUTPUT_FILE}"; then
  if [ $# -eq 1 ]; then
    OUTPUT_FILE=$1
  else
    OUTPUT_FILE=""
  fi
fi

SCRIPT_PATH="$(readlink -f $0)"

get_metrics_with_prometheus_format() {
  echo "# [$(date)] Generated from ${SCRIPT_PATH}"
  echo "${PREFIX}example{component=\"none\"} 10"
}

if test -z "${OUTPUT_FILE}"; then
  get_metrics_with_prometheus_format
else
  TMP_FILE=$(mktemp)
  chmod a+r "${TMP_FILE}"
  get_metrics_with_prometheus_format > "${TMP_FILE}"
  mv "${TMP_FILE}" "${OUTPUT_FILE}"
fi
