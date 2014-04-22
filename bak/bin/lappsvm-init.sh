#!/bin/bash

export LAPPSVM_VERSION="@LAPPSVM_VERSION@"
export LAPPSVM_PLATFORM=$(uname)

if [ -z "${LAPPSVM_SERVICE}" ]; then
    export LAPPSVM_SERVICE="@LAPPSVM_SERVICE@"
fi

if [ -z "${LAPPSVM_DIR}" ]; then
	export LAPPSVM_DIR="$HOME/.lappsvm"
fi

function lappsvm_source_modules {
	# Source lappsvm module scripts.
    for f in $(find "${LAPPSVM_DIR}/src" -type f -name 'lappsvm-*' -exec basename {} \;); do
        source "${LAPPSVM_DIR}/src/${f}"
    done

	# Source extension files prefixed with 'lappsvm-' and found in the ext/ folder
	# Use this if extensions are written with the functional approach and want
	# to use functions in the main lappsvm script.
	for f in $(find "${LAPPSVM_DIR}/ext" -type f -name 'lappsvm-*' -exec basename {} \;); do
		source "${LAPPSVM_DIR}/ext/${f}"
	done
	unset f
}

function lappsvm_set_candidates {
    # Set the candidate array
    OLD_IFS="$IFS"
    IFS=","
    LAPPSVM_CANDIDATES=(${LAPPSVM_CANDIDATES_CSV})
    IFS="$OLD_IFS"
}

function lappsvm_check_offline {
    LAPPSVM_RESPONSE="$1"
	LAPPSVM_DETECT_HTML="$(echo "$LAPPSVM_RESPONSE" | tr '[:upper:]' '[:lower:]' | grep 'html')"
	if [[ -n "$LAPPSVM_DETECT_HTML" ]]; then
		echo "LAPPSVM can't reach the internet so going offline. Re-enable online with:"
		echo ""
		echo "  $ lappsvm offline disable"
		echo ""
		LAPPSVM_FORCE_OFFLINE="true"
	fi
	unset LAPPSVM_RESPONSE
	unset LAPPSVM_DETECT_HTML
}

# force zsh to behave well
if [[ -n "$ZSH_VERSION" ]]; then
	setopt shwordsplit
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

OFFLINE_BROADCAST=$( cat << EOF
==== BROADCAST =============================================

OFFLINE MODE ENABLED! Some functionality is now disabled.

============================================================
EOF
)

ONLINE_BROADCAST=$( cat << EOF
==== BROADCAST =============================================

ONLINE MODE RE-ENABLED! All functionality now restored.

============================================================
EOF
)

OFFLINE_MESSAGE="This command is not available in offline mode."

# fabricate list of candidates
if [[ -f "${LAPPSVM_DIR}/var/candidates" ]]; then
	LAPPSVM_CANDIDATES_CSV=$(cat "${LAPPSVM_DIR}/var/candidates")
else
	LAPPSVM_CANDIDATES_CSV=$(curl -s "${LAPPSVM_SERVICE}/candidates")
	echo "$LAPPSVM_CANDIDATES_CSV" > "${LAPPSVM_DIR}/var/candidates"
fi

# initialise once only
if [[ "${LAPPSVM_INIT}" == "true" ]]; then
    lappsvm_set_candidates
	lappsvm_source_modules
	return
fi

# Attempt to set JAVA_HOME if it's not already set.
if [ -z "${JAVA_HOME}" ] ; then
    if ${darwin} ; then
        [ -z "${JAVA_HOME}" -a -f "/usr/libexec/java_home" ] && export JAVA_HOME=$(/usr/libexec/java_home)
        [ -z "${JAVA_HOME}" -a -d "/Library/Java/Home" ] && export JAVA_HOME="/Library/Java/Home"
        [ -z "${JAVA_HOME}" -a -d "/System/Library/Frameworks/JavaVM.framework/Home" ] && export JAVA_HOME="/System/Library/Frameworks/JavaVM.framework/Home"
    else
        javaExecutable="$(which javac 2> /dev/null)"
        [[ -z "${javaExecutable}" ]] && echo "LAPPSVM: JAVA_HOME not set and cannot find javac to deduce location, please set JAVA_HOME." && return

        readLink="$(which readlink 2> /dev/null)"
        [[ -z "${readLink}" ]] && echo "LAPPSVM: JAVA_HOME not set and readlink not available, please set JAVA_HOME." && return

        javaExecutable="$(readlink -f "${javaExecutable}")"
        javaHome="$(dirname "${javaExecutable}")"
        javaHome=$(expr "${javaHome}" : '\(.*\)/bin')
        JAVA_HOME="${javaHome}"
        [[ -z "${JAVA_HOME}" ]] && echo "LAPPSVM: could not find java, please set JAVA_HOME" && return
        export JAVA_HOME
    fi
