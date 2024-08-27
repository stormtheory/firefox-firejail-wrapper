# Firefox Sandboxing with Firejail wrapper
Wrapper for firejail for the purpose of sandboxing the Mozilla Firefox browser. This wrapper allows for seemless intergration of the sandbox and your computer environment. All firefox commands get intercepted by the python script and then safely ran.
Written by StormTheory in July2024

In order to use this, firejail must be installed. Tested with firejail-0.9.72. 
Firejail can be found in your local software center or https://sourceforge.net/projects/firejail/

Runs from /sandbox where firefox.profile and firefox-jail.py lives. 
The firefox-bash in /sandbox is the orginal 'firefox' command script that comes with the firefox package from mozilla. This is moved to /sandbox and renamed from /usr/bin/firefox.
The CLI command firefox which is found in /usr/bin/firefox is softlink'd to /sandbox/firefox-jail.py

# User agreement:
This project is not a company or business. By using this project’s works, scripts, or code know that you, out of respect are entitled to privacy to highest grade. This product will not try to steal, share, collect, or sell your information. However 3rd parties such at Github may try to use your data without your consent. Users or admins should make reports of issue(s) related to the project’s product to the project to better equip or fix issues for others who may run into the same issue(s). By using this project’s works, scripts, code, or ideas you as the end user or admin agree to the following Warning statement and lack of acknowledge lack of Warranty.

WARNING: This project and it’s work does not come with a Warranty of any kind. It is on the end user or admin to preform regular backups, maintain kickstarts, verify code and or policies, and maintain their own gear and or equipment. This project will try to stay to the highest standards but will not be held accountable for any kind of mishaps that may happen while using.
