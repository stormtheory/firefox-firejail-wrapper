# Place file at /sandbox/firefox-cac.profile
# The goal for this profile is to create a very secure but yet usable firefox sandbox.
# Firefox can only read or save files to ~/Downloads directory. If you need to upload something 
#   you have to move it to the downloads directory. This protects your files from being read or 
#   stolen without your relative knowledge.
# Blocks ssh keys from being read/stolen which has been a problem before and general homespace.
#
# This profile has added noblacklists for pkcs11 and coolkey allowing for CAC/Smartcard readers to work.
#   Refer to CAC_READER.txt as to how to install drivers to use CAC/Smartcard readers.
#
# Written by StormTheory in July2024
# Uploaded to github in Aug2024
#
#
# This file is overwritten after every install/update
# Persistent local customizations
include firefox.local
# Persistent global definitions
include globals.local

# NOTE: sandboxing web browsers is as important as it is complex. Users might be
# interested in creating custom profiles depending on use case (e.g. one for
# general browsing, another for banking, ...). Consult our FAQ/issue tracker for more
# info. Here are a few links to get you going.
# https://github.com/netblue30/firejail/wiki/Frequently-Asked-Questions#firefox-doesnt-open-in-a-new-sandbox-instead-it-opens-a-new-tab-in-an-existing-firefox-instance
# https://github.com/netblue30/firejail/wiki/Frequently-Asked-Questions#how-do-i-run-two-instances-of-firefox
# https://github.com/netblue30/firejail/issues/4206#issuecomment-824806968


#################### FIREFOX FIREJAIL WRAPPER PROJECT ADDED ########################
## CAC Card Reader ##
# Ubuntu
noblacklist /usr/lib/firefox/libnssckbi.so
noblacklist /usr/lib/x86_64-linux-gnu/nss
noblacklist /usr/lib/x86_64-linux-gnu/pkcs11
noblacklist /usr/lib/pkcs11
# RHEL
noblacklist /usr/lib64/pkcs11

#noblacklist ${HOME}/Documents
#whitelist ${HOME}/Documents
#read-only ${HOME}/Documents
blacklist /opt
blacklist /root
blacklist /media
blacklist /run/media
blacklist /boot

blacklist ${HOME}/.bashrc
blacklist ${HOME}/.ssh
blacklist ${HOME}/.local
noroot
nonewprivs
notv
nodvd
###################################### END #########################################

noblacklist ${HOME}/.cache/mozilla
noblacklist ${HOME}/.mozilla

blacklist /usr/libexec

mkdir ${HOME}/.cache/mozilla/firefox
mkdir ${HOME}/.mozilla
whitelist ${HOME}/.cache/mozilla/firefox
whitelist ${HOME}/.mozilla

# Add one of the following whitelist options to your firefox.local to enable KeePassXC Plugin support.
# NOTE: start KeePassXC before Firefox and keep it open to allow communication between them.
#whitelist ${RUNUSER}/kpxc_server
#whitelist ${RUNUSER}/org.keepassxc.KeePassXC.BrowserServer

whitelist /usr/share/doc
whitelist /usr/share/firefox
whitelist /usr/share/gnome-shell/search-providers/firefox-search-provider.ini
whitelist /usr/share/gtk-doc/html
whitelist /usr/share/mozilla
whitelist /usr/share/webext
include whitelist-usr-share-common.inc

# firefox requires a shell to launch on Arch - add the next line to your firefox.local to enable private-bin.
#private-bin bash,dbus-launch,dbus-send,env,firefox,sh,which
# Fedora uses shell scripts to launch firefox - add the next line to your firefox.local to enable private-bin.
#private-bin basename,bash,cat,dirname,expr,false,firefox,firefox-wayland,getenforce,ln,mkdir,pidof,restorecon,rm,rmdir,sed,sh,tclsh,true,uname
# Add the next line to your firefox.local to enable private-etc support - note that this must be enabled in your firefox-common.local too.
#private-etc firefox

