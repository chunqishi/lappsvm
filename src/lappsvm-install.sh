#!/bin/bash


function __lappsvmtool_download {
	CANDIDATE="$1"
	VERSION="$2"
	mkdir -p "${LAPPSVM_DIR}/archives"
	if [ ! -f "${LAPPSVM_DIR}/archives/${CANDIDATE}-${VERSION}.zip" ]; then
		echo ""
		echo "Downloading: ${CANDIDATE} ${VERSION}"
		echo ""


        # determine if up to date
        LAPPSVM_URLS="${LAPPSVM_DIR}/var/urls"
        if [[ -f "$LAPPSVM_URLS" ]]; then
            LAPPSVM_REMOTE_URLS=$(cat "$LAPPSVM_URLS")

        else
            LAPPSVM_REMOTE_URLS=$(curl -s "${LAPPSVM_SERVICE}/lappsvm/server/${LAPPSVM_VERSION}/urls" -m 1)
            echo ${LAPPSVM_REMOTE_URLS} > "$LAPPSVM_URLS"

        fi

	    __lappsvm_log "LAPPSVM_REMOTE_URLS" "${LAPPSVM_SERVICE}/lappsvm/server/${LAPPSVM_VERSION}/urls" "__lappsvmtool_download"

		DOWNLOAD_URL="${LAPPSVM_SERVICE}/lappsvm/server/download/${CANDIDATE}-${VERSION}-${LAPPSVM_PLATFORM}.zip"
        # read urls into column
        while read col1 col2 col3 col4;
        do
            if [[ "${col1}" == "${CANDIDATE}"  && "${col2}" == "${VERSION}"  && ( "${col3}" == "${LAPPSVM_PLATFORM}" || "${col3}" == "all" ) ]]; then
                DOWNLOAD_URL="${col4}"
                break
            fi
        done < "$LAPPSVM_URLS"

        __lappsvm_log "LAPPSVM_REMOTE_URLS" "${LAPPSVM_REMOTE_URLS}" "__lappsvmtool_download"
        __lappsvm_log "LAPPSVM_URLS" "${LAPPSVM_URLS}" "__lappsvmtool_download"
	    __lappsvm_log "DOWNLOAD_URL" "${DOWNLOAD_URL}" "__lappsvmtool_download"


		ZIP_ARCHIVE="${LAPPSVM_DIR}/archives/${CANDIDATE}-${VERSION}.zip"
		curl -L "${DOWNLOAD_URL}" > "${ZIP_ARCHIVE}"
		__lappsvmtool_validate_zip "${ZIP_ARCHIVE}" || return 1
	else
		echo ""
		echo "Found a previously downloaded ${CANDIDATE} ${VERSION} archive. Not downloading it again..."
		__lappsvmtool_validate_zip "${LAPPSVM_DIR}/archives/${CANDIDATE}-${VERSION}.zip" || return 1
	fi
	echo ""
}

function __lappsvmtool_validate_zip {
	ZIP_ARCHIVE="$1"
	ZIP_OK=$(unzip -t "${ZIP_ARCHIVE}" | grep 'No errors detected in compressed data')
	if [ -z "${ZIP_OK}" ]; then
		rm "${ZIP_ARCHIVE}"
		echo ""
		echo "Stop! The archive was corrupt and has been removed! Please try installing again."
		return 1
	fi
}

