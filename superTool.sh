#!/bin/bash

#***************************************************
#	$ ./superTool.sh install|uninstall|update
#***************************************************

PATH_DEST="/opt"

NAME_PROGRAM="
Arachni/arachni
scrapy/dirbot
fwaeytens/dnsenum
golismero/golismero
NikolaiT/GoogleScraper
rapid7/metasploit-framework
sullo/nikto
rfunix/Pompem
smicallef/spiderfoot
sqlmapproject/sqlmap
vanhauser-thc/thc-hydra
andresriancho/w3af
anestisb/WeBaCoo
urbanadventurer/WhatWeb
wpscanteam/wpscan
epsylon/xsser
"

echo >&2
echo -e "                         _______          _ "
echo -e "                        |__   __|        | |"
echo -e "  ___ _   _ _ __   ___ _ __| | ___   ___ | |"
echo -e " / __| | | | '_ \ / _ \ '__| |/ _ \ / _ \| |"
echo -e " \__ \ |_| | |_) |  __/ |  | | (_) | (_) | |"
echo -e " |___/\__,_| .__/ \___|_|  |_|\___/ \___/|_|"
echo -e "           | |                              "
echo -e "           |_|                      v0.1    "
echo >&2
echo -e " Clona las herramientas de Seguridad y Auditoría.  "
echo >&2
echo -e " Arachni, dirbot, dnsenum, GoLismero, GoogleScraper, "
echo -e " metasploit, nikto, Pompem, spiderfoot, sqlmap, "
echo -e " thc-hydra, W3AF, WeBacoo, WhatWeb, WPScan y XSSer."
echo >&2
echo -e " Daniel Maldonado @elcodigok                "
echo >&2

if [ ! "${UID}" = 0 ]
then
	echo >&2
	echo >&2
	echo >&2 "Only user root can run superTool."
	echo >&2
	exit 1
fi

which_cmd() {
	local block=1
	if [ "a${1}" = "a-n" ]
	then
		local block=0
		shift
	fi

	unalias $2 >/dev/null 2>&1
	local cmd=`which $2 2>/dev/null | head -n 1`
	if [ $? -gt 0 -o ! -x "${cmd}" ]
	then
		if [ ${block} -eq 1 ]
		then
			echo >&2
			echo >&2 "ERROR:	Command '$2' not found in the system path."
			echo >&2
			echo >&2 "	which $2"
			exit 1
		fi
		return 1
	fi
	
	eval $1=${cmd}
	return 0
}

# Commands.
which_cmd GIT git
which_cmd AWK awk
which_cmd RM rm

repository_clone() {
	# $1 PATH_DEST
	# $2 Name Program
	# $3 GitHub
	$GIT clone git://github.com/$3.git $1/$2
}

repository_install() {
	for name in $NAME_PROGRAM
	do
            DIRECTORY=`echo $name | $AWK -F"/" '{ print $2 }'`
            repository_clone ${PATH_DEST} $DIRECTORY $name
	done
}

repository_uninstall() {
        for name in $NAME_PROGRAM
	do
            DIRECTORY=`echo $name | $AWK -F"/" '{ print $2 }'`
            if [ -d ${PATH_DEST}/$DIRECTORY ];
            then
                echo -e "Remove " $PATH_DEST/$DIRECTORY
                $RM ${PATH_DEST}/$DIRECTORY -r
            fi
	done
}

repository_update() {
        for name in $NAME_PROGRAM
	do
            DIRECTORY=`echo $name | $AWK -F"/" '{ print $2 }'`
            if [ -d $PATH_DEST/$DIRECTORY ];
            then
                cd ${PATH_DEST}/$DIRECTORY
                $GIT pull origin --verbose --progress
            fi
	done
}

case "$1" in
	install)
		repository_install
	;;

	uninstall)
                repository_uninstall
	;;

	update)
                repository_update
	;;

	*)
		echo >&2 "Usage: install|uninstall|update ."
	;;
esac

exit 0
