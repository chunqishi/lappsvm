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

function __lappsvmtool_cleanup_folder {
	LAPPSVM_CLEANUP_DIR="${LAPPSVM_DIR}/${1}"
	LAPPSVM_CLEANUP_DU=$(du -sh "$LAPPSVM_CLEANUP_DIR")
	LAPPSVM_CLEANUP_COUNT=$(ls -1 "$LAPPSVM_CLEANUP_DIR" | wc -l)

	rm -rf "${LAPPSVM_DIR}/${1}"
	mkdir "${LAPPSVM_DIR}/${1}"

	echo "${LAPPSVM_CLEANUP_COUNT} archive(s) flushed, freeing ${LAPPSVM_CLEANUP_DU}."

	unset LAPPSVM_CLEANUP_DIR
	unset LAPPSVM_CLEANUP_DU
	unset LAPPSVM_CLEANUP_COUNT
}

function __lappsvmtool_flush {
	QUALIFIER="$1"
	case "$QUALIFIER" in
		candidates)
			if [[ -f "${LAPPSVM_DIR}/var/candidates" ]]; then
		        rm "${LAPPSVM_DIR}/var/candidates"
		        echo "Candidates have been flushed."
		    else
		        echo "No candidate list found so not flushed."
		    fi
		    ;;
		broadcast)
			if [[ -f "${LAPPSVM_DIR}/var/broadcast" ]]; then
		        rm "${LAPPSVM_DIR}/var/broadcast"
		        echo "Broadcast has been flushed."
		    else
		        echo "No prior broadcast found so not flushed."
		    fi
		    ;;
		version)
			if [[ -f "${LAPPSVM_DIR}/var/version" ]]; then
		        rm "${LAPPSVM_DIR}/var/version"
		        echo "Version Token has been flushed."
		    else
		        echo "No prior Remote Version found so not flushed."
		    fi
		    ;;
		archives)
			__lappsvmtool_cleanup_folder "archives"
		    ;;
		temp)
			__lappsvmtool_cleanup_folder "tmp"
		    ;;
		tmp)
			__lappsvmtool_cleanup_folder "tmp"
		    ;;
		*)
			echo "Stop! Please specify what you want to flush."
			;;
	esac
}