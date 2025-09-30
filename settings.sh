set xkbmap -layout br -variant abnt2
sudo localectl set-x11-keymap br abnt2

nmcli dev wifi connect  "CERMOB_POS_Wi-Fi5" password "cermobpos123"
nmcli connection modify "CERMOB_POS_Wi-Fi5" connection.autoconnect yes
nmcli connection modify "CERMOB_POS_Wi-Fi5" wifi-sec.key-mgmt wpa-psk
nmcli connection modify "CERMOB_POS_Wi-Fi5" 802-11-wireless-security.psk "cermobpos123"

echo "set completion-ignore-case on" >> /etc/inputrc

echo 'function cd { builtin cd "$@" && ls --color=auto; }' >> /home/rock/.bashrc

git clone --depth=1 https://github.com/amix/vimrc.git ~/.vim_runtime
sh ~/.vim_runtime/install_awesome_vimrc.sh
echo "set relativenumber number" >> ~/.vim_runtime/my_configs.vim

sudo apt upgrade
sudo apt update
sudo apt upgrade
sudo apt-get install python3-libgpiod -y

xrandr --output HDMI-1 --mode 2560x1080
