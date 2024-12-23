#!/usr/bin/bash
cd "$(dirname "$0")"

SLEEP=90

EXE_DIR=/sandbox

SANDBOX_APP_FIREFOX=firefox-jail.py
SANDBOX_APP_STEAM=steam-jail.py
SANDBOX_APP_CODE=code-jail.py
SANDBOX_APP_PDF=pdf-jail.py

SANDBOX_APP_LAUNCHER_FIREFOX=firefox-launcher
SANDBOX_APP_LAUNCHER_STEAM=steam-launcher
SANDBOX_APP_LAUNCHER_CODE=code-launcher
SANDBOX_APP_LAUNCHER_XREADER=xreader-launcher
SANDBOX_APP_LAUNCHER_EVINCE=evince-launcher


################# ERROR CHECKING
if [ -f /usr/bin/dpkg ];then
	echo "Ubuntu"
	dpkg -l|grep -q firejail
	if [ "$?" != 0 ];then
        	echo "ERROR: Firejail is not installed!"
        	exit
	fi
elif [ -f /usr/bin/rpm ];then
	echo "RHEL"
	rpm -qa|grep -q firejail
	if [ "$?" != 0 ];then
                echo "ERROR: Firejail is not installed!"
                exit
        fi
fi


if [ -f $EXE_DIR/$SANDBOX_APP_FIREFOX ];then
	echo "Firefox"
	LAUNCHER_USR_BIN_FIREFOX=/usr/bin/firefox
	FIREFOX_ACTIVE=True
	echo "  $LAUNCHER_USR_BIN_FIREFOX"
fi
if [ -f $EXE_DIR/$SANDBOX_APP_STEAM ];then
	echo "STEAM"
	LAUNCHER_USR_BIN_STEAM=/usr/games/steam
	STEAM_ACTIVE=True
	echo "  $LAUNCHER_USR_BIN_STEAM"
fi
if [ -f $EXE_DIR/$SANDBOX_APP_CODE ];then
	echo "CODE"
	CODE_ACTIVE=True
	echo "  /usr/bin/code  /usr/share/code/code"
fi
if [ -f $EXE_DIR/$SANDBOX_APP_PDF ];then
	echo "PDF"
	LAUNCHER_USR_BIN_XREADER=/usr/bin/xreader
	LAUNCHER_USR_BIN_EVINCE=/usr/bin/evince
	PDF_ACTIVE=True
	echo "  $LAUNCHER_USR_BIN_XREADER $LAUNCHER_USR_BIN_EVINCE"
fi


ID=$(id -u)
if [ "$ID" != 0 ];then
        echo "Not root"
        exit
fi

################### MEAT

#SANDBOX_APP=.py
#LAUNCHER_FILE=/usr/bin/
#SANDBOX_APP_LAUNCHER=-launcher
function LINK {
        ### Copy 'bash/binary' to /sandbox and softlink the wrapper
        echo " Linking..."
        if [ -f "$EXE_DIR/$SANDBOX_APP" ];then
                if [ -f $LAUNCHER_FILE ];then
			cp $LAUNCHER_FILE $EXE_DIR/$SANDBOX_APP_LAUNCHER
                	chmod 755 $EXE_DIR/$SANDBOX_APP_LAUNCHER
        		rm $LAUNCHER_FILE
		fi
		if [ ! -L $LAUNCHER_FILE ];then
        		ln -s $EXE_DIR/$SANDBOX_APP $LAUNCHER_FILE
        		ls -al $LAUNCHER_FILE
		fi
	else
		echo "ERROR: $EXE_DIR/$SANDBOX_APP was not found..."
		exit 1
	fi
}

################## LOOP
while true;do
	if [ "$FIREFOX_ACTIVE" == True ];then
		if [ -f $LAUNCHER_USR_BIN_FIREFOX ];then #has to exist, we don't want to create something that shouldn't be there
			if [ ! -L $LAUNCHER_USR_BIN_FIREFOX ];then #is not a link already
        			echo "Firefox not linked, acting..."
				SANDBOX_APP=$(echo "$SANDBOX_APP_FIREFOX")
				LAUNCHER_FILE=$(echo "$LAUNCHER_USR_BIN_FIREFOX")
				SANDBOX_APP_LAUNCHER=$(echo "$SANDBOX_APP_LAUNCHER_FIREFOX")
        			LINK
			fi
		fi
	fi
	if [ "$STEAM_ACTIVE" == True ];then
        	if [ -f $LAUNCHER_USR_BIN_STEAM ];then #has to exist, we don't want to create something that shouldn't be there
			if [ ! -L $LAUNCHER_USR_BIN_STEAM ];then #is not a link already
                		echo "Steam not linked, acting..."
                		SANDBOX_APP=$(echo "$SANDBOX_APP_STEAM")
                		LAUNCHER_FILE=$(echo "$LAUNCHER_USR_BIN_STEAM")
                		SANDBOX_APP_LAUNCHER=$(echo "$SANDBOX_APP_LAUNCHER_STEAM")
                		LINK
			fi
        	fi
	fi
	if [ "$CODE_ACTIVE" == True ];then
		if [ -f /usr/bin/code ];then #has to exist, we don't want to create something that shouldn't be there
        		if [ -L /usr/bin/code ];then # this is normally a link already, make sure it points to the right place 
                		ls -al /usr/bin/code |grep -q "$EXE_DIR/$SANDBOX_APP_CODE"
				if [ "$?" != 0 ];then
                        		echo "Linking Code..."
                        		unlink /usr/bin/code
                        		ln -s $EXE_DIR/code-jail.py /usr/bin/code
                        		ls -al /usr/bin/code
                		fi
			fi
        	fi
		if [ -f /usr/share/code/code ];then
        	if [ ! -L /usr/share/code/code ];then
                	echo "Taking care of /usr/share/code/code..."
                	sed -i '/ELECTRON=/c\ELECTRON="$VSCODE_PATH/code-bin"' /usr/share/code/bin/code
                	mv /usr/share/code/code /usr/share/code/code-bin
                	ln -s $EXE_DIR/code-jail.py /usr/share/code/code
                	ls -al /usr/share/code/code
	        fi
	        fi
	fi
	if [ "$PDF_ACTIVE" == True ];then
		if [ -f $LAUNCHER_USR_BIN_XREADER ];then #has to exist, we don't want to create something that shouldn't be there
        		if [ ! -L $LAUNCHER_USR_BIN_XREADER ];then #is not a link already
                		echo "Xreader not linked, acting..."
                		SANDBOX_APP=$(echo "$SANDBOX_APP_PDF")
                		LAUNCHER_FILE=$(echo "$LAUNCHER_USR_BIN_XREADER")
                		SANDBOX_APP_LAUNCHER=$(echo "$SANDBOX_APP_LAUNCHER_XREADER")
                		LINK
        		fi
		fi
		if [ -f $LAUNCHER_USR_BIN_EVINCE ];then #has to exist, we don't want to create something that shouldn't be there
                	if [ ! -L $LAUNCHER_USR_BIN_EVINCE ];then #is not a link already
                        	echo "Evince not linked, acting..."
                        	SANDBOX_APP=$(echo "$SANDBOX_APP_PDF")
                        	LAUNCHER_FILE=$(echo "$LAUNCHER_USR_BIN_EVINCE")
                        	SANDBOX_APP_LAUNCHER=$(echo "$SANDBOX_APP_LAUNCHER_EVINCE")
                        	LINK
                	fi
        	fi
	fi
	sleep $SLEEP
done
