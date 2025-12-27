#!/usr/bin/python3
# Written by StormTheory in July2024
# Uploaded to github in Aug2024

# Wrapper for firejail for the purpose of sandboxing the Mozilla Firefox browser. 
# This wrapper allows for seamless intergration of the sandbox and your computer environment. 
# All firefox commands get intercepted by the wrapper's python script and then safely runs the sandbox. 
# After the sandbox launches firefox it will make sure that the sandbox is working. 
# If the sandbox is not registered it will pkill the program, in this case firefox.

# This python script runs from /sandbox where firefox.profile lives as well, as defined below. It is called by a softlink from the /usr/bin/firefox location.
# The firefox-launcher is the orginal 'firefox' command script that comes with the firefox package from mozilla. This is moved to /sandbox and renamed from /usr/bin/firefox.
# The CLI command firefox which is found in /usr/bin/firefox is softlink'd to /sandbox/firefox-jail.py

# Please note that the use of --nodbus will break the joining of two firefox sessions and you will get: "Firefox is already running, but is not responding."

# Files required:
## /sandbox/firefox-launcher
## /sandbox/firefox-jail.py
## /sandbox/firefox.profile

# Opional files:
## /sandbox/firefox-cac.profile
## /sandbox/firefox-drm.profile

import argparse
import time
import logging
import subprocess
import threading
import sys
import os
from os import geteuid
import configJailFirefox

## COLORS
class bcolors:
    HEADER = '\033[95m'
    BLUE = '\033[94m'
    CYAN = '\033[96m'
    GREEN = '\033[92m'
    YELLOW = '\033[93m'
    RED = '\033[91m'
    NC = '\033[0m'
    BOLD = '\033[1m'
    UNDERLINE = '\033[4m'

SANDBOX_NAME =configJailFirefox.SANDBOX_NAME
DEFAULT_FIREJAIL_OPTIONS = configJailFirefox.DEFAULT_FIREJAIL_OPTIONS

### Making it root safe
if os.geteuid() == 0:
    print(bcolors.RED + ' WARNING! Hey, you are ROOT! and should not run firefox.' + bcolors.NC)
    sys.exit()

parser = argparse.ArgumentParser()
parser.add_argument("-v", "--version", action='store_true', help='Version information for firejail and firefox')
parser.add_argument("-d", "--debug", action='store_true', help='Run wrapper in debug mode')
parser.add_argument("-u", "--unbox", action='store_true', help='Run firefox without a sandbox')
parser.add_argument("-l", "--list", action='store_true', help='Run firejail command to list sandboxes')
parser.add_argument("-j", "--join", action='store_true', help='Run firejail command to join the sandbox in a shell terminal')
parser.add_argument("--private", action='store_true', help='Run firejail command option. Mount new /root and /home/user directories in temporary filesystems. All modifications are discarded when the sandbox is closed.')
parser.add_argument("--cac", action='store_true', help='Run firefox to allow for CAC Readers in a sandbox')
parser.add_argument("--drm", action='store_true', help='Run firefox to allow for DRM to run for sites like Netflix or Disney+ in a sandbox')
parser.add_argument("--new-window", help='Firefox command to open URL in new window')
parser.add_argument("--new-tab", help='Firefox command to open URL in new tab')
parser.add_argument("--private-window", action='store_true', help='<url> Open <url> in a new private window.')
parser.add_argument("address", nargs='?')
args = parser.parse_args()

### SET LOGGING LEVEL
if args.debug:
    lLevel = logging.DEBUG     # INFO, DEBUG
else:
    lLevel = logging.INFO     # INFO, DEBUG

### LOGGER CONFIG
logger = logging.getLogger()
logger.setLevel(lLevel)

def SECURE(options_address):
    if args.private:
        if options_address is None:
            subprocess.run(['firejail --name=' + SANDBOX_NAME + ' ' + DEFAULT_FIREJAIL_OPTIONS + ' --private' + ' --profile=' + PROFILE + ' ' + FIREFOX_LAUNCHER], shell=True)
        else:
            subprocess.run(['firejail --name=' + SANDBOX_NAME + ' ' + DEFAULT_FIREJAIL_OPTIONS + ' --private' + ' --profile=' + PROFILE + ' ' + FIREFOX_LAUNCHER + ' ' + options_address], shell=True)
    else:    
        if options_address is None:
            subprocess.run(['firejail --name=' + SANDBOX_NAME + ' ' + DEFAULT_FIREJAIL_OPTIONS + ' --profile=' + PROFILE + ' ' + FIREFOX_LAUNCHER], shell=True)
        else:
            subprocess.run(['firejail --name=' + SANDBOX_NAME + ' ' + DEFAULT_FIREJAIL_OPTIONS + ' --profile=' + PROFILE + ' ' + FIREFOX_LAUNCHER + ' ' + options_address], shell=True)

def CLOSE():
    global EXIT_PYTHON
    EXIT_PYTHON = 'TRUE'
    print('Application Closing...')
    sys.exit()

#### VERSION INFO
if args.version:
    subprocess.run(["{} --version".format(configJailFirefox.FIREFOX_BIN)], shell=True)
    subprocess.run(["firejail --version"], shell=True)
    sys.exit()

#### List Sandboxes
if args.list:
    subprocess.run(["firejail --list"], shell=True)
    sys.exit()

