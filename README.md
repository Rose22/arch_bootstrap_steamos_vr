# arch_bootstrap_steamos_vr
This script turns any minimal arch linux install into a steamOS-like setup that has built in VR support using wivr.
Ensure the multilib repository is enabled in your minimal arch linux installation before you use this script!

It installs:

- steam running on it's own user account, in gamescope, in steamOS mode (with the steamOS ui)
- a minimal display manager with autologin to the gamescope session
- enables sshd by default so you can log in remotely
- tigervnc so you can use graphical applications remotely
- wivrn
- wlx-overlay-s set up in a specific way that allows using it in steamOS mode
- wayvr-dashboard

## WARNING
this is intended to be used on a MINIMAL arch install! it modifies a ton of system critical stuff (such as sshd, vncserver, and a bunch of other things) to do it's thing. use it on an existing system at your own risk.
