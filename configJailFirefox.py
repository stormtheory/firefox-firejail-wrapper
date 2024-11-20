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

# Files and variables required:
FIREFOX_LAUNCHER = '/sandbox/firefox-launcher'
FIREFOX_BIN = '/usr/lib/firefox/firefox'
DEFAULT_PROFILE = '/sandbox/firefox.profile'
SANDBOX_NAME = 'sandyfox'

DEFAULT_FIREJAIL_OPTIONS = '--noroot --disable-mnt --novideo --machine-id'

# Opional files and variables:
PROFILE_CAC_READER = '/sandbox/firefox-cac.profile'
PROFILE_NETFLIX_DRM = '/sandbox/firefox-drm.profile'

VIDEO_FIREJAIL_OPTIONS = '--noroot --disable-mnt --noprofile'

# Other options:
## true/false
USE_WITHIN_ANOTHER_FIREJAIL_SANDBOX = 'false'
