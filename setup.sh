#!/bin/zsh

## Set wallpaper
xfconf-query -c xfce4-desktop -p /backdrop/screen0/monitor0/image-path -s wallpaper.jpg

## Move transfer folder to /opt/
mkdir /opt/transfer
mv -r transfer/. /opt/transfer/

## Move .zsh stuff to ~
mv -r zsh/. /root/

## Download tools

#Burp
cd /root/lab/kali_setup
wget -O 'burp_downloader.sh' 'https://portswigger-cdn.net/burp/releases/download?product=pro&type=Linux'
chmod +x burp_downloader.sh burp_patcher.sh
./burp_downloader.sh
./burp_patcher.sh

#Dcode
cd /opt/
git clone https://github.com/UltimateHackers/Decodify
cd Decodify
make install

#Kerbrute
cd /opt/
go install github.com/ropnop/kerbrute@latest

#Ligolo
cd /opt/
git clone https://github.com/nicocha30/ligolo-ng.git
cd ligolo-ng
go build -o agent cmd/agent/main.go
go build -o proxy cmd/proxy/main.go
GOOS=windows go build -o agent.exe cmd/agent/main.go
cp agent agent.exe /opt/transfer 

#SSTImap
cd /opt/
git clone https://github.com/vladko312/SSTImap.git
cd SSTImap
pip3 install -r requirements.txt

#EZPZ
cd /opt/
git clone https://github.com/chsoares/ezpz.git
cd ezpz; chmod +x ezpz.sh

#Creds
pip3 install defaultcreds-cheat-sheet

## Fix Rockyou
cd /usr/share/wordlists
mv rockyou.txt rockyou_old.txt
iconv -f ISO-8859-1 -t UTF-8 rockyou_old.txt > rockyou.txt
rm rockyou_old.txt

## PIPX
pipx install bloodyAD
pipx install autobloody
pipx install autorecon
pipx install certipy
pipx install impacket
pipx install git+https://github.com/Pennyw0rth/NetExec

