#!/usr/bin/python3
# Written by StormTheory in July2024
# Uploaded to github in Aug2024
# Wrapper for firejail for the purpose of sandboxing the Mozilla Firefox browser.
# This wrapper allows for seemless intergration of the sandbox and your computer environment.
# All firefox commands get intercepted by the python script and then safely ran.

# This python script runs from /sandbox where firefox.profile lives as well, as defined below. It is called by a softlink from the /usr/bin/firefox location.
# The firefox-bash is the orginal 'firefox' command script that comes with the firefox package from mozilla. This is moved to /sandbox and renamed from /usr/bin/firefox.
# The CLI command firefox which is found in /usr/bin/firefox is softlink'd to /sandbox/firefox-jail.py

# Please note that the use of --nodbus will break the joining of two firefox seesions and you will get: "Firefox is already running, but is not responding."

# Files required:
## /sandbox/firefox-bash
## /sandbox/firefox-jail.py
## /sandbox/firefox.profile

# Opional files:
## /sandbox/firefox-cac.profile

# Files and variables required:
FIREFOX_BASH = '/sandbox/firefox-bash'
FIREFOX_BIN = '/usr/lib/firefox/firefox'
PROFILE = '/sandbox/firefox.profile'
SANDBOX_NAME = 'sandyfox'

DEFAULT_FIREJAIL_OPTIONS = '--noroot --nodvd --keep-var-tmp --disable-mnt --novideo --noprofile --machine-id'

# Opional files and variables:
PROFILE_CAC_READER = '/sandbox/firefox-cac.profile'

VIDEO_FIREJAIL_OPTIONS = '--noroot --nodvd --keep-var-tmp --disable-mnt --noprofile'

import argparse
import logging
import subprocess
import sys
import os
from os import geteuid

### SET LOGGING LEVEL
lLevel = logging.INFO     # INFO, DEBUG

### LOGGER CONFIG
logger = logging.getLogger()
logger.setLevel(lLevel)

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

### Making it root safe
if os.geteuid() == 0:
    print(bcolors.RED + ' WARNING! Hey, you are ROOT! and should not run firefox.' + bcolors.NC)
    sys.exit()

parser = argparse.ArgumentParser()
parser.add_argument("-v", "--version", action='store_true', help='Version information for firejail and firefox')
parser.add_argument("-u", "--unbox", action='store_true', help='Run firefox without a sandbox')
parser.add_argument("--cac", action='store_true', help='Run firefox to allow for CAC Readers in a sandbox')
parser.add_argument("--new-window", help='Firefox command to open in new window')
parser.add_argument("--new-tab", help='Firefox command to open in new tab')
parser.add_argument("address", nargs='?')
args = parser.parse_args()

def VIDEO_MODE(address):
    if address is None:
        subprocess.run(['firejail --name=' + SANDBOX_NAME + ' ' + VIDEO_FIREJAIL_OPTIONS + ' --include=' + PROFILE + ' ' + FIREFOX_BASH], shell=True)
    else:
        subprocess.run(['firejail --name=' + SANDBOX_NAME + ' ' + VIDEO_FIREJAIL_OPTIONS + ' --include=' + PROFILE + ' ' + FIREFOX_BASH + ' ' + address], shell=True)

def SECURE(address):
    if address is None:
        subprocess.run(['firejail --name=' + SANDBOX_NAME + ' ' + DEFAULT_FIREJAIL_OPTIONS + ' --include=' + PROFILE + ' ' + FIREFOX_BASH], shell=True)
    else:
        subprocess.run(['firejail --name=' + SANDBOX_NAME + ' ' + DEFAULT_FIREJAIL_OPTIONS + ' --include=' + PROFILE + ' ' + FIREFOX_BASH + ' ' + address], shell=True)


#### VERSION INFO
if args.version:
    subprocess.run(["{} --version".format(FIREFOX_BIN)], shell=True)
    subprocess.run(["firejail --version"], shell=True)
    sys.exit()


#### CAC READER PROFILE SWITCH
if args.cac:
    PROFILE = PROFILE_CAC_READER
    print (bcolors.YELLOW + 'Will load... CAC Reader Access Profile ' + PROFILE + bcolors.NC)

### ERROR CHECKING
os.path.exists(PROFILE)
if os.path.exists(FIREFOX_BASH):
    logging.debug(FIREFOX_BASH + ' was found')
else:
    print('ERROR: ' + FIREFOX_BASH + ' file was not found. Using ' + FIREFOX_BIN)
    FIREFOX_BASH = FIREFOX_BIN
os.path.exists(FIREFOX_BIN)


#### NOT SANDBOX'd    
if args.unbox:
    print(bcolors.YELLOW + ' WARNING! Firefox is not sandboxed...' + bcolors.NC)
    if args.new_window:
        ADDRESS = vars(args)['new_window']
        ADDRESS = '--new-window ' + ADDRESS
        print(ADDRESS)
        subprocess.run([FIREFOX_BASH + ' --new-window ' + ADDRESS], shell=True)
        sys.exit()
    elif args.new_tab:
        ADDRESS = vars(args)['new_tab']
        ADDRESS = '--new-tab ' + ADDRESS
        print(ADDRESS)
        subprocess.run([FIREFOX_BASH + ' --new-tab ' + ADDRESS], shell=True)
        sys.exit()
    elif len(sys.argv) <= 2:
        subprocess.run([FIREFOX_BASH], shell=True)
        sys.exit()
    else:
        ADDRESS = vars(args)['address']
        print(ADDRESS)
        subprocess.run([FIREFOX_BASH + ' ' + ADDRESS], shell=True)
        sys.exit()

#### ELSE DEFAULT SECURE SANDBOX
print(bcolors.GREEN + ' Sandboxing...' + bcolors.NC)
if args.new_window:
    ADDRESS = vars(args)['new_window']
    ADDRESS = '--new-window ' + ADDRESS
    print(ADDRESS)
    SECURE(ADDRESS)
    sys.exit()
elif args.new_tab:
    ADDRESS = vars(args)['new_tab']
    ADDRESS = '--new-tab ' + ADDRESS
    print(ADDRESS)
    SECURE(ADDRESS)
    sys.exit()
elif len(sys.argv) <= 1:
    SECURE('')
    sys.exit()
else:
    ADDRESS = vars(args)['address']
    print(ADDRESS)
    SECURE(ADDRESS)
    sys.exit()
