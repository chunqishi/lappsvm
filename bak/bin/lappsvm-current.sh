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

function __lappsvmtool_determine_current_version {
	CANDIDATE="$1"
	if [[ "${solaris}" == true ]]; then
		CURRENT=$(echo $PATH | gsed -r "s|.lappsvm/${CANDIDATE}/([^/]+)/bin|!!\1!!|1" | gsed -r "s|^.*!!(.+)!!.*$|\1|g")
	elif [[ "${darwin}" == true ]]; then
		CURRENT=$(echo $PATH | sed -E "s|.lappsvm/${CANDIDATE}/([^/]+)/bin|!!\1!!|1" | sed -E "s|^.*!!(.+)!!.*$|\1|g")
	else
		CURRENT=$(echo $PATH | sed -r "s|.lappsvm/${CANDIDATE}/([^/]+)/bin|!!\1!!|1" | sed -r "s|^.*!!(.+)!!.*$|\1|g")
	fi

	if [[ "${CURRENT}" == "current" ]]; then
	    unset CURRENT
	fi

	if [[ -z ${CURRENT} ]]; then
		CURRENT=$(readlink "${LAPPSVM_DIR}/${CANDIDATE}/current" | sed "s!${LAPPSVM_DIR}/${CANDIDATE}/!!g")
	fi
}

function __lappsvmtool_current {
	if [ -n "$1" ]; then
		CANDIDATE="$1"
		__lappsvmtool_determine_current_version "${CANDIDATE}"
		if [ -n "${CURRENT}" ]; then
			echo "Using ${CANDIDATE} version ${CURRENT}"
		else
			echo "Not using any version of ${CANDIDATE}"
		fi
	else
		INSTALLED_COUNT=0
		for (( i=0; i <= ${LAPPSVM_CANDIDATE_COUNT}; i++ )); do
			# Eliminate empty entries due to incompatibility
			if [[ -n ${LAPPSVM_CANDIDATES[${i}]} ]]; then
				__lappsvmtool_determine_current_version "${LAPPSVM_CANDIDATES[${i}]}"
				if [ -n "${CURRENT}" ]; then
					if [ ${INSTALLED_COUNT} -eq 0 ]; then
						echo 'Using:'
					fi
					echo "${LAPPSVM_CANDIDATES[${i}]}: ${CURRENT}"
					(( INSTALLED_COUNT += 1 ))
				fi
			fi
		done
		if [ ${INSTALLED_COUNT} -eq 0 ]; then
			echo 'No candidates are in use'
		fi
	fi
}
