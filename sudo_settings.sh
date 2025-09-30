echo "set completion-ignore-case on" >> /etc/inputrc

sudo apt upgrade -y
sudo apt update -y
sudo apt upgrade -y
sudo apt-get install python3-libgpiod -y

sudo systemctl start ssh
sudo systemctl enable ssh  # to start on boot
