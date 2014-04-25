#!/bin/bash



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

if [[ "${darwin}" == "true" ]]; then
    URL="http://softlayer-dal.dl.sourceforge.net/project/git-osx-installer/git-1.9.2-intel-universal-snow-leopard.dmg"
    hdiutil mount "${URL}"
    "/Volumes/Git 1.9.2 Snow Leopard Intel Universal"
fi