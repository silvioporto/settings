set xkbmap -layout br -variant abnt2
sudo localectl set-x11-keymap br abnt2

nmcli dev wifi connect  "CERMOB_POS" password "cermobpos123"
nmcli connection modify "CERMOB_POS" connection.autoconnect yes
nmcli connection modify "CERMOB_POS" wifi-sec.key-mgmt wpa-psk
nmcli connection modify "CERMOB_POS" 802-11-wireless-security.psk "cermobpos123"

echo 'function cd { builtin cd "$@" && ls --color=auto; }' >> /home/rock/.bashrc

git clone --depth=1 https://github.com/amix/vimrc.git ~/.vim_runtime
sh ~/.vim_runtime/install_awesome_vimrc.sh
echo "set relativenumber number" >> ~/.vim_runtime/my_configs.vim

xrandr --output HDMI-1 --mode 2560x1080
