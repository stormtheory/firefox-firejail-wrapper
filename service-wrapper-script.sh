#!/usr/bin/bash
cd "$(dirname "$0")"
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin

EXE_DIR=/sandbox
LAUNCHER_FILE=/usr/bin/firefox

### ERROR CHECKING
if [ "$USER" != root ];then
	echo "Not root"
	exit
elif echo "$EXE_DIR"|grep -iq "/[abcdefghijklmnopqrstuvwxyz0123456789]";then
        if [ -z "$EXE_DIR" ];then
                echo "ERROR"
                exit
        fi
else
        echo "DANGER!: EXE_DIR cannot be just /"
        exit
fi
if [ -f $EXE_DIR/firefox-bash ];then
	## Filename change
	mv $EXE_DIR/firefox-bash $EXE_DIR/firefox-launcher
fi
if [ -f /usr/bin/dpkg ];then
	if dpkg -l|grep -q firejail;then
        	echo ''
	else
        	echo "ERROR: Firejail is not installed!"
        	exit
	fi
elif [ -f /usr/bin/rpm ];then
	if rpm -qa|grep -q firejail;then
                echo ''
        else
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
