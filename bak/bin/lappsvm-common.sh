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


#
# common internal function definitions
#

function __lappsvmtool_check_candidate_present {
	if [ -z "$1" ]; then
		echo -e "\nNo candidate provided."
		__lappsvmtool_help
		return 1
	fi
}

function __lappsvmtool_check_version_present {
	if [ -z "$1" ]; then
		echo -e "\nNo candidate version provided."
		__lappsvmtool_help
		return 1
	fi
}

function __lappsvmtool_determine_version {
	if [[ "${LAPPSVM_AVAILABLE}" == "false" && -n "$1" && -d "${LAPPSVM_DIR}/${CANDIDATE}/$1" ]]; then
		VERSION="$1"

	elif [[ "${LAPPSVM_AVAILABLE}" == "false" && -z "$1" && -L "${LAPPSVM_DIR}/${CANDIDATE}/current" ]]; then

		VERSION=$(readlink "${LAPPSVM_DIR}/${CANDIDATE}/current" | sed "s!${LAPPSVM_DIR}/${CANDIDATE}/!!g")

	elif [[ "${LAPPSVM_AVAILABLE}" == "false" && -n "$1" ]]; then
		echo "Stop! ${CANDIDATE} ${1} is not available in offline mode."
		return 1

	elif [[ "${LAPPSVM_AVAILABLE}" == "false" && -z "$1" ]]; then
        echo "${OFFLINE_MESSAGE}"
        return 1

	elif [[ "${LAPPSVM_AVAILABLE}" == "true" && -z "$1" ]]; then
		VERSION_VALID='valid'
		VERSION=$(curl -s "${LAPPSVM_SERVICE}/candidates/${CANDIDATE}/default")

	else
		VERSION_VALID=$(curl -s "${LAPPSVM_SERVICE}/candidates/${CANDIDATE}/$1")
		if [[ "${VERSION_VALID}" == 'valid' || ( "${VERSION_VALID}" == 'invalid' && -n "$2" ) ]]; then
			VERSION="$1"

		elif [[ "${VERSION_VALID}" == 'invalid' && -h "${LAPPSVM_DIR}/${CANDIDATE}/$1" ]]; then
			VERSION="$1"

		elif [[ "${VERSION_VALID}" == 'invalid' && -d "${LAPPSVM_DIR}/${CANDIDATE}/$1" ]]; then
			VERSION="$1"

		else
			echo ""
			echo "Stop! $1 is not a valid ${CANDIDATE} version."
			return 1
		fi
	fi
}

function __lappsvmtool_default_environment_variables {

	if [ ! "$LAPPSVM_FORCE_OFFLINE" ]; then
		LAPPSVM_FORCE_OFFLINE="false"
	fi

	if [ ! "$LAPPSVM_ONLINE" ]; then
		LAPPSVM_ONLINE="true"
	fi

	if [[ "${LAPPSVM_ONLINE}" == "false" || "${LAPPSVM_FORCE_OFFLINE}" == "true" ]]; then
		LAPPSVM_AVAILABLE="false"
	else
	  	LAPPSVM_AVAILABLE="true"
	fi
}

function __lappsvmtool_link_candidate_version {
	CANDIDATE="$1"
	VERSION="$2"

	# Change the 'current' symlink for the candidate, hence affecting all shells.
	if [ -L "${LAPPSVM_DIR}/${CANDIDATE}/current" ]; then
		unlink "${LAPPSVM_DIR}/${CANDIDATE}/current"
	fi
	ln -s "${LAPPSVM_DIR}/${CANDIDATE}/${VERSION}" "${LAPPSVM_DIR}/${CANDIDATE}/current"
}