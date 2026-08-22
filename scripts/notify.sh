#!/usr/bin/env bash
# Desktop notification helper for detached pipeline jobs (setsid'd scripts have
# no session bus by default). Usage: notify.sh "TITLE" "BODY" [critical|normal]
export DBUS_SESSION_BUS_ADDRESS="${DBUS_SESSION_BUS_ADDRESS:-unix:path=/run/user/$(id -u)/bus}"
TITLE="${1:-Pipeline}"
BODY="${2:-done}"
URGENCY="${3:-normal}"
if command -v notify-send >/dev/null 2>&1 && notify-send -u "$URGENCY" -t 0 -a jac-pipeline "$TITLE" "$BODY" 2>/dev/null; then
  exit 0
fi
echo "[notify-fallback $(date '+%F %T')] $TITLE — $BODY" >> /tmp/jac_pipeline_notify.log
exit 0
