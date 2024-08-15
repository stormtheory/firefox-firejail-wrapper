#!/usr/bin/bash
cd "$(dirname "$0")"

# OPTIONS: 
#    force - Force deploy config files but no softlink
#    undo - Undo the softlink install
#    uninstall - Uninstalls

EXE_DIR=/sandbox
CONFIG_DIR=.

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
if [ ! -f $CONFIG_DIR/firefox-jail.py ];then
        echo "ERROR: $CONFIG_DIR/firefox-jail.py not found..."
        exit
elif [ ! -f $CONFIG_DIR/firefox.profile ];then
        echo "ERROR: $CONFIG_DIR/firefox.profile not found..."
        exit
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

function DEPLOY {
        ### Deploy scripts/config
        echo " Deploying..."
        if [ ! -d $EXE_DIR ];then
		mkdir $EXE_DIR
		chmod 755 $EXE_DIR
		chown root:root $EXE_DIR
	fi
        cp $CONFIG_DIR/firefox-jail.py $EXE_DIR
        chmod 755 $EXE_DIR/firefox-jail.py
        cp $CONFIG_DIR/firefox.profile $EXE_DIR
        cp $CONFIG_DIR/firefox-cac.profile $EXE_DIR
        chmod 644 $EXE_DIR/*.profile
        chown -R root:root $EXE_DIR
}

function LINK {
        ### Copy Firefox 'binary' to /sandbox and softlink the wrapper
        echo " Linking..."
        cp /usr/bin/firefox $EXE_DIR/firefox-bash
        chmod 755 $EXE_DIR/firefox-bash
        rm /usr/bin/firefox
        ln -s $EXE_DIR/firefox-jail.py /usr/bin/firefox
        ls -al /usr/bin/firefox
}

function UNLINK {
        echo " unLinking..."
	unlink /usr/bin/firefox
        cp $EXE_DIR/firefox-bash /usr/bin/firefox
        ls -al /usr/bin/firefox
}

function UNINSTALL {
        UNLINK
        rm -rf $EXE_DIR
}

if [ ! -z "$1" ];then
	if [ "$1" == undo ];then
		if [ -L /usr/bin/firefox ];then
			echo "linked, undo'ing, acting..."
			UNLINK
			exit
		else
        		echo "Linked all good"
		fi
		exit
	elif [ "$1" == force ];then	
		DEPLOY
	elif [ "$1" == uninstall ];then
                UNINSTALL
		exit
	fi
	exit
fi


if [ ! -L /usr/bin/firefox ];then
	echo "not linked, acting..."
	DEPLOY	
	LINK
else
	echo "Linked all good"
	echo "Use force option to force deploy"
fi

