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

# Global variables
LAPPSVM_SERVICE="@LAPPSVM_SERVICE@"
LAPPSVM_VERSION="@LAPPSVM_VERSION@"
LAPPSVM_DIR="$HOME/.lappsvm"

# Local variables
lappsvm_bin_folder="${LAPPSVM_DIR}/bin"
lappsvm_src_folder="${LAPPSVM_DIR}/src"
lappsvm_tmp_folder="${LAPPSVM_DIR}/tmp"
lappsvm_stage_folder="${lappsvm_tmp_folder}/stage"
lappsvm_zip_file="${lappsvm_tmp_folder}/res-${LAPPSVM_VERSION}.zip"
lappsvm_ext_folder="${LAPPSVM_DIR}/ext"
lappsvm_etc_folder="${LAPPSVM_DIR}/etc"
lappsvm_var_folder="${LAPPSVM_DIR}/var"
lappsvm_config_file="${lappsvm_etc_folder}/config"
lappsvm_bash_profile="${HOME}/.bash_profile"
lappsvm_profile="${HOME}/.profile"
lappsvm_bashrc="${HOME}/.bashrc"
lappsvm_zshrc="${HOME}/.zshrc"
lappsvm_platform=$(uname)

lappsvm_init_snippet=$( cat << EOF
#THIS MUST BE AT THE END OF THE FILE FOR LAPPSVM TO WORK!!!
[[ -s "${LAPPSVM_DIR}/bin/lappsvm-init.sh" ]] && source "${LAPPSVM_DIR}/bin/lappsvm-init.sh"
EOF
)

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

echo '                                                                     '
echo 'Thanks for using Lapps Version Manager!                              '
echo '                                                                     '
echo '                                                                     '
echo 'Will now attempt installing...                                       '
echo '                                                                     '

# Sanity checks

echo "Looking for a previous installation of LAPPSVM..."
if [ -d "${LAPPSVM_DIR}" ]; then
	echo "LAPPSVM found."
	echo ""
	echo "======================================================================================================"
	echo " You already have LAPPSVM installed."
	echo " LAPPSVM was found at:"
	echo ""
	echo "    ${LAPPSVM_DIR}"
	echo ""
	echo " Please consider running the following if you need to upgrade."
	echo ""
	echo "    $ lappsvm selfupdate"
	echo ""
	echo "======================================================================================================"
	echo ""
	exit 0
fi

echo "Looking for unzip..."
if [ -z $(which unzip) ]; then
	echo "Not found."
	echo "======================================================================================================"
	echo " Please install unzip on your system using your favourite package manager."
	echo ""
	echo " Restart after installing unzip."
	echo "======================================================================================================"
	echo ""
	exit 0
fi

echo "Looking for curl..."
if [ -z $(which curl) ]; then
	echo "Not found."
	echo ""
	echo "======================================================================================================"
	echo " Please install curl on your system using your favourite package manager."
	echo ""
	echo " LAPPSVM uses curl for crucial interactions with it's backend server."
	echo ""
	echo " Restart after installing curl."
	echo "======================================================================================================"
	echo ""
	exit 0
fi

echo "Looking for sed..."
if [ -z $(which sed) ]; then
	echo "Not found."
	echo ""
	echo "======================================================================================================"
	echo " Please install sed on your system using your favourite package manager."
	echo ""
	echo " LAPPSVM uses sed extensively."
	echo ""
	echo " Restart after installing sed."
	echo "======================================================================================================"
	echo ""
	exit 0
fi

if [[ "${solaris}" == true ]]; then
	echo "Looking for gsed..."
	if [ -z $(which gsed) ]; then
		echo "Not found."
		echo ""
		echo "======================================================================================================"
		echo " Please install gsed on your solaris system."
		echo ""
		echo " LAPPSVM uses gsed extensively."
		echo ""
		echo " Restart after installing gsed."
		echo "======================================================================================================"
		echo ""
		exit 0
	fi
fi


echo "Installing lappsvm scripts..."


# Create directory structure

echo "Create distribution directories..."
mkdir -p "${lappsvm_bin_folder}"
mkdir -p "${lappsvm_src_folder}"
mkdir -p "${lappsvm_tmp_folder}"
mkdir -p "${lappsvm_stage_folder}"
mkdir -p "${lappsvm_ext_folder}"
mkdir -p "${lappsvm_etc_folder}"
mkdir -p "${lappsvm_var_folder}"

