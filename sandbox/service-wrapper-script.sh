#!/usr/bin/bash
cd "$(dirname "$0")"
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin

EXE_DIR=/sandbox
SANDBOX_APP=firefox-jail.py
SANDBOX_APP_LAUNCHER=firefox-launcher

################# ERROR CHECKING
if [ -f /usr/bin/dpkg ];then
	echo "Ubuntu"
	dpkg -l|grep -q firejail
	if [ "$?" != 0 ];then
        	echo "ERROR: Firejail is not installed!"
        	exit
	else
		LAUNCHER_FILE=/usr/bin/firefox
	fi
elif [ -f /usr/bin/rpm ];then
	echo "RHEL"
	rpm -qa|grep -q firejail
	if [ "$?" != 0 ];then
                echo "ERROR: Firejail is not installed!"
                exit
	else
		LAUNCHER_FILE=
        fi
else
	LAUNCHER_FILE=$(whereis firefox|awk '{print $2}')
fi

if [ ! -f "$SANDBOX_APP" ];then
	echo "ERROR: $SANDBOX_APP was not found!"
        exit
fi

echo "$LAUNCHER_FILE"

ID=$(id -u)
if [ "$ID" != 0 ];then
        echo "Not root"
        exit
fi

################### MEAT

function LINK {
        ### Copy Firefox 'bash/binary' to /sandbox and softlink the wrapper
        echo " Linking..."
        if [ -f "$EXE_DIR/$SANDBOX_APP" ];then

		grep -q 'firejail' $LAUNCHER_FILE
        	if [ "$?" != 0 ];then
                	cp $LAUNCHER_FILE $EXE_DIR/$SANDBOX_APP_LAUNCHER
                	chmod 755 $EXE_DIR/$SANDBOX_APP_LAUNCHER
        	fi
        	rm $LAUNCHER_FILE
        	ln -s $EXE_DIR/$SANDBOX_APP $LAUNCHER_FILE
        	ls -al $LAUNCHER_FILE
	else
		echo "ERROR: $EXE_DIR/$SANDBOX_APP was not found..."
		exit 1
	fi
}

################## LOOP
while true;do
	if [ ! -L $LAUNCHER_FILE ];then
        	echo "not linked, acting..."
        	LINK
	fi
	sleep 90
done
