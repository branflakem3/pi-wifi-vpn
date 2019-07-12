#!/bin/bash
# Script used to complete the setup of a raspberry pi as a WiFi AP, all WiFi clients will be directed through the VPN

if [ ! "`whoami`" = "root" ]
then
    echo -e "\e[7m*!! Please run script using 'sudo' !!*"
    exit 1
fi

sudo apt-get update
sudo apt-get upgrade -y

###################################################################
# Change Raspberry Pi keyboard layout to US
###################################################################
echo " ++ Creating keyboard (Eng_US) diff file"
cat > ./keyboarddiff.conf << EOL
5c
XKBMODEL="pc101"
.
6c
XKBLAYOUT="us"
.
EOL
sleep 1
sudo echo "w" >> ./keyboarddiff.conf
sleep 1
echo " ++ Applying Keyboard (Eng_US) diff file ++"
sleep 1
sudo ed - /etc/default/keyboard < keyboarddiff.conf
sleep 1
echo ""
###################################################################
# Start install of hostapd and dnsmasq
###################################################################
echo " ++ Starting install of hostapd and dnsmasq"
sudo apt-get install hostapd dnsmasq -y
sleep 2

# Stop services hostapd and dnsmasq
echo " ++ Stopping services hostapd and dnsmasq"
sudo systemctl stop hostapd
sudo systemctl stop dnsmasq

# Add config for wlan0 to dhcpcd.conf
echo " ++ Creating dhcpcd.conf entry for wlan0 - 192.168.220.1/24"
echo 'interface wlan0' >> /etc/dhcpcd.conf
echo '    static ip_address=192.168.220.1/24' >> /etc/dhcpcd.conf
echo '    nohook wpa_supplicant' >> /etc/dhcpcd.conf

# Restart dhcpcd service
echo " ++ Restarting dhcpcd service"
sudo systemctl restart dhcpcd

# Add SSID and WiFi PSK details
echo " Edit SSID and PSK values in the text editor"
sudo nano /etc/hostapd/hostapd.conf

# Edit the config for hostapd to use the hostapd.conf file
echo " Edit the config for hostapd to use the hostapd.conf file"
echo ' DAEMON_CONF="/etc/hostapd/hostapd.conf"'
sudo nano /etc/default/hostapd

# Edit the config for hostapd to use the hostapd.conf file
echo " Edit the config for hostapd to use the hostapd.conf file"
echo ' DAEMON_CONF="/etc/hostapd/hostapd.conf"'
sudo nano /etc/init.d/hostapd

sudo mv /etc/dnsmasq.conf /etc/dnsmasq.conf.orig
echo 'interface=wlan0       # Use interface wlan0  ' >> /etc/dnsmasq.conf
echo 'server=1.1.1.1       # Use Cloudflare DNS  ' >> /etc/dnsmasq.conf
echo 'dhcp-range=192.168.220.50,192.168.220.150,12h # IP range and lease time  ' >> /etc/dnsmasq.conf

echo " Uncomment this line - #net.ipv4.ip_forward=1"
sudo nano /etc/sysctl.conf

sudo systemctl unmask hostapd
sudo systemctl enable hostapd
sudo systemctl start hostapd
sudo service dnsmasq start

echo "++ Installing openvpn"
sudo apt-get install openvpn -y
cd /etc/openvpn

echo "++ Type your username and password in this file"
echo " sudo nano /etc/openvpn/auth.txt"
sudo nano /etc/openvpn/auth.txt

# Copy openvpn ovpn file into /etc/openvpn and give it the .conf extension"
echo " ++ Copy openvpn ovpn file into /etc/openvpn and give it the .conf extension"

# sudo nano abovefile.conf
# change auth-user-pass to
# auth-user-pass auth.txt

# TEST IT
#sudo openvpn --config "/etc/openvpn/vpn.conf"

# Clear iptables
echo " ++ Clearing iptables"
sudo iptables -F
sudo iptables -t nat -F
sudo iptables -X

# Route wlan0 traffic over tunnel
sudo iptables -t nat -A POSTROUTING -o tun0 -j MASQUERADE

# Save iptables
sudo sh -c "iptables-save > /etc/iptables.ipv4.nat"

# Add saved iptables config on boot
# sudo nano /etc/rc.local
# Add this above exit 0
# iptables-restore < /etc/iptables.ipv4.nat

# Configure autostart
# sudo nano /etc/default/openvpn
# #autostart="all"
# to
# autostart="vpn"

# Prevent DNS Leaks
# sudo nano /etc/dhcpcd.conf
# REPLACE
# #static domain_name_servers=192.168.0.1
# with
# static domain_name_servers=1.1.1.1








sudo reboot
