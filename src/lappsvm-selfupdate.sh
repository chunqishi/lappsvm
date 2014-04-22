#!/bin/bash



function __lappsvmtool_selfupdate {
    LAPPSVM_FORCE_SELFUPDATE="$1"
	if [[ "$LAPPSVM_AVAILABLE" == "false" ]]; then
		echo "$OFFLINE_MESSAGE"

	elif [[ "$LAPPSVM_REMOTE_VERSION" == "$LAPPSVM_VERSION" && "$LAPPSVM_FORCE_SELFUPDATE" != "force" ]]; then
		echo "No update available at this time."

	else
		curl -s "${LAPPSVM_SERVICE}/selfupdate" | bash
	fi
	unset LAPPSVM_FORCE_SELFUPDATE
}