function __lappsvmtool_install {
	CANDIDATE="$1"
	LOCAL_FOLDER="$3"
	__lappsvmtool_check_candidate_present "${CANDIDATE}" || return 1
	__lappsvmtool_determine_version "$2" "$3" || return 1

	if [[ -d "${LAPPSVM_DIR}/${CANDIDATE}/${VERSION}" || -h "${LAPPSVM_DIR}/${CANDIDATE}/${VERSION}" ]]; then
		echo ""
		echo "Stop! ${CANDIDATE} ${VERSION} is already installed."
		return 0
	fi

    __lappsvm_log "VERSION_VALID" "${VERSION_VALID}" "__lappsvmtool_install"

	if [[ ${VERSION_VALID} == 'valid' ]]; then
		__lappsvmtool_install_candidate_version "${CANDIDATE}" "${VERSION}" || return 1

		if [[ "${lappsvm_auto_answer}" != 'true' ]]; then
			echo -n "Do you want ${CANDIDATE} ${VERSION} to be set as default? (Y/n): "
			read USE
		fi
		if [[ -z "${USE}" || "${USE}" == "y" || "${USE}" == "Y" ]]; then
			echo ""
			echo "Setting ${CANDIDATE} ${VERSION} as default."
			__lappsvmtool_link_candidate_version "${CANDIDATE}" "${VERSION}"
		fi
		return 0

	elif [[ "${VERSION_VALID}" == 'invalid' && -n "${LOCAL_FOLDER}" ]]; then
		__lappsvmtool_install_local_version "${CANDIDATE}" "${VERSION}" "${LOCAL_FOLDER}" || return 1

	elif [[ "${VERSION_VALID}" == 'script' ]]; then
		__lappsvmtool_install_script_version "${CANDIDATE}" "${VERSION}" || return 1

	elif [[ "${VERSION_VALID}" == 'tips' ]]; then
		__lappsvmtool_install_tips_version "${CANDIDATE}" "${VERSION}" || return 1

    else
        echo ""
		echo "Stop! $1 is not a valid ${CANDIDATE} version."
		return 1
	fi
}


function __lappsvmtool_install_tips_version {
	CANDIDATE="$1"
	VERSION="$2"

	# determine if up to date
    LAPPSVM_URLS="${LAPPSVM_DIR}/var/urls"
    if [[ -f "$LAPPSVM_URLS" ]]; then
        LAPPSVM_REMOTE_URLS=$(cat "$LAPPSVM_URLS")

    else
        LAPPSVM_REMOTE_URLS=$(curl -s "${LAPPSVM_SERVICE}/lappsvm/server/${LAPPSVM_VERSION}/urls" -m 1)
        echo ${LAPPSVM_REMOTE_URLS} > "$LAPPSVM_URLS"

    fi

    __lappsvm_log "LAPPSVM_REMOTE_URLS" "${LAPPSVM_SERVICE}/lappsvm/server/${LAPPSVM_VERSION}/urls" "__lappsvmtool_download"

    TIPS=""
    # read urls into column
    while read col1 col2 col3 col4;
    do
        if [[ "${col1}" == "${CANDIDATE}"  && "${col2}" == "${VERSION}"  && ( "${col3}" == "${LAPPSVM_PLATFORM}" || "${col3}" == "all" ) ]]; then
            TIPS="${col4}"
            break
        fi
    done < "$LAPPSVM_URLS"

    echo ""
    echo "----------------------- How to Installation ? ----------------------- "
    echo "To install ${CANDIDATE} ${VERSION}: "
    echo ""
    echo "${TIPS}"
    echo "--------------------------------------------------------------------- "
    echo ""
}



function __lappsvmtool_install_script_version {
	CANDIDATE="$1"
	VERSION="$2"
}


function __lappsvmtool_install_local_version {
	CANDIDATE="$1"
	VERSION="$2"
	LOCAL_FOLDER="$3"
	mkdir -p "${LAPPSVM_DIR}/${CANDIDATE}"

	echo "Linking ${CANDIDATE} ${VERSION} to ${LOCAL_FOLDER}"
	ln -s "${LOCAL_FOLDER}" "${LAPPSVM_DIR}/${CANDIDATE}/${VERSION}"
	echo "Done installing!"
	echo ""
}

function __lappsvmtool_install_candidate_version {
	CANDIDATE="$1"
	VERSION="$2"

	__lappsvm_log "CANDIDATE" "${CANDIDATE}" "__lappsvmtool_install_candidate_version"
	__lappsvm_log "VERSION" "${VERSION}" "__lappsvmtool_install_candidate_version"

	__lappsvmtool_download "${CANDIDATE}" "${VERSION}" || return 1
	echo "Installing: ${CANDIDATE} ${VERSION}"

	mkdir -p "${LAPPSVM_DIR}/${CANDIDATE}"

	unzip -oq "${LAPPSVM_DIR}/archives/${CANDIDATE}-${VERSION}.zip" -d "${LAPPSVM_DIR}/tmp/"
	mv "${LAPPSVM_DIR}"/tmp/*-${VERSION} "${LAPPSVM_DIR}/${CANDIDATE}/${VERSION}"

	sh ${LAPPSVM_DIR}/${CANDIDATE}/${VERSION}/install.sh

	echo "Done installing!"
	echo ""
}
