#!/bin/bash



function __lappsvmtool_offline {
	if [[ "$1" == "enable" ]]; then
		LAPPSVM_FORCE_OFFLINE="true"
		echo "Forced offline mode enabled."
	fi
	if [[ "$1" == "disable" ]]; then
		LAPPSVM_FORCE_OFFLINE="false"
		LAPPSVM_ONLINE="true"
		echo "Online mode re-enabled!"
	fi
}