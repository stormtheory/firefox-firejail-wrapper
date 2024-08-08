#!/usr/bin/python3
# Written by stormtheory in July2024
# Uploaded to github in August2024
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

FIREFOX_BASH = '/sandbox/firefox-bash'
FIREFOX_BIN = '/usr/lib/firefox/firefox'
PROFILE = '/sandbox/firefox.profile'

DEFAULT_FIREJAIL_OPTIONS = '--keep-var-tmp --disable-mnt --novideo --machine-id'
VIDEO_FIREJAIL_OPTIONS = '--keep-var-tmp --disable-mnt'

SANDBOX_NAME = 'sandyfox'
 
import argparse
import subprocess
import sys
import os
from os import geteuid

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
