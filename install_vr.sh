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
yay -S wivrn-server wivrn-dashboard wlx-overlay-s-git wayvr-dashboard-git
systemctl --user enable wivrn
systemctl --user start wivrn

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

# store current audio sink
export SAVED_AUDIO_SINK=\$(pactl get-default-sink)

# switch to the wivrn audio output
pactl set-default-sink wivrn.sink

wlx-overlay-s --headless --openxr --log-to ~/.vr_scripts/logs/wlx.log

# switch audio output back to the stored default
pactl set-default-sink $SAVED_AUDIO_SINK
" > $HOME/.vr_scripts/start_wlxoverlay.sh
chmod +x $HOME/.vr_scripts/start_wlxoverlay.sh

mkdir -p $HOME/.config/wivrn
echo "
{
  "application": [
	  "$HOME/.vr_scripts/start_wlxoverlay.sh"
  ]
}
" > $HOME/.config/wivrn/config.json

# cleanup
cd
sudo rm -rf /tmp/vr_install
