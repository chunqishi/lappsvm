#!/bin/bash



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