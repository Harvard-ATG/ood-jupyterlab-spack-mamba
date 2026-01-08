#!/usr/bin/env bash

this_script="template/after.sh"

log() {
    echo -e "[$(date -Iseconds)][${this_script}] $1"
}

# Wait for the Jupyter Notebook server to start
log "Waiting for Jupyter Notebook server to open port ${port}..."
log "Starting wait..."
if wait_until_port_used "${host}:${port}" 600; then
  log "Discovered Jupyter Notebook server listening on port ${port}!"
  log "Wait ended"
else
  log "Timed out waiting for Jupyter Notebook server to open port ${port}!"
  log "Wait ended at"
  pkill -P ${SCRIPT_PID}
  clean_up 1
fi
sleep 2
