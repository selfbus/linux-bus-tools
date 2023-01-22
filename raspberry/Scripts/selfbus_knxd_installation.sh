#!/bin/bash

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
# 2018-01-07    v1.00: First version. Made for fresh RPi Stretch or Jessie installations.
#               No script interaction, no error handling.
#               After calling the script and doing a reboot knxd should be found by ETS
# 2018-01-09    v1.01: Adaption for RPi3 + bigfixes
# 2018-01-18    v1.02: switch to stable knxd repository; minor improvements
# 2022-11-19	v2.00: reworked whole script; 
#			switch to debian branch
#			more robust dependency installation
# 			TPUART / FT1.2 supported
#			


if [ `id -u` = 0 ];then
echo '
                _____      ________
  __/|___/|_   / ___/___  / / __/ /_  __  _______   __/|___/|_
 |    /    /   \__ \/ _ \/ / /_/ __ \/ / / / ___/  |    /    /
/_ __/_ __|   ___/ /  __/ / __/ /_/ / /_/ (__  )  /_ __/_ __|
 |/   |/     /____/\___/_/_/ /_.___/\__,_/____/    |/   |/

    ____  ____  _    __  _____  ______   ____           __        ____
   / __ \/ __ \(_)  / / / /   |/_  __/  /  _/___  _____/ /_____ _/ / /__  _____
  / /_/ / /_/ / /  / /_/ / /| | / /     / // __ \/ ___/ __/ __ `/ / / _ \/ ___/
 / _, _/ ____/ /  / __  / ___ |/ /    _/ // / / (__  ) /_/ /_/ / / /  __/ /
/_/ |_/_/   /_/  /_/ /_/_/  |_/_/    /___/_/ /_/____/\__/\__,_/_/_/\___/_/
';

#    echo "   *** Annahmen: "; sleep 1
    echo '   ***   * frisches raspian stretch oder jessie (ohne eibd) '; sleep 1
#    echo "   ***   * user: pi"; sleep 1
#    echo "   ***   * installiertes FT1.2 Modul"; sleep 1
    echo "   ***   "
#    echo "   *** Skript enthaelt bisher keine Fehlerpruefung! --> Daumen druecken, dass alles gut laeuft!" ; sleep 1
    echo "   *** Installation startet in 5 Sekunden. "
#    sleep 5
else
    echo Bitte mit sudo ausfuehren!
    exit 1
fi



kernelsserial=`udevadm info -a /dev/ttyAMA0 | grep KERNELS.*serial | sed "s|.*\"\(.*\)\".*|\\1|"`
attrsid=`udevadm info -a /dev/ttyAMA0 | grep \{id\} | sed "s|.*\"\(.*\)\".*|\\1|"`
neededpackages=
rpigeneration=`cat /proc/cpuinfo | grep Revision | sed s/"Revision.*: "/""/g`
installdate=`date +%Y-%m-%d-%H%M%S`
non_bt_rpis="0002 0003 0004 0005 0006 0007 0008 0009 000d 000e 000f 0010 0011 0012 0013 0014 0015 900021 900032 900092 900093 9000c1 920092 920093 900061 a01040 a01041 a020a0 a02042 a21041 a22042 a220a0"



# Zugrundeliegende OS Version prÃ¼fen
# je nach Version werden leicht unterschiedliche Softwarepakete benÃ¶tigt
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
    echo "   *** Weder Debian Stretch (Verison 9) noch Jessie (Version 8) erkannt. Gehe von neuerer Version aus und wir versuchen mal unser GlÃ¼ck."
fi



echo "   *** Passe /boot/cmdline.txt an, um Ausgabe der Konsole auf serielle Schnittstelle zu unterbinden."
#sleep 2
sed -i s/"console=serial0,115200"/""/g /boot/cmdline.txt

echo "   *** Stelle Zeitzone auf Europe/Berlin."
#sleep 2
mv /etc/localtime /etc/localtime-old
ln -sf /usr/share/zoneinfo/Europe/Berlin /etc/localtime

echo "   *** Aktualisiere System"
#sleep 1
apt update
apt -y upgrade

echo "   *** Hole notwendige Pakete"
sleep 1
apt install -y $neededpackages

echo "   *** Stoppe ggf. bereits laufenden KNXD "
sleep 1
systemctl stop knxd.service
systemctl stop knxd.socket

