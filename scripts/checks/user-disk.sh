#!/bin/bash
CHECK_NAME="Passive Disk Usage"

set -u -o pipefail

FILESYSTEMS="$(df -h --output=source --local --exclude-type=tmpfs | grep -v Filesystem)"
DATA=""

for SOURCE in $FILESYSTEMS; do
    SIZE=$(df -k --output=size --local --exclude-type=tmpfs "$SOURCE" | tail -1 | tr -d ' ')
    USED=$(df -k --output=used --local --exclude-type=tmpfs "$SOURCE" | tail -1 | tr -d ' ')

    if [[ $SIZE -gt 10048576 ]]; then
        WARN=$(( SIZE - $(( 512 * 1024 )) ))
        CRIT=$(( SIZE - $(( 128 * 1024 )) ))
    else
        WARN=$(( SIZE - $(( SIZE / 10 )) ))
        CRIT=$(( SIZE - $(( SIZE / 20 )) ))
    fi

    DATA="$DATA ${SOURCE##*/}=${USED}KiB;${WARN};${CRIT};0;${SIZE}"
done

send_passive_check "$CHECK_NAME" 0 "A disk is there" "$DATA"
