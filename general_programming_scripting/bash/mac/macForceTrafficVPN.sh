#!/bin/sh
#usage sudo ./macForceTrafficVPN.sh test.ping.com
#usage sudo ./macForceTrafficVPN.sh domain test.ping.com
#usage sudo ./macForceTrafficVPN.sh ip 127.0.0.1

IP=""
KEY=""

process_request () {
	if [ $2 = "/32" ]
	then
		echo "Bad IP: $2"
		return;
	fi
	
	echo "Adding IP: $2 on interface $1"
	route add $2 -interface $1

}

MAINFRAMEIP=`dig +short mainframe.nerdery.com | grep -E "^([1-9][0-9]{0,2})(\.)"`

if [ "$MAINFRAMEIP" = "" ] 
then
	MAINFRAMEIP=`dig +short host ns02.nerdery.com mainframe.nerdery.com | grep -E "^([1-9][0-9]{0,2})(\.)"`
fi

if [ "$MAINFRAMEIP" = "" ] 
then
	echo "could not find mainframe IP"
	exit;
fi

INTERFACE=`route get $MAINFRAMEIP | grep interface | awk -F: '{gsub(/ /, "", $2); print $2}'`

if [ "$INTERFACE" = "" ] 
then
	echo "could not find interface"
	exit;
fi

if [ $# = 1 ]
then
	KEY="DOMAIN"
	IP="`dig +short $1 | grep -E \"^([1-9][0-9]{0,2})(\.)\"`/32"
	
	process_request $INTERFACE $IP
else
	if [ $# > 1 ]
	then	
		userKEY=$1
		case $1 in
		  [Ii][Pp]) KEY="IP";;
		  *)                 KEY="DOMAIN";;
		esac
	
		for arg in "$@"
		do
			if [ $arg != $userKEY ]
			then
				if [ $KEY = "DOMAIN" ]
				then
					IP="`dig +short $2 | grep -E \"^([1-9][0-9]{0,2})(\.)\"`/32"
				else
					IP="`echo \"$arg/32\"`"
				fi	
				process_request $INTERFACE $IP				
			fi
		done
	else
		echo "Please check the paramaters"
		exit;
	fi
fi



