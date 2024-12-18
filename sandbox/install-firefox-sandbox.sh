#!/usr/bin/bash
cd "$(dirname "$0")"
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin

# OPTIONS: 
#    force 		- Force deploy config files and softlink
#    reinstall 		- Force deploy config files and softlink
#    service 		- Installs service file
#    install-service 	- Installs service file
#    undo 		- Undo the softlink install
#    uninstall 		- Uninstalls
#    uninstall-package - Uninstalls *Used by package manager*

EXE_DIR=/sandbox
CONFIG_DIR=.
LAUNCHER_FILE=/usr/bin/firefox
SERVICE_NAME=wrapper-firefox.service

FIREJAIL_APP_LAUNCHER_FILE=firefox-launcher
FIREJAIL_PYTHON_WRAPPER=firefox-jail.py
FIREJAIL_CONFIG_WRAPPER=configJailFirefox.py
FIREJAIL_DEFAULT_PROFILE=firefox.profile

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
if [ ! -f $CONFIG_DIR/$FIREJAIL_PYTHON_WRAPPER ];then
        echo "ERROR: $CONFIG_DIR/$FIREJAIL_PYTHON_WRAPPER not found..."
        exit
elif [ ! -f $CONFIG_DIR/$FIREJAIL_DEFAULT_PROFILE ];then
        echo "ERROR: $CONFIG_DIR/$FIREJAIL_DEFAULT_PROFILE not found..."
        exit
