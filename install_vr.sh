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

announce "adding steam user (seperate user ensures less chance of failure).."
sudo groupadd nopasswdlogin
sudo useradd -m -G nopasswdlogin steam
sudo bash -c "(echo steam; echo steam) | passwd steam"

announce "installing vnc server for even more remote access.."
sudo pacman --noconfirm -Sy tigervnc

sudo -u steam bash -c "(echo steamvnc; echo steamvnc) | vncpasswd"
cat <<EOF | sudo tee /etc/tigervnc/vncserver.users
:1=steam
EOF

sudo -u steam mkdir -p /home/steam/.config/tigervnc
cat <<EOF | sudo -u steam tee /home/steam/.config/tigervnc/config
session=i3
geometry=1024x768
alwaysshared
EOF

cat <<EOF | sudo tee /etc/X11/xorg.conf.d/10-vnc.conf
Section "Module"
Load "vnc"
EndSection

Section "Screen"
Identifier "Screen0"
Option "UserPasswdVerifier" "VncAuth"
Option "PasswordFile" "/root/.vnc/passwd"
EndSection
EOF

# we need an X11 window manager in order to be able to log into the VNC server
sudo pacman --noconfirm -Sy i3-wm i3status dmenu rofi kitty

# but let's also have a wayland window manager handy
sudo pacman --noconfirm -Sy sway waybar swaync swaybg swaylock swayimg swayidle

sudo systemctl enable vncserver@:1

announce "installed VNC, you can now log in remotely as steam to use graphical applications!"

announce "installing paru.."
sudo pacman --noconfirm -Sy --needed base-devel git rust
git clone https://aur.archlinux.org/paru.git
cd paru
makepkg --noconfirm -si
cd ..

announce "installing emptty display manager.."
sudo paru --noconfirm -S emptty

announce "writing emptty config.."
cat <<EOF | sudo tee /etc/emptty/conf
# TTY, where emptty will start.
TTY_NUMBER=7

# Enables switching to defined TTY number.
SWITCH_TTY=true

# Enables printing of /etc/issue in daemon mode.
PRINT_ISSUE=true

# Enables printing of default motd, /etc/emptty/motd or /etc/emptty/motd-gen.sh.
PRINT_MOTD=false

# Preselected user, if AUTOLOGIN is enabled, this user is logged in.
DEFAULT_USER=steam

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
# manually enable the service because using systemctl over sudo doesn't work well without very weird workarounds
sudo -u steam mkdir -p /home/steam/.config/systemd/user/default.target.wants
sudo -u steam ln -s /usr/lib/systemd/user/wivrn.service /home/steam/.config/systemd/user/default.target.wants/wivrn.service

# install custom scripts and configs
sudo -u steam mkdir /home/steam/.scripts

cat << EOF | sudo -u steam tee /home/steam/.scripts/start_wlxoverlay.sh
#!/bin/sh

# remove the gamescope performance overlay (it can mess with things)
unset LD_PRELOAD

# break out of gamescope's xwayland session
unset DISPLAY
export WAYLAND_DISPLAY=gamescope-0

wlx-overlay-s --headless --openxr
EOF
sudo -u steam chmod +x /home/steam/.scripts/start_wlxoverlay.sh

sudo -u steam mkdir -p /home/steam/.config/wivrn
cat <<EOF | sudo -u steam tee /home/steam/.config/wivrn/config.json
{
  "application": [
	  "/home/steam/.scripts/start_wlxoverlay.sh"
  ]
}
EOF

# cleanup
cd ..
announce "cleaning up.."
sudo rm -rfv vr_install

announce "
Done! Now reboot your system, and you should immediately be logged into steamOS mode.

From now on, you can remote into your system using ssh for console access, and vnc for graphical access.
Feel free to uninstall tigervnc if you don't want this!

A new user called steam has been created, and the password for it is steam. This keeps steam seperate from your main user account, in case you want to use this computer for other things too as your normal user account.
You can change the steam user password if you wish, it has no effect on auto login.

You can access VNC through port 5901, the password is steamvnc. This'll log you into a remote desktop session in the steam user account.
You can use this to do stuff like add non-steam games to steam, install software needed under the steam account such as decky-loader, etc.

Wivrn should also have been enabled, and on your quest, you should be able to connect!
Open wivrn-dashboard as the steam user in order to begin the wivrn pairing process. You can either do this using a mouse on your PC, or through VNC.

When you're ready, reboot the system!

This text has been written to your home folder in case you want to revisit these instructions.
" | tee $HOME/vr_instructions.txt
