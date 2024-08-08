# Firefox Sandboxing with Firejail wrapper
Wrapper for firejail for the purpose of sandboxing the Mozilla Firefox browser. This wrapper allows for seemless intergration of the sandbox and your computer environment. All firefox commands get intercepted by the python script and then safely ran.
Written by StormTheory in July2024

In order to use this, firejail must be installed. Tested with firejail-0.9.72. 
Firejail can be found in your local software center or https://sourceforge.net/projects/firejail/

Runs from /sandbox where firefox.profile and firefox-jail.py lives. 
The firefox-bash in /sandbox is the orginal 'firefox' command script that comes with the firefox package from mozilla. This is moved to /sandbox and renamed from /usr/bin/firefox.
The CLI command firefox which is found in /usr/bin/firefox is softlink'd to /sandbox/firefox-jail.py