dbus-user filter
dbus-user.own org.mozilla.Firefox.*
dbus-user.own org.mozilla.firefox.*
dbus-user.own org.mpris.MediaPlayer2.firefox.*
# Add the next line to your firefox.local to enable native notifications.
dbus-user.talk org.freedesktop.Notifications
# Add the next line to your firefox.local to allow inhibiting screensavers.
dbus-user.talk org.freedesktop.ScreenSaver
# Add the next lines to your firefox.local for plasma browser integration.
#dbus-user.own org.mpris.MediaPlayer2.plasma-browser-integration
#dbus-user.talk org.kde.JobViewServer
#dbus-user.talk org.kde.kuiserver
# Add the next three lines to your firefox.local to allow screen sharing under wayland.
#whitelist ${RUNUSER}/pipewire-0
#whitelist /usr/share/pipewire/client.conf
#dbus-user.talk org.freedesktop.portal.*
# Add the next line to your firefox.local if screen sharing sharing still does not work
# with the above lines (might depend on the portal implementation).
#ignore noroot
ignore dbus-user none


# Redirect - Disable for CAC Reader
# Uncomment the below include and remove the firefox-common.profile file section
#   below if you are NOT using a CAC Reader.
#include firefox-common.profile



#####################################################
############### firefox-common.profile ##############
#####################################################
# The file in /etc/firejail was breaking cac readers
# Moved the file here to troubleshoot...
# Something under "include whitelist-run-common.inc"
#####################################################
# Firejail profile for firefox-common
# This file is overwritten after every install/update
# Persistent local customizations
include firefox-common.local
# Persistent global definitions
# added by caller profile
#include globals.local

# noexec ${HOME} breaks DRM binaries.
?BROWSER_ALLOW_DRM: ignore noexec ${HOME}
# noexec ${RUNUSER} breaks DRM binaries when using profile-sync-daemon.
?BROWSER_ALLOW_DRM: ignore noexec ${RUNUSER}

# Add the next line to your firefox-common.local to allow access to common programs/addons/plugins.
#include firefox-common-addons.profile

noblacklist ${HOME}/.local/share/pki
noblacklist ${HOME}/.pki

include disable-common.inc
include disable-devel.inc
include disable-exec.inc
include disable-interpreters.inc
include disable-proc.inc
include disable-programs.inc

mkdir ${HOME}/.local/share/pki
mkdir ${HOME}/.pki
whitelist ${DOWNLOADS}
whitelist ${HOME}/.local/share/pki
whitelist ${HOME}/.pki
include whitelist-common.inc
#include whitelist-run-common.inc       # Breaks CAC Card Readers # Not sure why this is here to begin with...
include whitelist-runuser-common.inc
include whitelist-var-common.inc

apparmor
# Fixme!
apparmor-replace

caps.drop all
# machine-id breaks pulse audio; add it to your firefox-common.local if sound is not required.
#machine-id
netfilter
nodvd
nogroups
noinput
nonewprivs
# noroot breaks GTK_USE_PORTAL=1 usage, see https://github.com/netblue30/firejail/issues/2506.
#noroot
notv
?BROWSER_DISABLE_U2F: nou2f
protocol unix,inet,inet6,netlink
# The below seccomp configuration still permits chroot syscall. See https://github.com/netblue30/firejail/issues/2506 for possible workarounds.
seccomp !chroot
# Disable tracelog, it breaks or causes major issues with many firefox based browsers, see https://github.com/netblue30/firejail/issues/1930.
#tracelog

disable-mnt
?BROWSER_DISABLE_U2F: private-dev
# private-etc below works fine on most distributions. There are some problems on CentOS.
# Add it to your firefox-common.local if you want to enable it.
#private-etc alternatives,asound.conf,ca-certificates,crypto-policies,dconf,fonts,group,gtk-2.0,gtk-3.0,hostname,hosts,ld.so.cache,ld.so.conf,ld.so.conf.d,ld.so.preload,localtime,machine-id,mailcap,mime.types,nsswitch.conf,pango,passwd,pki,pulse,resolv.conf,selinux,ssl,X11,xdg
private-tmp

blacklist ${PATH}/curl
blacklist ${PATH}/wget
blacklist ${PATH}/wget2

# 'dbus-user none' breaks various desktop integration features like global menus, native notifications,
# Gnome connector, KDE connect and power management on KDE Plasma.
dbus-user none
dbus-system none

#restrict-namespaces

################ END COMMON ##################################
