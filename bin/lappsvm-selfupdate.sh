#!/bin/bash

#
#   Copyright 2012 Marco Vermeulen
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

function __lappsvmtool_selfupdate {
    LAPPSVM_FORCE_SELFUPDATE="$1"
	if [[ "$LAPPSVM_AVAILABLE" == "false" ]]; then
		echo "$OFFLINE_MESSAGE"

	elif [[ "$LAPPSVM_REMOTE_VERSION" == "$LAPPSVM_VERSION" && "$LAPPSVM_FORCE_SELFUPDATE" != "force" ]]; then
		echo "No update available at this time."

	else
		curl -s "${LAPPSVM_SERVICE}/selfupdate" | bash
	fi
	unset LAPPSVM_FORCE_SELFUPDATE
}
