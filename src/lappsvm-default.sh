#!/bin/bash

function __lappsvmtool_default {
	CANDIDATE="$1"
	__lappsvmtool_check_candidate_present "${CANDIDATE}" || return 1
	__lappsvmtool_determine_version "$2" || return 1

	if [ ! -d "${LAPPSVM_DIR}/${CANDIDATE}/${VERSION}" ]; then
		echo ""
		echo "Stop! ${CANDIDATE} ${VERSION} is not installed."
		return 1
	fi

	__lappsvmtool_link_candidate_version "${CANDIDATE}" "${VERSION}"

	echo ""
	echo "Default ${CANDIDATE} version set to ${VERSION}"
}
