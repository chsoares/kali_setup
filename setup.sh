#!/bin/zsh

## Set wallpaper
xfconf-query -c xfce4-desktop -p /backdrop/screen0/monitor0/image-path -s wallpaper.jpg

## Move transfer folder to /opt/
mkdir /opt/_transfer
mv -r transfer/. /opt/_transfer/

## Move .zsh stuff to ~
mv -r zsh/. /root/

## Download tools

#Burp
cd /root/lab
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
go get github.com/ropnop/kerbrute
cd kerbrute
make all

#Ligolo
cd /opt/
git clone https://github.com/nicocha30/ligolo-ng.git
cd ligolo-ng
go build -o agent cmd/agent/main.go
go build -o proxy cmd/proxy/main.go
GOOS=windows go build -o agent.exe cmd/agent/main.go

#SSTImap
cd /opt/
git clone https://github.com/vladko312/SSTImap.git
cd SSTImap
pip3 install -r requirements.txt

#EZPZ
cd /opt/
mkdir ezpz; cd ezpz
wget https://github.com/chsoares/ezpz/raw/main/ezpz.sh
chmod +x ezpz.sh

#Creds
pip3 install defaultcreds-cheat-sheet
