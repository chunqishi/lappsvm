#!/bin/bash

function __lappsvmtool_uninstall {
	CANDIDATE="$1"
	VERSION="$2"
	__lappsvmtool_check_candidate_present "${CANDIDATE}" || return 1
	__lappsvmtool_check_version_present "${VERSION}" || return 1
	CURRENT=$(readlink "${LAPPSVM_DIR}/${CANDIDATE}/current" | sed "s_${LAPPSVM_DIR}/${CANDIDATE}/__g")
	if [[ -h "${LAPPSVM_DIR}/${CANDIDATE}/current" && ( "${VERSION}" == "${CURRENT}" ) ]]; then
		echo ""
		echo "Unselecting ${CANDIDATE} ${VERSION}..."
		unlink "${LAPPSVM_DIR}/${CANDIDATE}/current"
	fi
	echo ""
	if [ -d "${LAPPSVM_DIR}/${CANDIDATE}/${VERSION}" ]; then
		echo "Uninstalling ${CANDIDATE} ${VERSION}..."
		rm -rf "${LAPPSVM_DIR}/${CANDIDATE}/${VERSION}"
	else
		echo "${CANDIDATE} ${VERSION} is not installed."
	fi
}
