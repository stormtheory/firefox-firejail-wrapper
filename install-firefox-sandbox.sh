#!/usr/bin/bash
cd "$(dirname "$0")"
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin

# OPTIONS: 
#    force - Force deploy config files but no softlink
#    reinstall - Force deploy config files
#    undo - Undo the softlink install
#    uninstall - Uninstalls

EXE_DIR=/sandbox
CONFIG_DIR=.
LAUNCHER_FILE=/usr/bin/firefox
SERVICE_NAME=wrapper-firefox.service

### ERROR CHECKING
ID=$(id -u)
if [ "$ID" != 0 ];then
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
if [ -f $EXE_DIR/firefox-bash ];then
	## Filename change
	mv $EXE_DIR/firefox-bash $EXE_DIR/firefox-launcher
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

function DEPLOY {
        ### Deploy scripts/config
        echo " Deploying..."
        if [ ! -d $EXE_DIR ];then
		mkdir $EXE_DIR
		chmod 755 $EXE_DIR
		chown root:root $EXE_DIR
	fi
	if [ ! -f $EXE_DIR/configJailFirefox.py ];then
		cp $CONFIG_DIR/configJailFirefox.py $EXE_DIR
		chmod 644 $EXE_DIR/configJailFirefox.py
	elif [ -f $EXE_DIR/configJailFirefox.py ];then
                grep -q 'USE_WITHIN_ANOTHER_FIREJAIL_SANDBOX' $EXE_DIR/configJailFirefox.py
                if [ "$?" != 0 ];then
                echo "Updating config file #1..." >> $EXE_DIR/configJailFirefox.py
                echo "# Other options:" >> $EXE_DIR/configJailFirefox.py
                echo "## true/false" >> $EXE_DIR/configJailFirefox.py
                echo "USE_WITHIN_ANOTHER_FIREJAIL_SANDBOX = 'false'" >> $EXE_DIR/configJailFirefox.py
	else
		echo "Config file $EXE_DIR/configJailFirefox.py already installed... skipping"
	fi

        cp $CONFIG_DIR/firefox-jail.py $EXE_DIR
        chmod 755 $EXE_DIR/firefox-jail.py
        cp $CONFIG_DIR/firefox.profile $EXE_DIR
        cp $CONFIG_DIR/firefox-cac.profile $EXE_DIR
	cp $CONFIG_DIR/firefox-drm.profile $EXE_DIR
	cp $CONFIG_DIR/service-wrapper-script.sh $EXE_DIR
        chmod 644 $EXE_DIR/*.profile
	chmod 700 $EXE_DIR/service-wrapper-script.sh
        chown -R root:root $EXE_DIR

	## Deploy Service
	if [ ! -f /etc/systemd/system/$SERVICE_NAME ];then
echo "[Unit]
Description=--Firefox Wrapper/Sandbox Service--
StartLimitIntervalSec=5
StartLimitBurst=5

[Service]
Type=fork
WorkingDirectory=$EXE_DIR
ExecStart=$EXE_DIR/service-wrapper-script.sh
Restart=always
RestartSec=3
RemainAfterExit=no

[Install]
WantedBy=multi-user.target" > /etc/systemd/system/$SERVICE_NAME
		chmod 644 /etc/systemd/system/$SERVICE_NAME
		systemctl daemon-reload
		systemctl enable $SERVICE_NAME
	fi
	timeout 5 systemctl restart $SERVICE_NAME
}

function SHORTCUT_SCRIPT_INSTALL {
echo "#!/bin/bash
#Script is s shortcut for running firejail sandbox
cd $EXE_DIR/
./firefox-jail.py" > $LAUNCHER_FILE
chmod 755 $LAUNCHER_FILE
ls -al $LAUNCHER_FILE
}

function DEPLOY_OVERWRITE {
	### Copy Firefox 'binary/launcher' to /sandbox and place the wrapper at /usr/bin/firefox
        echo " Deploy immutable..."
	if [ -f $EXE_DIR/firefox-launcher ];then
		if grep -q 'firejail' $EXE_DIR/firefox-launcher;then
			## If firejail wrapper is there! Bad
			rm $EXE_DIR/firefox-launcher
		else
			## Not wrapper, SAFE this
			cp $EXE_DIR/firefox-launcher $EXE_DIR/firefox-launcher.bak
		fi
	fi
	grep -q 'firejail' $LAUNCHER_FILE
	if [ "$?" == 1 ];then
                ## Not wrapper, SAFE this
        	cp $LAUNCHER_FILE $EXE_DIR/firefox-launcher
		chmod 755 $EXE_DIR/firefox-launcher
        fi
	SHORTCUT_SCRIPT_INSTALL	
}

function UPDATE_OVERWRITE {
        ### Copy Firefox 'binary/launcher' to /sandbox and place the wrapper at /usr/bin/firefox
        echo " Deploy immutable..."
        SHORTCUT_SCRIPT_INSTALL
}

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

function UNLINK {
        echo " unLinking..."
	unlink $LAUNCHER_FILE
	rm $LAUNCHER_FILE
	chattr -i $LAUNCHER_FILE
        cp $EXE_DIR/firefox-launcher $LAUNCHER_FILE
        ls -al $LAUNCHER_FILE
	systemctl stop $SERVICE_NAME
}

function UNINSTALL {
        UNLINK
        rm -rf $EXE_DIR
        systemctl disable $SERVICE_NAME
	systemctl stop $SERVICE_NAME
	rm /etc/systemd/system/$SERVICE_NAME
	systemctl daemon-reload
}

if [ ! -z "$1" ];then
	if [ "$1" == undo ];then
		if [ -L $LAUNCHER_FILE ];then
			echo "linked, undo'ing, acting..."
			UNLINK
			exit
		else
        		echo "Linked all good"
		fi
		exit
	elif [ "$1" == force ];then	
		DEPLOY
	elif [ "$1" == reinstall ];then
                DEPLOY
	elif [ "$1" == uninstall ];then
                UNINSTALL
		exit
	fi
	exit
fi


if [ ! -L $LAUNCHER_FILE ];then
	echo "not linked, acting..."
	DEPLOY	
	LINK
else
	echo "Linked, all good"
	#echo "Installed, all good"
	echo "Use options [force] or [reinstall] force deploy"
fi

