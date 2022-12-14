#!/bin/bash
CHECK_NAME="System Load"

set -u -o pipefail

LOAD_AVG="$(awk '{ print $1 }' /proc/loadavg)"
NUM_CORES="$(nproc --all)"
NUM_CORES_2="$(( NUM_CORES / 2 ))"

DATA="load=${LOAD_AVG};$NUM_CORES_2;${NUM_CORES};0;0"

if [[ ${LOAD_AVG%.*} -gt $NUM_CORES ]]; then
    STATUS=2
elif [[ ${LOAD_AVG%.*} -gt $NUM_CORES_2 ]]; then
    STATUS=1
else
    STATUS=0
fi

send_passive_check "$CHECK_NAME" "$STATUS" "$(cat /proc/loadavg)" "$DATA"
