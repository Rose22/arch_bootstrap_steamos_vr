#!/bin/sh
function announce() {
	echo "[VR INSTALL] $1"
}

echo "WARNING: ensure you have the multilib repository enabled!! if it isn't, stuff will break during install."
echo "This is your last chance to cancel out. (use ctrl+Z and kill the process)"
echo "---"
echo "This script will permanently turn your arch linux install into a steamOS clone that also has VR support. are you sure you wish to continue? (y/N)"
read confirm
if [ "$confirm" != "y" ]; then
	exit
fi

echo "Enter your password to continue:"
sudo echo

mkdir vr_install
cd vr_install

announce "enabling sshd for remote access, use it in case anything goes wrong or just in the future to access your PC"
sudo pacman --noconfirm -Sy openssh
sudo systemctl enable --now sshd

announce "installing networkmanager.."
sudo pacman --noconfirm -Sy networkmanager
sudo systemctl enable NetworkManager

announce "installing AMD GPU drivers.."
sudo pacman --noconfirm -Sy mesa lib32-mesa vulkan-radeon lib32-vulkan-radeon

announce "installing paru.."
sudo pacman --noconfirm -Sy --needed base-devel git rust
git clone https://aur.archlinux.org/paru.git
cd paru
makepkg --noconfirm -si
cd ..

announce "installing emptty display manager.."
sudo paru --noconfirm -S emptty

sudo groupadd nopasswdlogin
sudo usermod $USER -a -G nopasswdlogin
sudo mkdir -p /usr/share/wayland-sessions

announce "writing emptty config.."
cat <<EOF | sudo tee /etc/emptty/conf
# TTY, where emptty will start.
TTY_NUMBER=7

# Enables switching to defined TTY number.
SWITCH_TTY=true

# Enables printing of /etc/issue in daemon mode.
PRINT_ISSUE=false

# Enables printing of default motd, /etc/emptty/motd or /etc/emptty/motd-gen.sh.
PRINT_MOTD=false

# Preselected user, if AUTOLOGIN is enabled, this user is logged in.
DEFAULT_USER=$(whoami)

# Enables Autologin, if DEFAULT_USER is defined and part of nopasswdlogin group. Possible values are "true" or "false".
AUTOLOGIN=true

# The default session used, if Autologin is enabled. If session is not found in list of session, it proceeds to manual selection.
AUTOLOGIN_SESSION=Steam (Gamescope)

# If Autologin is enabled and session does not start correctly, the number of retries in short period is kept to eventually stop the infinite loop of restarts. -1 is for infinite retries, 0 is for no retry.
AUTOLOGIN_MAX_RETRY=2

# Default LANG, if user does not have set own in init script.
#LANG=en_US.UTF-8

# Starts desktop with calling "dbus-launch".
DBUS_LAUNCH=false

# Starts Xorg desktop with calling "~/.xinitrc" script, if is true, file exists and selected WM/DE is Xorg session, it overrides DBUS_LAUNCH.
XINITRC_LAUNCH=false

# Prints available WM/DE each on new line instead of printing on single line.
VERTICAL_SELECTION=true

# Defines the way, how is logging handled. Possible values are "rotate", "appending" or "disabled".
#LOGGING=rotate

# Overrides path of log file
#LOGGING_FILE=/var/log/emptty/[TTY_NUMBER].log

# Arguments passed to Xorg server.
#XORG_ARGS=

# Allows to use dynamic motd script to generate custom MOTD.
#DYNAMIC_MOTD=false

# Allows to override default path to dynamic motd.
#DYNAMIC_MOTD_PATH=/etc/emptty/motd-gen.sh

# Allows to override default path to static motd.
#MOTD_PATH=/etc/emptty/motd

# Foreground color, available only in daemon mode.
#FG_COLOR=LIGHT_BLACK

# Background color, available only in daemon mode.
#BG_COLOR=BLACK

# Enables numlock in daemon mode. Possible values are "true" or "false".
#ENABLE_NUMLOCK=false

