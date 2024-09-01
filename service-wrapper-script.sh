#!/usr/bin/bash
cd "$(dirname "$0")"
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin

EXE_DIR=/sandbox
LAUNCHER_FILE=/usr/bin/firefox

### ERROR CHECKING
ID=$(id -u)
if [ "$ID" != 0 ];then
        echo "Not root"
        exit
fi
if [ -f /usr/bin/dpkg ];then
	dpkg -l|grep -q firejail
	if [ "$?" != 0 ];then
        	echo "ERROR: Firejail is not installed!"
        	exit
	fi
elif [ -f /usr/bin/rpm ];then
	rpm -qa|grep -q firejail
	if [ "$?" != 0 ];then
                echo "ERROR: Firejail is not installed!"
                exit
        fi
fi

function LINK {
        ### Copy Firefox 'binary' to /sandbox and softlink the wrapper
        echo " Linking..."
        grep -q 'firejail' $LAUNCHER_FILE
        if [ "$?" != 0 ];then
                cp $LAUNCHER_FILE $EXE_DIR/firefox-launcher
                chmod 755 $EXE_DIR/firefox-launcher
        fi
        rm $LAUNCHER_FILE
        ln -s $EXE_DIR/firefox-jail.py $LAUNCHER_FILE
        ls -al $LAUNCHER_FILE
}

while true;do
	if [ ! -L $LAUNCHER_FILE ];then
        	echo "not linked, acting..."
        	LINK
	fi
	sleep 90
done
