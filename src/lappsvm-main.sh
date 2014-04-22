#!/bin/bash

#
#   @copyright 2014 Chunqi Shi (shicq@brandeis.edu)
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.
#

function lappsvm {

    COMMAND="$1"
    QUALIFIER="$2"

    case "$COMMAND" in
        l)
            COMMAND="list";;
        ls)
            COMMAND="list";;
        h)
            COMMAND="help";;
        v)
            COMMAND="version";;
        u)
            COMMAND="use";;
        i)
            COMMAND="install";;
        rm)
            COMMAND="uninstall";;
        c)
            COMMAND="current";;
        d)
            COMMAND="default";;
        b)
            COMMAND="broadcast";;
    esac

	#
	# Various sanity checks and default settings
	#
	__lappsvmtool_default_environment_variables

	mkdir -p "$LAPPSVM_DIR"
#    echo "lappsvm-common.sh" "$LAPPSVM_FORCE_OFFLINE" "$COMMAND" "$QUALIFIER"

	if [[ "$LAPPSVM_FORCE_OFFLINE" == "true" || ( "$COMMAND" == "offline" && "$QUALIFIER" == "enable" ) ]]; then
		BROADCAST_LIVE=""
	else
		BROADCAST_LIVE=$(curl -s "${LAPPSVM_SERVICE}/lappsvm/server/broadcast/${LAPPSVM_VERSION}")
		lappsvm_check_offline "$BROADCAST_LIVE"
		if [[ "$LAPPSVM_FORCE_OFFLINE" == 'true' ]]; then BROADCAST_LIVE=""; fi
	fi

	if [[ -z "$BROADCAST_LIVE" && "$LAPPSVM_ONLINE" == "true" && "$COMMAND" != "offline" ]]; then
		echo "$OFFLINE_BROADCAST"
	fi

	if [[ -n "$BROADCAST_LIVE" && "$LAPPSVM_ONLINE" == "false" ]]; then
		echo "$ONLINE_BROADCAST"
	fi

	if [[ -z "$BROADCAST_LIVE" ]]; then
		LAPPSVM_ONLINE="false"
		LAPPSVM_AVAILABLE="false"
	else
		LAPPSVM_ONLINE="true"
	fi

	__lappsvmtool_update_broadcast "$COMMAND"

	# Load the lappsvm config if it exists.
	if [ -f "${LAPPSVM_DIR}/etc/config" ]; then
		source "${LAPPSVM_DIR}/etc/config"
	fi

 	# no command provided
	if [[ -z "$COMMAND" ]]; then
		__lappsvmtool_help
		return 1
	fi

	# Check if it is a valid command
	CMD_FOUND=""
	CMD_TARGET="${LAPPSVM_DIR}/src/lappsvm-${COMMAND}.sh"
	if [[ -f "$CMD_TARGET" ]]; then
		CMD_FOUND="$CMD_TARGET"
	fi

	# Check if it is a sourced function
	CMD_TARGET="${LAPPSVM_DIR}/ext/lappsvm-${COMMAND}.sh"
	if [[ -f "$CMD_TARGET" ]]; then
		CMD_FOUND="$CMD_TARGET"
	fi

	# couldn't find the command
	if [[ -z "$CMD_FOUND" ]]; then
		echo "Invalid command: $COMMAND"
		__lappsvmtool_help
	fi

	# Check whether the candidate exists
	LAPPSVM_VALID_CANDIDATE=$(echo ${LAPPSVM_CANDIDATES[@]} | grep -w "$QUALIFIER")
	if [[ -n "$QUALIFIER" && "$COMMAND" != "offline" && "$COMMAND" != "flush" && "$COMMAND" != "selfupdate" && -z "$LAPPSVM_VALID_CANDIDATE" ]]; then
		echo -e "\nStop! $QUALIFIER is not a valid candidate."
		return 1
	fi
    unset LAPPSVM_VALID_CANDIDATE

	if [[ "$COMMAND" == "offline" &&  -z "$QUALIFIER" ]]; then
		echo -e "\nStop! Specify a valid offline mode."
	elif [[ "$COMMAND" == "offline" && ( -z $(echo "enable disable" | grep -w "$QUALIFIER")) ]]; then
		echo -e "\nStop! $QUALIFIER is not a valid offline mode."
	fi

	# Check whether the command exists as an internal function...
	#
	# NOTE Internal commands use underscores rather than hyphens,
	# hence the name conversion as the first step here.
	CONVERTED_CMD_NAME=$(echo "$COMMAND" | tr '-' '_')

	# Execute the requested command
	if [ -n "$CMD_FOUND" ]; then
		# It's available as a shell function
		__lappsvmtool_"$CONVERTED_CMD_NAME" "$QUALIFIER" "$3" "$4"
	fi
}
