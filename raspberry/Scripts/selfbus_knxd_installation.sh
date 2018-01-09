#!/bin/sh

# Copyright (c) 2018 Christian Balzer <christian-balzer@gmx.de>
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# History
# 2018-01-07    First version. Made for fresh RPi Stretch or Jessie installations. 
#               No script interaction, no error handling. 
#               After calling the script and doing a reboot knxd should be found by ETS


if [ `id -u` = 0 ];then
    echo "   *** Annahmen: frisches raspian stretch oder jessie. User: Pi" 
    echo "   *** Skript enthaelt bisher keine Fehlerpruefung! --> Daumen druecken, dass alles gut laeuft!" 
    echo "   *** Installation startet in 5 Sekunden. "
    sleep 5
else
    echo Bitte mit sudo ausfuehren!
    exit 1
fi

kernelsserial=`udevadm info -a /dev/ttyAMA0 | grep KERNELS.*serial | sed "s|.*\"\(.*\)\".*|\\1|"`
attrsid=`udevadm info -a /dev/ttyAMA0 | grep \{id\} | sed "s|.*\"\(.*\)\".*|\\1|"`
neededpackages=

# Zugrundeliegende OS Version prüfen
# je nach Version werden leicht unterschiedliche Softwarepakete benötigt
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$NAME
    VER=$VERSION_ID
fi

if [ $VER = 9 ]
then
    neededpackages="debhelper automake libtool libusb-1.0-0-dev git-core build-essential libsystemd-dev dh-systemd libev-dev cmake mc"
    echo "   *** erkannte Debian-Version: $VER"
elif [ $VER = 8 ]
then
    neededpackages="debhelper automake libtool libusb-1.0-0-dev git-core build-essential libsystemd-daemon-dev dh-systemd libev-dev cmake mc"
    echo "   *** erkannte Debian-Version: $VER"
else 
    neededpackages="debhelper automake libtool libusb-1.0-0-dev git-core build-essential libsystemd-dev dh-systemd libev-dev cmake mc"
    echo "   *** erkannte Debian-Version: $VER"
    echo "   *** Weder Debian Stretch (Verison 9) noch Jessie (Version 8) erkannt. Gehe von neuerer Version aus und wir versuchen mal unser Glück."
fi
    

echo "   *** Passe /boot/cmdline.txt an, um Ausgabe der Konsole auf serielle Schnittstelle zu unterbinden."
sleep 2
sed -i s/"console=serial0,115200"/""/g /boot/cmdline.txt

echo "   *** Stelle Zeitzone auf Europe/Berlin."
sleep 2
mv /etc/localtime /etc/localtime-old
ln -sf /usr/share/zoneinfo/Europe/Berlin /etc/localtime

echo "   *** Aktualisiere System"
sleep 1
apt-get update
apt-get -y upgrade

echo "   *** Hole notwendige Pakete"
sleep 1
apt-get install -y $neededpackages 

echo "   *** Hole knxd aus Git und uebersetze knxd. Das dauert eine Weile!" 
sleep 1
su -c 'cd ~ && git clone https://github.com/knxd/knxd.git && cd ~/knxd/ && git checkout master && dpkg-buildpackage -b -uc' pi 

echo "   *** installiere knxd..."
sleep 1
dpkg -i knxd_*.deb knxd-tools_*.deb 

echo "   *** Passe /etc/knxd.conf und /boot/config.txt an"
cp /etc/knxd.conf /etc/knxd.conf.bkp 
sed -i '/^KNXD_OPTS=/s/=.*/="-e 0.0.0 -E 0.0.1:8 -D -R -T -S -i --trace=15 -b ft12:\/dev\/ttyKNX1"/' /etc/knxd.conf 
cp /etc/knxd.conf /etc/knxd.conf.bkp
sed -i '/^enable_uart=/s/=.*/=1/' /boot/config.txt

echo "   *** Stelle Kommunikationspunkt auf ttxKNX1 um"
sleep 1
echo "ACTION==\"add\", SUBSYSTEM==\"tty\", ATTRS{id}==\"$attrsid\", KERNELS==\"$kernelsserial\", SYMLINK+=\"ttyKNX1\", OWNER=\"knxd\"" > /etc/udev/rules.d/70-knxd.rules

echo "   *** "
echo "   *** Fertig! Wenn keine Fehler aufgetreten sind:"
echo "   *** Bitte System mit sudo reboot neu starten. Dann SOLLTE die ETS den knxd finden!"