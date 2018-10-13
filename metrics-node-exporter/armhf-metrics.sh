#!/bin/sh
# Script adapted from https://github.com/fahlke/raspberrypi_exporter/
set -eu

VCGEN="${VCGEN:-$(command -v vcgencmd || true)}"
PREFIX="${PREFIX:-rpi_}"

if test -z "${OUTPUT_FILE}"; then
  if [ $# -eq 1 ]; then
    OUTPUT_FILE=$1
  else
    OUTPUT_FILE=""
  fi
fi

FREQ_COMPONENTS="arm core h264 isp v3d uart pwm emmc pixel vec hdmi dpi"
VOLT_COMPONENTS="core sdram_c sdram_i sdram_p"
MEM_COMPONENTS="arm gpu"

SCRIPT_PATH="$(readlink -f $0)"

get_metrics_with_prometheus_format () {

  echo "# [$(date)] Generated from ${SCRIPT_PATH}"
  # get temperatures
  echo "# HELP ${PREFIX}temperature Temperatures of the components in degree celsius."
  echo "# TYPE ${PREFIX}temperature gauge"
  for SENSOR in /sys/class/thermal/*; do
    unset CPU_TEMP_CELSIUS
    unset CPU_TYPE

    CPU_TEMP_CELSIUS="$(awk '{printf "%f", $1/1000}' "${SENSOR}/temp")" || true
    CPU_TEMP_CELSIUS="${CPU_TEMP_CELSIUS:=0}"
    CPU_TYPE="$(cat "${SENSOR}/type")"
    CPU_TYPE="${CPU_TYPE:=N/A}"
    SENSOR_NAME=${SENSOR#/sys/class/thermal/}

    echo "${PREFIX}temperature{sensor=\"${SENSOR_NAME}\",type=\"${CPU_TYPE}\"} ${CPU_TEMP_CELSIUS}"
  done

  # get component frequencies
  echo "# HELP ${PREFIX}frequency Clock frequencies of the components in hertz.";
  echo "# TYPE ${PREFIX}frequency gauge";
  for FREQ_COMPONENT in ${FREQ_COMPONENTS}; do
    unset FREQUENCE

    FREQUENCE="$($VCGEN measure_clock "${FREQ_COMPONENT}" | cut -d '=' -f 2)" || true
    FREQUENCE="${FREQUENCE:=0}"

    echo "${PREFIX}frequency{component=\"${FREQ_COMPONENT}\"} ${FREQUENCE}"
  done

  # get component voltages
  echo "# HELP ${PREFIX}voltage Voltages of the components in volts.";
  echo "# TYPE ${PREFIX}voltage gauge";
  for VOLT_COMPONENT in ${VOLT_COMPONENTS}; do
    unset VOLTS

    VOLTS="$($VCGEN measure_volts "${VOLT_COMPONENT}" | cut -d '=' -f 2 | sed 's/V$//')" || true
    VOLTS="${VOLTS:=0}"

    echo "${PREFIX}voltage{component=\"${VOLT_COMPONENT}\"} ${VOLTS}"
  done

  # get memory split of CPU vs GPU
  echo "# HELP ${PREFIX}memory Memory split of CPU and GPU in bytes.";
  echo "# TYPE ${PREFIX}memory gauge";
  for MEM_COMPONENT in ${MEM_COMPONENTS}; do
    unset MEM
    MEM="$($VCGEN get_mem "${MEM_COMPONENT}" | cut -d '=' -f 2 | sed 's/M$//')" || true
    MEM="${MEM:=0}"
    MEM="$(( MEM * 1024 * 1024 ))"
    echo "${PREFIX}memory{component=\"${MEM_COMPONENT}\"} ${MEM}"
  done
}

if test -z "${OUTPUT_FILE}"; then
  get_metrics_with_prometheus_format
else
  TMP_FILE=$(mktemp)
  chmod a+r "${TMP_FILE}"
  get_metrics_with_prometheus_format > "${TMP_FILE}"
  mv "${TMP_FILE}" "${OUTPUT_FILE}"
fi
