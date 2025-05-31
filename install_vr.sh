cd /tmp

mkdir vr_install
cd vr_install

# install steamOS mode (steam on gamescope) required packages
echo "setting up steam and gamescope.."

sudo pacman -Sy steam gamescope mangohud lib32-mangohud 
git clone https://github.com/shahnawazshahin/steam-using-gamescope-guide.git
cd steam-using-gamescope-guide
chmod +x installer.sh
sudo ./installer.sh
cd ..
rm -rf steam-using-gamescope-guide

# install wivrn and other VR packages
yay -S wivrn-dashboard wlx-overlay-s-git wayvr-dashboard-git
systemctl --user enable --now wivrn

sleep 3

# install custom scripts and configs
mkdir $HOME/.vr_scripts
mkdir $HOME/.vr_scripts/logs

echo "
#!/bin/sh

# remove the gamescope performance overlay (it can mess with things)
unset LD_PRELOAD

# break out of gamescope's xwayland session
unset DISPLAY
export WAYLAND_DISPLAY=gamescope-0

wlx-overlay-s --headless --openxr --log-to ~/.vr_scripts/logs/wlx.log
" > $HOME/.vr_scripts/start_wlxoverlay.sh
chmod +x $HOME/.vr_scripts/start_wlxoverlay.sh

mkdir -p $HOME/.config/wivrn
echo "
{
  \"application\": [
	  \"$HOME/.vr_scripts/start_wlxoverlay.sh\"
  ]
}
" > $HOME/.config/wivrn/config.json

# cleanup
cd
sudo rm -rf /tmp/vr_install

echo "
Done! Now reboot your system, and in your display manager, there should be a new option called \"Steam (Gamescope)\". Log into that, and you should be in the steamOS UI!
Wivrn should also have been enabled, and on your quest, you should be able to connect.

When you're ready, set that session as the default in your display manager, so that your system boots straight into steamOS mode.
"
