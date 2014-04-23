#!/bin/bash



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

	if [[ "$LAPPSVM_FORCE_OFFLINE" == "true" || ( "$COMMAND" == "offline" && "$QUALIFIER" == "enable" ) ]]; then
		BROADCAST_LIVE=""
	else
		BROADCAST_LIVE=$(curl -s "${LAPPSVM_SERVICE}/lappsvm/server/broadcast/${LAPPSVM_VERSION}")
		lappsvm_check_offline "$BROADCAST_LIVE"
		if [[ "$LAPPSVM_FORCE_OFFLINE" == 'true' ]]; then BROADCAST_LIVE=""; fi
	fi

    __lappsvm_log "BROADCAST_LIVE" "${BROADCAST_LIVE}" "lappsvm"
    __lappsvm_log "LAPPSVM_SERVICE" "${LAPPSVM_SERVICE}" "lappsvm"
    __lappsvm_log "LAPPSVM_VERSION" "${LAPPSVM_VERSION}" "lappsvm"
    __lappsvm_log "LAPPSVM_FORCE_OFFLINE" "${LAPPSVM_FORCE_OFFLINE}" "lappsvm"


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


    __lappsvm_log "LAPPSVM_ONLINE" "${LAPPSVM_ONLINE}"  "lappsvm"
    __lappsvm_log "LAPPSVM_AVAILABLE" "${LAPPSVM_AVAILABLE}"  "lappsvm"
    __lappsvm_log "COMMAND" "${COMMAND}"  "lappsvm"

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

    __lappsvm_log "CMD_TARGET" "${CMD_TARGET}" "lappsvm"

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


    __lappsvm_log "LAPPSVM_VALID_CANDIDATE" "${LAPPSVM_VALID_CANDIDATE}" "lappsvm"


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


    __lappsvm_log "CONVERTED_CMD_NAME" "${CONVERTED_CMD_NAME}" "lappsvm"
    __lappsvm_log "QUALIFIER" "${QUALIFIER}" "lappsvm"
}