#### Join Sandbox in a Shell
if args.join:
    subprocess.run(["firejail --join={}".format(SANDBOX_NAME)], shell=True)
    sys.exit()

#### CAC READER PROFILE SWITCH
if args.cac:
    PROFILE = configJailFirefox.PROFILE_CAC_READER
    print (bcolors.YELLOW + 'Will load... CAC Reader Access Profile ' + PROFILE + bcolors.NC)
if args.drm:
    PROFILE = configJailFirefox.PROFILE_NETFLIX_DRM
    print (bcolors.YELLOW + 'Will load... DRM Profile to allow for sites like Netflix ' + PROFILE + bcolors.NC)
else:
    PROFILE = configJailFirefox.DEFAULT_PROFILE

### ERROR CHECKING
os.path.exists(PROFILE)
if os.path.exists(configJailFirefox.FIREFOX_LAUNCHER):
    logging.debug(configJailFirefox.FIREFOX_LAUNCHER + ' was found')
    FIREFOX_LAUNCHER = configJailFirefox.FIREFOX_LAUNCHER
else:
    print('ERROR: ' + configJailFirefox.FIREFOX_LAUNCHER + ' file was not found. Using ' + configJailFirefox.FIREFOX_BIN)
    FIREFOX_LAUNCHER = configJailFirefox.FIREFOX_BIN
os.path.exists(configJailFirefox.FIREFOX_BIN)

#### NOT SANDBOX'd    
if args.unbox:
    print(bcolors.YELLOW + ' WARNING! Firefox is not sandboxed...' + bcolors.NC)
    if args.new_window:
        ADDRESS = vars(args)['new_window']
        ADDRESS = '--new-window ' + ADDRESS
        print(ADDRESS)
        subprocess.run([FIREFOX_LAUNCHER + ' --new-window ' + ADDRESS], shell=True)
        sys.exit()
    elif args.new_tab:
        ADDRESS = vars(args)['new_tab']
        ADDRESS = '--new-tab ' + ADDRESS
        print(ADDRESS)
        subprocess.run([FIREFOX_LAUNCHER + ' --new-tab ' + ADDRESS], shell=True)
        sys.exit()
    elif args.private_window:
        ADDRESS = vars(args)['address']
        if ADDRESS is None:
            ADDRESS=''
        ADDRESS = '--private-window ' + ADDRESS
        print(ADDRESS)
        subprocess.run([FIREFOX_LAUNCHER + ' --new-tab ' + ADDRESS], shell=True)
        sys.exit()
    elif len(sys.argv) <= 2:
        subprocess.run([FIREFOX_LAUNCHER], shell=True)
        sys.exit()
    else:
        ADDRESS = vars(args)['address']
        print(ADDRESS)
        subprocess.run([FIREFOX_LAUNCHER + ' ' + ADDRESS], shell=True)
        sys.exit()
else:
### Run sandbox

    #### Deploy firejail validator
    ## This function will check at start up that the sandbox launched as 
    ## it should and that the application is a registered sandbox with firejail.
    ## If not registered the with firejail, the pythan will pkill the application.
    def Sandbox_Validator ():
        if args.unbox:
            sys.exit()
        # Wait time to start test.
        time.sleep(2)
        while True:
            FIREJAIL_LIST_CODE = subprocess.run(["firejail --list|grep -q {}".format(SANDBOX_NAME)], shell=True).returncode
            logging.debug(FIREJAIL_LIST_CODE)
            if FIREJAIL_LIST_CODE is not int('0'):
                print(bcolors.RED + 'ERROR: Sandboxing issue... Exiting' + bcolors.NC)
                # Kill entire firejail process group safely
                try:
                    subprocess.run(["pkill", "-TERM", "-g", str(os.getpgid(os.getpid()))],check=False)
                    print(bcolors.YELLOW + 'Safed' + bcolors.NC)
                except Exception as e:
                    logging.debug(e)
                sys.exit()
            logging.debug('Sandbox is registered, exiting Validator')
            sys.exit()

    if configJailFirefox.USE_WITHIN_ANOTHER_FIREJAIL_SANDBOX == 'false':
        t1 = threading.Thread(target=Sandbox_Validator, daemon=False)
        t1.start()
    else:
        logging.debug('Not going to run the Validator')
        logging.debug('Using firejail within another firejail sandbox...')


    #### ELSE DEFAULT SECURE SANDBOX
    print(bcolors.GREEN + ' Sandboxing...' + bcolors.NC)
    if args.new_window:
        ADDRESS = vars(args)['new_window']
        ADDRESS = '--new-window ' + ADDRESS
        print(ADDRESS)
        SECURE(ADDRESS)
        CLOSE()
    elif args.new_tab:
        ADDRESS = vars(args)['new_tab']
        ADDRESS = '--new-tab ' + ADDRESS
        print(ADDRESS)
        SECURE(ADDRESS)
        CLOSE()
    elif args.private_window:
        ADDRESS = vars(args)['address']
        if ADDRESS is None:
            ADDRESS=''
        ADDRESS = '--private-window ' + ADDRESS
        print(ADDRESS)
        SECURE(ADDRESS)
        CLOSE()
    elif len(sys.argv) <= 1:
        SECURE('')
        CLOSE()
    else:
        ADDRESS = vars(args)['address']
        print(ADDRESS)
        SECURE(ADDRESS)
        CLOSE()