# Defines the way, how is logging of session errors handled. Possible values are "rotate", "appending" or "disabled".
#SESSION_ERROR_LOGGING=disabled

# Overrides path of session errors log file
#SESSION_ERROR_LOGGING_FILE=/var/log/emptty/session-errors.[TTY_NUMBER].log

# If set true, it will not use '.emptty-xauth' file, but the standard '~/.Xauthority' file. This allows to handle xauth issues.
#DEFAULT_XAUTHORITY=false

#If set true, Xorg will be started as rootless, if system allows and emptty is running in daemon mode.
#ROOTLESS_XORG=false

#If set true, environmental groups are printed to differ Xorg/Wayland/Custom/UserCustom desktops.
IDENTIFY_ENVS=false
EOF

announce "enabling emptty.."
sudo systemctl enable emptty

announce "installing steam & gamescope.."
sudo pacman --noconfirm -Sy steam gamescope mangohud lib32-mangohud 
git clone https://github.com/shahnawazshahin/steam-using-gamescope-guide.git
cd steam-using-gamescope-guide
chmod +x installer.sh
sudo ./installer.sh
cd ..
rm -rfv steam-using-gamescope-guide

# install wivrn and other VR packages
announce "installing wivrn, wlx-overlay-s and wayvr-dashboard.."
sudo pacman --noconfirm -Sy avahi
sudo systemctl enable --now avahi-daemon

paru --noconfirm -S opencomposite-git wivrn-dashboard wlx-overlay-s-git wayvr-dashboard-git
systemctl --user enable wivrn.service

# install custom scripts and configs
mkdir $HOME/.vrscripts

cat << EOF | tee $HOME/.vrscripts/start_wlxoverlay.sh
#!/bin/sh

# remove the gamescope performance overlay (it can mess with things)
unset LD_PRELOAD

# break out of gamescope's xwayland session
unset DISPLAY
export WAYLAND_DISPLAY=gamescope-0

wlx-overlay-s --headless --openxr
EOF
chmod +x $HOME/.vrscripts/start_wlxoverlay.sh

mkdir -p $HOME/.config/wivrn
cat <<EOF | tee $HOME/.config/wivrn/config.json
{
  "application": [
	  "$HOME/.vrscripts/start_wlxoverlay.sh"
  ]
}
EOF

cat << EOF | tee $HOME/.vrscripts/steam_insert_vr_runtime.sh
#!/bin/sh
echo "this script will insert the required code into the steam linux runtime"
echo "please scroll down to the end of the file and then move the inserted code to where it belongs"
echo "press enter to continue.."
read

chmod +x $HOME/.vrscripts/steam_insert_vr_runtime.sh

echo "
# makes VR work with wivrn.
# move this above the 'set' statement in the script
export XR_RUNTIME_JSON=/run/host/usr/share/openxr/1/openxr_wivrn.json
export PRESSURE_VESSEL_FILESYSTEMS_RW=$XDG_RUNTIME_DIR/wivrn/comp_ipc
" >> ~/.steam/steam/steamapps/common/SteamLinuxRuntime_sniper/_v2-entry-point
$EDITOR ~/.steam/steam/steamapps/common/SteamLinuxRuntime_sniper/_v2-entry-point
EOF

# cleanup
cd ..
announce "cleaning up.."
sudo rm -rfv vr_install

announce "
Done! Now reboot your system, and you should immediately be logged into steamOS mode.

WiVRn should have been enabled, and on your quest, you should be able to connect!
Open wivrn-dashboard in order to begin the wivrn pairing process.

From now on, you can remote into your system using ssh for console access if needed. Feel free to disable that if you don't want it!

In your home directory is a hidden folder called .vrscripts, it has a variety of useful scripts.
You can use the steam_insert_vr_runtime script to add the VR runtime instructions needed for VR to function, into the steam linux runtime.
This is a workaround for a quirk about WiVRn that will hopefully be fixed in the future.

When you're ready, reboot the system!

This text has been written to your home folder in case you want to revisit these instructions.
" | tee $HOME/vr_instructions.txt
