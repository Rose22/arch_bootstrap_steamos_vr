# arch_bootstrap_steamos_vr
This script turns any minimal arch linux install into a steamOS-like setup that has built in VR support using wivr.

It's a very minimal install, that is laser focused on providing the best and most performant linux VR experience possible.

Prerequisites:
- Your PC must be running an AMD CPU and GPU
- multilib repository must be enabled
- pipewire or pulseaudio

It installs:
- steam running on it's own user account, in gamescope, in steamOS mode (with the steamOS ui)
- a minimal display manager with autologin to the gamescope session
- wivrn (PCVR streaming service)
- wlx-overlay-s set up in a specific way that allows using it in steamOS mode
- wayvr-dashboard

It also, for convenience:
- enables sshd by default so you can log in remotely
- sets up tigervnc so you can use graphical applications remotely inside the steam account, without having to switch to desktop. the default window manager on the vnc server is i3, use mod+d to open a launch menu.
- sway, in case you want to use the desktop outside of VNC

## WARNING
this is intended to be used on a MINIMAL arch install! it modifies a ton of system critical stuff (such as sshd, vncserver, and a bunch of other things) to do it's thing. use it on an existing system at your own risk. It would work and add the steam user and reconfigure the system to autostart gamescope on boot, but it will replace some system configs.

# install
To quickly convert a minimal arch install, just do this:
```
pacman -Sy git
git clone https://github.com/Rose22/arch_bootstrap_steamos_vr.git
cd arch_bootstrap_steamos_vr
chmod +x install_vr.sh
clear
./install_vr.sh
```

It's designed to ask for your password as minimally as possible, although some cases were hard to avoid. It's mostly unattended but you need to answer your password a few times.
