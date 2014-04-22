#!/bin/bash

function __lappsvmtool_broadcast {
	if [ "${BROADCAST_HIST}" ]; then
		echo "${BROADCAST_HIST}"
	else
		echo "${BROADCAST_LIVE}"
	fi
}

function __lappsvmtool_update_broadcast {
	COMMAND="$1"
	BROADCAST_FILE="${LAPPSVM_DIR}/var/broadcast"
	if [ -f "${BROADCAST_FILE}" ]; then
		BROADCAST_HIST=$(cat "${BROADCAST_FILE}")
	fi

	if [[ "${LAPPSVM_AVAILABLE}" == "true" && "${BROADCAST_LIVE}" != "${BROADCAST_HIST}" && "$COMMAND" != "broadcast" && "$COMMAND" != "selfupdate" && "$COMMAND" != "flush" ]]; then
		mkdir -p "${LAPPSVM_DIR}/var"
		echo "${BROADCAST_LIVE}" > "${BROADCAST_FILE}"
		echo "${BROADCAST_LIVE}"
	fi
}
