#!/bin/sh
#usage sudo ./ubuntuForceTrafficVPN.sh test.ping.com
#usage sudo ./ubuntuForceTrafficVPN.sh domain test.ping.com
#usage sudo ./ubuntuForceTrafficVPN.sh ip 127.0.0.1

IP=""
KEY=""
userKEY=""

process_request () {
	if [ $2 = "/32" ]
	then
		echo "Bad IP: $2"
		return;
	fi
	
	echo "Adding IP: $2 on interface $1"
	ip route add $2 via 0.0.0.0 dev $1

}

MAINFRAMEIP=`dig +short mainframe.nerdery.com | egrep "^([1-9][0-9]{0,2})(\.)"`

if [ "$MAINFRAMEIP" = "" ] 
then
	MAINFRAMEIP=`dig +short host ns02.nerdery.com mainframe.nerdery.com | egrep "^([1-9][0-9]{0,2})(\.)"`
fi

if [ "$MAINFRAMEIP" = "" ] 
then
	echo "could not find mainframe IP"
	exit;
fi

INTERFACE=`route | grep $MAINFRAMEIP | awk '{print $8}'`

if [ "$INTERFACE" = "" ] 
then
	echo "could not find interface"
	exit;
fi

if [ $# = 1 ]
then
	KEY="DOMAIN"
	IP="`dig +short $1 | egrep \"^([1-9][0-9]{0,2})(\.)\"`/32"
	
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
					IP="`dig +short $arg | egrep \"^([1-9][0-9]{0,2})(\.)\"`/32"
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