fi

# For Cygwin, ensure paths are in UNIX format before anything is touched.
if ${cygwin} ; then
    [ -n "${JAVACMD}" ] && JAVACMD=$(cygpath --unix "${JAVACMD}")
    [ -n "${JAVA_HOME}" ] && JAVA_HOME=$(cygpath --unix "${JAVA_HOME}")
    [ -n "${CP}" ] && CP=$(cygpath --path --unix "${CP}")
fi

# Build _HOME environment variables and prefix them all to PATH

# The candidates are assigned to an array for zsh compliance, a list of words is not iterable
# Arrays are the only way, but unfortunately zsh arrays are not backward compatible with bash
# In bash arrays are zero index based, in zsh they are 1 based(!)
lappsvm_set_candidates
if [[ -z "$ZSH_VERSION" ]]; then
	LAPPSVM_CANDIDATE_COUNT=${#LAPPSVM_CANDIDATES[@]}
else
	LAPPSVM_CANDIDATE_COUNT=${#LAPPSVM_CANDIDATES}
fi
for (( i=0; i <= ${LAPPSVM_CANDIDATE_COUNT}; i++ )); do
	# Eliminate empty entries due to incompatibility
	if [[ -n ${LAPPSVM_CANDIDATES[${i}]} ]]; then
		CANDIDATE_NAME="${LAPPSVM_CANDIDATES[${i}]}"
		CANDIDATE_HOME_VAR="$(echo ${CANDIDATE_NAME} | tr '[:lower:]' '[:upper:]')_HOME"
		CANDIDATE_DIR="${LAPPSVM_DIR}/${CANDIDATE_NAME}/current"
		export $(echo ${CANDIDATE_HOME_VAR})="$CANDIDATE_DIR"
		PATH="${CANDIDATE_DIR}/bin:${PATH}"
		unset CANDIDATE_HOME_VAR
		unset CANDIDATE_NAME
		unset CANDIDATE_DIR
	fi
done
unset i

export PATH

lappsvm_source_modules

# Load the lappsvm config if it exists.
if [ -f "${LAPPSVM_DIR}/etc/config" ]; then
	source "${LAPPSVM_DIR}/etc/config"
fi

# determine if up to date
LAPPSVM_VERSION_TOKEN="${LAPPSVM_DIR}/var/version"
if [[ -f "$LAPPSVM_VERSION_TOKEN" && -z "$(find "$LAPPSVM_VERSION_TOKEN" -mtime +1)" ]]; then
    LAPPSVM_REMOTE_VERSION=$(cat "$LAPPSVM_VERSION_TOKEN")

else
    LAPPSVM_REMOTE_VERSION=$(curl -s "${LAPPSVM_SERVICE}/app/version" -m 1)
    lappsvm_check_offline "$LAPPSVM_REMOTE_VERSION"
    if [[ -z "$LAPPSVM_REMOTE_VERSION" || "$LAPPSVM_FORCE_OFFLINE" == 'true' ]]; then
        LAPPSVM_REMOTE_VERSION="$LAPPSVM_VERSION"
    else
        echo ${LAPPSVM_REMOTE_VERSION} > "$LAPPSVM_VERSION_TOKEN"
    fi
fi

if [[ "$LAPPSVM_REMOTE_VERSION" != "$LAPPSVM_VERSION" ]]; then
    echo "A new version of LAPPSVM is available..."
    echo ""
    echo "The current version is $LAPPSVM_REMOTE_VERSION, but you have $LAPPSVM_VERSION."
    echo ""

    if [[ "$lappsvm_auto_selfupdate" != "true" ]]; then
        echo -n "Would you like to upgrade now? (Y/n)"
        read upgrade
    fi

    if [[ -z "$upgrade" ]]; then upgrade="Y"; fi

    if [[ "$upgrade" == "Y" || "$upgrade" == "y" ]]; then
        __lappsvmtool_selfupdate
        unset upgrade
    else
        echo "Not upgrading now..."
    fi
fi


export LAPPSVM_INIT="true"
