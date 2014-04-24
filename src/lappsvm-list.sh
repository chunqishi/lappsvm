#!/bin/bash



function __lappsvmtool_build_version_csv {
	CANDIDATE="$1"
	CSV=""
	for version in $(find "${LAPPSVM_DIR}/${CANDIDATE}" -maxdepth 1 -mindepth 1 -exec basename '{}' \; | sort); do
		if [[ "${version}" != 'current' ]]; then
			CSV="${version},${CSV}"
		fi
	done
	CSV=${CSV%?}
}

function __lappsvmtool_offline_list {
	echo "------------------------------------------------------------"
	echo "Offline Mode: only showing installed ${CANDIDATE} versions"
	echo "------------------------------------------------------------"
	echo "                                                            "

	lappsvm_versions=($(echo ${CSV//,/ }))
	for (( i=0 ; i <= ${#lappsvm_versions} ; i++ )); do
		if [[ -n "${lappsvm_versions[${i}]}" ]]; then
			if [[ "${lappsvm_versions[${i}]}" == "${CURRENT}" ]]; then
				echo -e " > ${lappsvm_versions[${i}]}"
			else
				echo -e " * ${lappsvm_versions[${i}]}"
			fi
		fi
	done

	if [[ -z "${lappsvm_versions[@]}" ]]; then
		echo "   None installed!"
	fi

	echo "------------------------------------------------------------"
	echo "* - installed                                               "
	echo "> - currently in use                                        "
	echo "------------------------------------------------------------"

	unset CSV lappsvm_versions
}

function __lappsvmtool_list {
	CANDIDATE="$1"
	__lappsvmtool_check_candidate_present "${CANDIDATE}" || return 1
	__lappsvmtool_build_version_csv "${CANDIDATE}"
	__lappsvmtool_determine_current_version "${CANDIDATE}"

	if [[ "${LAPPSVM_AVAILABLE}" == "false" ]]; then
		__lappsvmtool_offline_list
	else

#		FRAGMENT=$(curl -s "${LAPPSVM_SERVICE}/candidates/${CANDIDATE}/list?platform=${LAPPSVM_PLATFORM}&current=${CURRENT}&installed=${CSV}")
#        FRAGMENT=$(curl -s "${LAPPSVM_SERVICE}/lappsvm/server/${CANDIDATE}")
        FRAGMENT=$( cat <<EOF
================================================================================
Installed ${CANDIDATE} Versions
================================================================================
     * ${CSV}
     > ${CURRENT}

================================================================================
+ - local version
* - installed
> - currently in use
================================================================================
EOF
)

		__lappsvm_log "FRAGMENT" "${FRAGMENT}" "__lappsvmtool_list"

		echo "${FRAGMENT}"
		unset FRAGMENT
	fi
}