fi
if [ -f $EXE_DIR/firefox-bash ];then
	## Filename change
	mv $EXE_DIR/firefox-bash $EXE_DIR/$FIREJAIL_APP_LAUNCHER_FILE
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
	if [ ! -f $EXE_DIR/$FIREJAIL_CONFIG_WRAPPER ];then
		cp $CONFIG_DIR/$FIREJAIL_CONFIG_WRAPPER $EXE_DIR
		chmod 644 $EXE_DIR/$FIREJAIL_CONFIG_WRAPPER
	elif [ -f $EXE_DIR/$FIREJAIL_CONFIG_WRAPPER ];then
                grep -q 'USE_WITHIN_ANOTHER_FIREJAIL_SANDBOX' $EXE_DIR/$FIREJAIL_CONFIG_WRAPPER
                if [ "$?" != 0 ];then
                	echo "Updating config file #1..."
                	echo "" >> $EXE_DIR/$FIREJAIL_CONFIG_WRAPPER
			echo "# Other options:" >> $EXE_DIR/$FIREJAIL_CONFIG_WRAPPER
                	echo "## true/false" >> $EXE_DIR/$FIREJAIL_CONFIG_WRAPPER
                	echo "USE_WITHIN_ANOTHER_FIREJAIL_SANDBOX = 'false'" >> $EXE_DIR/$FIREJAIL_CONFIG_WRAPPER
		fi
	else
		echo "Config file $EXE_DIR/$FIREJAIL_CONFIG_WRAPPER already installed... skipping"
	fi

        cp $CONFIG_DIR/$FIREJAIL_PYTHON_WRAPPER $EXE_DIR
        chmod 755 $EXE_DIR/$FIREJAIL_PYTHON_WRAPPER
        cp $CONFIG_DIR/$FIREJAIL_DEFAULT_PROFILE $EXE_DIR
        cp $CONFIG_DIR/firefox-cac.profile $EXE_DIR
	cp $CONFIG_DIR/firefox-drm.profile $EXE_DIR
	cp $CONFIG_DIR/service-wrapper-script.sh $EXE_DIR
        chmod 644 $EXE_DIR/*.profile
	chmod 700 $EXE_DIR/service-wrapper-script.sh
        chown -R root:root $EXE_DIR
}

function DEPLOY_SERVICE {
	## Deploy Service
	if [ ! -f /etc/systemd/system/$SERVICE_NAME ];then
echo "[Unit]
Description=--App Wrapper/Sandbox Service--
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
#Script is a shortcut for running firejail sandbox
cd $EXE_DIR/
./$FIREJAIL_PYTHON_WRAPPER" > $LAUNCHER_FILE
chmod 755 $LAUNCHER_FILE
ls -al $LAUNCHER_FILE
}

function DEPLOY_OVERWRITE {
	### Copy APP 'bash/binary launcher' to /sandbox and place the wrapper at /usr/bin/firefox
        echo " Deploy immutable..."
	if [ -f $EXE_DIR/$FIREJAIL_APP_LAUNCHER_FILE ];then
		if grep -q 'firejail' $EXE_DIR/$FIREJAIL_APP_LAUNCHER_FILE;then
			## If firejail wrapper is there! Bad
			rm $EXE_DIR/$FIREJAIL_APP_LAUNCHER_FILE
		else
			## Not wrapper, SAFE this
			cp $EXE_DIR/$FIREJAIL_APP_LAUNCHER_FILE $EXE_DIR/$FIREJAIL_APP_LAUNCHER_FILE.bak
		fi
	fi
	grep -q 'firejail' $LAUNCHER_FILE
	if [ "$?" == 1 ];then
                ## Not wrapper, SAFE this
        	cp $LAUNCHER_FILE $EXE_DIR/$FIREJAIL_APP_LAUNCHER_FILE
		chmod 755 $EXE_DIR/$FIREJAIL_APP_LAUNCHER_FILE
        fi
	SHORTCUT_SCRIPT_INSTALL	
}

function UPDATE_OVERWRITE {
        ### Copy APP 'bash/binary launcher' to /sandbox and place the wrapper at /usr/bin/firefox
        echo " Deploy immutable..."
        SHORTCUT_SCRIPT_INSTALL
}

function LINK {
        ### Copy APP 'bash/binary launcher' to /sandbox and softlink the wrapper
        echo " Linking..."
	grep -q 'firejail' $LAUNCHER_FILE
	if [ "$?" != 0 ];then
        	cp $LAUNCHER_FILE $EXE_DIR/$FIREJAIL_APP_LAUNCHER_FILE
        	chmod 755 $EXE_DIR/$FIREJAIL_APP_LAUNCHER_FILE
        fi
	rm $LAUNCHER_FILE
        ln -s $EXE_DIR/$FIREJAIL_PYTHON_WRAPPER $LAUNCHER_FILE
        ls -al $LAUNCHER_FILE
}

function UNLINK {
        echo " unLinking..."
	unlink $LAUNCHER_FILE
	chattr -i $LAUNCHER_FILE
        cp $EXE_DIR/$FIREJAIL_APP_LAUNCHER_FILE $LAUNCHER_FILE
        chmod 755 $LAUNCHER_FILE
	ls -al $LAUNCHER_FILE
	systemctl stop $SERVICE_NAME
}

function UNINSTALL {
        UNLINK
        systemctl disable $SERVICE_NAME
	systemctl stop $SERVICE_NAME
	rm /etc/systemd/system/$SERVICE_NAME
	systemctl daemon-reload
	systemctl stop $SERVICE_NAME
	rm -rf $EXE_DIR
}

function UNINSTALL-PACKAGE {
        UNLINK
        systemctl disable $SERVICE_NAME
        systemctl stop $SERVICE_NAME
        rm /etc/systemd/system/$SERVICE_NAME
        systemctl daemon-reload
	systemctl stop $SERVICE_NAME
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
		##NO EXIT - Links Below
	elif [ "$1" == reinstall ];then
                DEPLOY
		##NO EXIT - Links Below
	elif [ "$1" == uninstall ];then
                UNINSTALL
		exit
	elif [ "$1" == service ];then
                DEPLOY_SERVICE
                exit
	elif [ "$1" == install-service ];then
                DEPLOY_SERVICE
                exit
	elif [ "$1" == install ];then
                DEPLOY
		##NO EXIT - Links Below
	fi
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

