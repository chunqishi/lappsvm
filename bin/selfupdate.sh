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

function lappsvm_echo_debug {
	if [[ "$LAPPSVM_DEBUG_MODE" == 'true' ]]; then
		echo "$1"
	fi
}

echo ""
echo "Updating lappsvm..."

LAPPSVM_VERSION="@LAPPSVM_VERSION@"
if [ -z "${LAPPSVM_DIR}" ]; then
	LAPPSVM_DIR="$HOME/.lappsvm"
fi

# OS specific support (must be 'true' or 'false').
cygwin=false;
darwin=false;
solaris=false;
freebsd=false;
case "$(uname)" in
    CYGWIN*)
        cygwin=true
        ;;
    Darwin*)
        darwin=true
        ;;
    SunOS*)
        solaris=true
        ;;
    FreeBSD*)
        freebsd=true
esac

lappsvm_platform=$(uname)
lappsvm_bin_folder="${LAPPSVM_DIR}/bin"
lappsvm_tmp_zip="${LAPPSVM_DIR}/tmp/res-${LAPPSVM_VERSION}.zip"
lappsvm_stage_folder="${LAPPSVM_DIR}/tmp/stage"
lappsvm_src_folder="${LAPPSVM_DIR}/src"

lappsvm_echo_debug "Purge existing scripts..."
rm -rf "${lappsvm_bin_folder}"
rm -rf "${lappsvm_src_folder}"

lappsvm_echo_debug "Refresh directory structure..."
mkdir -p "${LAPPSVM_DIR}/bin"
mkdir -p "${LAPPSVM_DIR}/ext"
mkdir -p "${LAPPSVM_DIR}/etc"
mkdir -p "${LAPPSVM_DIR}/src"
mkdir -p "${LAPPSVM_DIR}/var"
mkdir -p "${LAPPSVM_DIR}/tmp"

# prepare candidates
LAPPSVM_CANDIDATES_CSV=$(curl -s "${LAPPSVM_SERVICE}/candidates")
echo "$LAPPSVM_CANDIDATES_CSV" > "${LAPPSVM_DIR}/var/candidates"

# drop version token
echo "$LAPPSVM_VERSION" > "${LAPPSVM_DIR}/var/version"

# create candidate directories
# convert csv to array
OLD_IFS="$IFS"
IFS=","
LAPPSVM_CANDIDATES=(${LAPPSVM_CANDIDATES_CSV})
IFS="$OLD_IFS"

for (( i=0; i <= ${#LAPPSVM_CANDIDATES}; i++ )); do
	# Eliminate empty entries due to incompatibility
	if [[ -n ${LAPPSVM_CANDIDATES[${i}]} ]]; then
		CANDIDATE_NAME="${LAPPSVM_CANDIDATES[${i}]}"
		mkdir -p "${LAPPSVM_DIR}/${CANDIDATE_NAME}"
		lappsvm_echo_debug "Created for ${CANDIDATE_NAME}: ${LAPPSVM_DIR}/${CANDIDATE_NAME}"
		unset CANDIDATE_NAME
	fi
done

if [[ -f "${LAPPSVM_DIR}/ext/config" ]]; then
	lappsvm_echo_debug "Removing config from ext folder..."
	rm -v "${LAPPSVM_DIR}/ext/config"
fi

lappsvm_echo_debug "Prime the config file..."
lappsvm_config_file="${LAPPSVM_DIR}/etc/config"
touch "${lappsvm_config_file}"
if [[ -z $(cat ${lappsvm_config_file} | grep 'lappsvm_auto_answer') ]]; then
	echo "lappsvm_auto_answer=false" >> "${lappsvm_config_file}"
fi

if [[ -z $(cat ${lappsvm_config_file} | grep 'lappsvm_auto_selfupdate') ]]; then
	echo "lappsvm_auto_selfupdate=false" >> "${lappsvm_config_file}"
fi

lappsvm_echo_debug "Download new scripts to: ${lappsvm_tmp_zip}"
curl -s "${LAPPSVM_SERVICE}/lappsvm/server/${lappsvm_platform}&purpose=selfupdate" > "${lappsvm_tmp_zip}"

lappsvm_echo_debug "Extract script archive..."
lappsvm_echo_debug "Unziping scripts to: ${lappsvm_stage_folder}"
if [[ "${cygwin}" == 'true' ]]; then
	lappsvm_echo_debug "Cygwin detected - normalizing paths for unzip..."
	unzip -qo $(cygpath -w "${lappsvm_tmp_zip}") -d $(cygpath -w "${lappsvm_stage_folder}")
else
	unzip -qo "${lappsvm_tmp_zip}" -d "${lappsvm_stage_folder}"
fi

lappsvm_echo_debug "Moving lappsvm-init file to bin folder..."
mv "${lappsvm_stage_folder}/lappsvm-init.sh" "${lappsvm_bin_folder}"

lappsvm_echo_debug "Move remaining module scripts to src folder: ${lappsvm_src_folder}"
mv "${lappsvm_stage_folder}"/lappsvm-* "${lappsvm_src_folder}"

lappsvm_echo_debug "Clean up staging folder..."
rm -rf "${lappsvm_stage_folder}"

echo ""
echo ""
echo "Successfully upgraded LAPPSVM."
echo ""
echo "Please open a new terminal, or run the following in the existing one:"
echo ""
echo "    source \"${LAPPSVM_DIR}/bin/lappsvm-init.sh\""
echo ""
echo ""
