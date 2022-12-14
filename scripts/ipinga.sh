#!/bin/bash

getconf() {
  awk "/^$1/{print \$NF}" ${CREDENTIALS_DIRECTORY:-"/etc"}/ipinga.conf
}

API_USER="$(getconf api-user)"
API_PASS="$(getconf api-pass)"
HOST_NAME="$(getconf check-hostname)"
ICINGA_HOST="$(getconf icinga-host)"

send_passive_check() {
  local check_name="$1"
  local check_exit_status="$2"
  local check_output="$3"
  local check_performance_data="$4"

  local str_performance_data=""
  for performance_data in $check_performance_data; do
    if [ -z $str_performance_data ]; then
      str_performance_data="\"$performance_data\""
    else
      str_performance_data="$str_performance_data,\"$performance_data\""
    fi
  done

  local req_status=$(curl -ksSu "$API_USER:$API_PASS" -H 'Accept: application/json' \
    -d '{
      "type": "Service",
      "filter": "host.name==\"'$HOST_NAME'\" && service.name==\"'"$check_name"'\"",
      "exit_status": '$check_exit_status',
      "plugin_output": "'"$check_output"'",
      "performance_data": [ '$str_performance_data' ],
      "pretty": true
    }' \
    "${ICINGA_HOST}/v1/actions/process-check-result" \
    | jq '.results[].code')

  NUM_TO_SEND_CHECKS=$(( $NUM_TO_SEND_CHECKS + 1 ))
}

for check in /opt/ipinga/checks/*.sh; do
  sha256sum $check >> /tmp/check-startup-hashes
done

while [ 1 ]; do
  NUM_TO_SEND_CHECKS=0

  if ! sha256sum --status -c /tmp/check-startup-hashes; then
    echo "Something is fishy, abort!"
    sha256sum -c /tmp/check-startup-hashes

    send_passive_check "Passive Ping" 2 "Check script - checksum missmatch" "checks=$NUM_TO_SEND_CHECKS;"
  else

    if [ $UID -eq 0 ]; then
      # Trigger various passive checks as root
      for check in /opt/ipinga/checks/root-*.sh; do
        [ -e "$check" ] && . $check
      done
    else
      # Trigger various passive checks as user
      for check in /opt/ipinga/checks/user-*.sh; do
        [ -e "$check" ] && . $check
      done
    fi

    send_passive_check "Passive Ping" 0 "Checks executed" "checks=$NUM_TO_SEND_CHECKS;"
  fi

  sleep 10
done
