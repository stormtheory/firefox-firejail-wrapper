# Firefox Sandboxing with Firejail wrapper
Wrapper for firejail for the purpose of sandboxing the Mozilla Firefox browser. This wrapper allows for seamless intergration of the sandbox and your computer environment. All firefox commands get intercepted by the wrapper's python script and then safely runs the sandbox. After the sandbox launches firefox it will make sure that the sandbox is working. If the sandbox is not registered it will pkill the program, in this case firefox.
Written by StormTheory in July2024

As of Dec 18, 2024 the Wrapper is out of Beta with a .deb installer.

# The Profile
The goal for this profile is to create a very secure but yet usable firefox sandbox. Firefox can only read or save/download files to ~/Downloads directory. If you need to upload something you have to move it to the downloads directory. This protects your files from being read or stolen without your knowledge. For Example: blocks ssh keys from being read/stolen which has been a problem before and general homespace protection. Firefox within the sandbox will not be able to take root or see very much of system files. For testing the user can join the firefox session and see what the firefox app 'sees'.

# System Requirements
In order to use this, firejail-0.9.72 or better must be installed. Tested with firejail-0.9.72.
Firejail can be found in your local software center or https://sourceforge.net/projects/firejail/

At this time Ubuntu/Mint is only tested to be supported. There may only be little work to make it RHEL/Rocky/Yum/DNF supported, please feedback if wanted. 
This will not work for App Images or Flatpak installs. If there is interest in other Linux flavors/families please let me know. 

# Overview of Data Flow
Runs from /sandbox where firefox.profile and firefox-jail.py lives. 
The firefox-launcher in /sandbox is the orginal 'firefox' command script that comes with the firefox package from mozilla. This is moved to /sandbox and renamed from /usr/bin/firefox.
The CLI command firefox which is found in /usr/bin/firefox is softlink'd to /sandbox/firefox-jail.py

NOTE: The install of the softlink will have to happen after each update of the firefox package. 
If the wrapper is to be used as designed use the by default service that checks every 90 seconds or 
it is recommended to add the install script to your automatic update post scripts.

# User Agreement:
This project is not a company or business. By using this project’s works, scripts, or code, please know that out of respect for YOU, are entitled to privacy in the highest grade. This product will not try to steal, share, collect, or sell your information. However 3rd parties such at Github may try to use your data without your consent. Users or admins should make reports of issue(s) related to the project’s product to the project to better equip or fix issues for others who may run into the same issue(s). By using this project’s works, scripts, code, or ideas you as the end user or admin agree to the following Warning statement and lack of acknowledge lack of Warranty.

WARNING: This project and it’s work does not come with a Warranty of any kind. It is on the end user or admin to preform regular backups, maintain kickstarts, verify code and or policies, and maintain their own gear and or equipment. This project will try to stay to the highest standards but will not be held accountable for any kind of mishaps that may happen while using.