echo "Create candidate directories..."

LAPPSVM_CANDIDATES_CSV=$(curl -s "${LAPPSVM_SERVICE}/candidates")
echo "$LAPPSVM_CANDIDATES_CSV" > "${LAPPSVM_DIR}/var/candidates"

echo "$LAPPSVM_VERSION" > "${LAPPSVM_DIR}/var/version"

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
		echo "Created for ${CANDIDATE_NAME}: ${LAPPSVM_DIR}/${CANDIDATE_NAME}"
		unset CANDIDATE_NAME
	fi
done

echo "Prime the config file..."
touch "${lappsvm_config_file}"
echo "lappsvm_auto_answer=false" >> "${lappsvm_config_file}"
echo "lappsvm_auto_selfupdate=false" >> "${lappsvm_config_file}"

echo "Download script archive..."
curl -s "${LAPPSVM_SERVICE}/res?platform=${lappsvm_platform}&purpose=install" > "${lappsvm_zip_file}"

echo "Extract script archive..."
if [[ "${cygwin}" == 'true' ]]; then
	echo "Cygwin detected - normalizing paths for unzip..."
	lappsvm_zip_file=$(cygpath -w "${lappsvm_zip_file}")
	lappsvm_stage_folder=$(cygpath -w "${lappsvm_stage_folder}")
fi
unzip -qo "${lappsvm_zip_file}" -d "${lappsvm_stage_folder}"

echo "Install scripts..."
mv "${lappsvm_stage_folder}/lappsvm-init.sh" "${lappsvm_bin_folder}"
mv "${lappsvm_stage_folder}"/lappsvm-* "${lappsvm_src_folder}"

echo "Attempt update of bash profiles..."
if [ ! -f "${lappsvm_bash_profile}" -a ! -f "${lappsvm_profile}" ]; then
	echo "#!/bin/bash" > "${lappsvm_bash_profile}"
	echo "${lappsvm_init_snippet}" >> "${lappsvm_bash_profile}"
	echo "Created and initialised ${lappsvm_bash_profile}"
else
	if [ -f "${lappsvm_bash_profile}" ]; then
		if [[ -z `grep 'lappsvm-init.sh' "${lappsvm_bash_profile}"` ]]; then
			echo -e "\n${lappsvm_init_snippet}" >> "${lappsvm_bash_profile}"
			echo "Updated existing ${lappsvm_bash_profile}"
		fi
	fi

	if [ -f "${lappsvm_profile}" ]; then
		if [[ -z `grep 'lappsvm-init.sh' "${lappsvm_profile}"` ]]; then
			echo -e "\n${lappsvm_init_snippet}" >> "${lappsvm_profile}"
			echo "Updated existing ${lappsvm_profile}"
		fi
	fi
fi

if [ ! -f "${lappsvm_bashrc}" ]; then
	echo "#!/bin/bash" > "${lappsvm_bashrc}"
	echo "${lappsvm_init_snippet}" >> "${lappsvm_bashrc}"
	echo "Created and initialised ${lappsvm_bashrc}"
else
	if [[ -z `grep 'lappsvm-init.sh' "${lappsvm_bashrc}"` ]]; then
		echo -e "\n${lappsvm_init_snippet}" >> "${lappsvm_bashrc}"
		echo "Updated existing ${lappsvm_bashrc}"
	fi
fi

echo "Attempt update of zsh profiles..."
if [ ! -f "${lappsvm_zshrc}" ]; then
	echo "${lappsvm_init_snippet}" >> "${lappsvm_zshrc}"
	echo "Created and initialised ${lappsvm_zshrc}"
else
	if [[ -z `grep 'lappsvm-init.sh' "${lappsvm_zshrc}"` ]]; then
		echo -e "\n${lappsvm_init_snippet}" >> "${lappsvm_zshrc}"
		echo "Updated existing ${lappsvm_zshrc}"
	fi
fi

echo -e "\n\n\nAll done!\n\n"

echo "Please open a new terminal, or run the following in the existing one:"
echo ""
echo "    source \"${LAPPSVM_DIR}/bin/lappsvm-init.sh\""
echo ""
echo "Then issue the following command:"
echo ""
echo "    lappsvm help"
echo ""
echo "Enjoy!!!"
