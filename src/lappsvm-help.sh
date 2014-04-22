#!/bin/bash



function __lappsvmtool_help {
	echo ""
	echo "Usage: lappsvm <command> <candidate> [version]"
	echo "       lappsvm offline <enable|disable>"
	echo ""
	echo "   commands:"
	echo "       install   or i    <candidate> [version]"
	echo "       uninstall or rm   <candidate> <version>"
	echo "       list      or ls   <candidate>"
	echo "       use       or u    <candidate> [version]"
	echo "       default   or d    <candidate> [version]"
	echo "       current   or c    [candidate]"
	echo "       version   or v"
	echo "       broadcast or b"
	echo "       help      or h"
	echo "       offline           <enable|disable>"
	echo "       selfupdate        [force]"
	echo "       flush             <candidates|broadcast|archives|temp>"
	echo ""
	echo -n "   candidate  :  "
	echo "$LAPPSVM_CANDIDATES_CSV" | sed 's/,/, /g'
	echo "   version    :  where optional, defaults to latest stable if not provided"
	echo ""
	echo "eg: lappsvm install maven"
}
