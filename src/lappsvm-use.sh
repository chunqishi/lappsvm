#!/bin/bash


function __lappsvmtool_use {
	CANDIDATE="$1"
	__lappsvmtool_check_candidate_present "${CANDIDATE}" || return 1
	__lappsvmtool_determine_version "$2" || return 1

	if [[ ! -d "${LAPPSVM_DIR}/${CANDIDATE}/${VERSION}" ]]; then
		echo ""
		echo "Stop! ${CANDIDATE} ${VERSION} is not installed."
		if [[ "${lappsvm_auto_answer}" != 'true' ]]; then
			echo -n "Do you want to install it now? (Y/n): "
			read INSTALL
		fi
		if [[ -z "${INSTALL}" || "${INSTALL}" == "y" || "${INSTALL}" == "Y" ]]; then
			__lappsvmtool_install_candidate_version "${CANDIDATE}" "${VERSION}"
		else
			return 1
		fi
	fi

	# Just update the *_HOME and PATH for this shell.
	UPPER_CANDIDATE=$(echo "${CANDIDATE}" | tr '[:lower:]' '[:upper:]')
	export "${UPPER_CANDIDATE}_HOME"="${LAPPSVM_DIR}/${CANDIDATE}/${VERSION}"

	# Replace the current path for the candidate with the selected version.
	if [[ "${solaris}" == true ]]; then
		export PATH=$(echo $PATH | gsed -r "s!${LAPPSVM_DIR}/${CANDIDATE}/([^/]+)!${LAPPSVM_DIR}/${CANDIDATE}/${VERSION}!g")

	elif [[ "${darwin}" == true ]]; then
		export PATH=$(echo $PATH | sed -E "s!${LAPPSVM_DIR}/${CANDIDATE}/([^/]+)!${LAPPSVM_DIR}/${CANDIDATE}/${VERSION}!g")

	else
		export PATH=$(echo $PATH | sed -r "s!${LAPPSVM_DIR}/${CANDIDATE}/([^/]+)!${LAPPSVM_DIR}/${CANDIDATE}/${VERSION}!g")
	fi

	echo ""
	echo Using "${CANDIDATE}" version "${VERSION} in this shell."
}