echo "   *** Hole knxd aus Git und uebersetze knxd. Das dauert eine Weile!"
#sleep 1
#su -c "mkdir /home/selfbus/knxd_install_$installdate && cd /home/selfbus/knxd_install_$installdate && git clone -b stable https://github.com/knxd/knxd.git && cd /home/selfbus/knxd_install_$installdate/knxd && git checkout debian" selfbus

echo "   *** ACHTUNG" ; sleep 2
apt install -y devscripts equivs
#su -c "mk-build-deps --install --root-cmd sudo --remove" selfbus 
#su -c "cd /home/selfbus/knxd_install_$installdate/knxd && dpkg-buildpackage -b -uc > /home/selfbus/knxd_install_$installdate/make_log.txt" selfbus

echo "   *** AAAAARRRGHH "
pwd
sleep 2

su -c "mkdir /home/selfbus/knxd_install_$installdate && cd /home/selfbus/knxd_install_$installdate && git clone -b debian https://github.com/knxd/knxd.git && cd /home/selfbus/knxd_install_$installdate/knxd && git checkout debian  && cd /home/selfbus/knxd_install_$installdate/knxd && sudo mk-build-deps --install --tool='apt-get --no-install-recommends --yes --allow-unauthenticated' debian/control && cd /home/selfbus/knxd_install_$installdate/knxd && libtoolize && cd /home/selfbus/knxd_install_$installdate/knxd && sudo dpkg-buildpackage -b -uc > /home/selfbus/knxd_install_$installdate/make_log.txt" selfbus
# mk-build-deps --install  --root-cmd sudo --remove && \


echo "   *** installiere knxd..."
sleep 1
cd /home/selfbus/knxd_install_$installdate
dpkg -i knxd_*.deb knxd-tools_*.deb


echo "   *** Passe /etc/knxd.conf und /boot/config.txt an"
cp /etc/knxd.conf /etc/knxd.conf.bkp-$installdate
sed -i '/^KNXD_OPTS=/s/=.*/="-e 0.0.0 -E 0.0.1:8 -D -R -T -S -i --trace=15 -b ft12:\/dev\/ttyKNX1"/' /etc/knxd.conf
cp /boot/config.txt /boot/config.txt.bkp-$installdate
sed -i '/^enable_uart=/s/=.*/=1/' /boot/config.txt 



if [[ " $non_bt_rpis " =~ .*\ $rpigeneration\ .* ]]; then
    echo "   *** RPi 1 / RPi 2 erkannt. No bluetooth existing on these models."; sleep 1
else
#    echo "   *** RPi 3 or newer identified. Disable bluetooth."; sleep 1
    if [ `cat /boot/config.txt | grep pi3-disable-bt`  ]; then
        sed -i '/^.*pi3-disable-bt/s/.*/dtoverlay=pi3-disable-bt/'  /boot/config.txt
	echo "Eintrag zum bt schon drin"
    else 
        echo "# disable bluetooth" >> /boot/config.txt
        echo 'dtoverlay=pi3-disable-bt' >> /boot/config.txt
    fi
fi



#if [ $rpigeneration != "900021" ]; then
#    echo "   *** Kein RPi 1 / RPi 2 erkannt. Deaktiviere Bluetooth"; sleep 1
#    
#    if [ `cat /boot/config.txt | grep pi3-disable-bt`  ]; then
#        sed -i '/^.*pi3-disable-bt/s/.*/dtoverlay=pi3-disable-bt/'  /boot/config.txt
#    else 
#        echo "# disable bluetooth" >> /boot/config.txt
#        echo 'dtoverlay=pi3-disable-bt' >> /boot/config.txt
#   fi
#fi

echo "   *** Stelle Kommunikationspunkt auf ttyKNX1 um"
#sleep 1
echo "ACTION==\"add\", SUBSYSTEM==\"tty\", ATTRS{id}==\"$attrsid\", KERNELS==\"$kernelsserial\", SYMLINK+=\"ttyKNX1\", OWNER=\"knxd\"" > /etc/udev/rules.d/70-knxd.rules

systemctl disable hciuart

echo "   *** "
echo "   *** Fertig! Wenn keine Fehler aufgetreten sind:"
echo "   *** Bitte System mit sudo reboot neu starten. Dann SOLLTE die ETS den knxd finden!"