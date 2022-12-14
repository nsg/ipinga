#!/bin/bash
CHECK_NAME="APT Security Updates"

set -u -o pipefail

NUM_SECURITY_UPDATES="$(apt-get upgrade -s | grep -ic security)"
DATA="updates=${NUM_SECURITY_UPDATES};0.9;5;0;${NUM_SECURITY_UPDATES}"

if [[ $NUM_SECURITY_UPDATES -gt 4 ]]; then
    STATUS=2
elif [[ $NUM_SECURITY_UPDATES -gt 0 ]]; then
    STATUS=1
else
    STATUS=0
fi

send_passive_check "$CHECK_NAME" "$STATUS" "There are $NUM_SECURITY_UPDATES security updates" "$DATA"
