#!/usr/bin/bash

echo Loading...

#Check Connection
export ping_test=$(ping -c1 google.com | grep PING)

if [ "$ping_test" = "" ] ; then
        echo -e "\n\e[91mCheck current connection: FAIL\e[0m" ; else
        echo -e "\nCheck current connecttion:\n\e[92m$ping_test\e[0m" ; fi

#Check necessary package
if [ -x /usr/bin/iw ] || [ -x /usr/sbin/iw ] ; then
        echo -e '\n\e[96mScan wifi by iw\e[0m' ; else
        echo -e '\n\e[91mNOTICE: iw is missing to scan wifi\e[0m' ; fi

if [ -x /usr/bin/wpa_supplicant ] || [ -x /usr/sbin/wpa_supplicant ] ; then
        echo -e '\n\e[96mConnect wifi by wpa_supplicant\e[0m' ; else
        echo -e '\n\e[91mNOTICE: wpa_supplicant is missing to connect wifi\e[0m' ; fi

if [ -x /usr/bin/dhcpcd ] || [ -x /usr/sbin/dhcpcd ] ; then
        echo -e '\n\e[96mConfigure dns by dhcpcd\e[0m' ; else
        echo -e '\n\e[91mNOTICE: dhcpcd is missing to configure dns\e[0m' ;
        exit ; fi

#Menu and Choices
echo -e '\nConnect Wifi or Ethernet \n(Type 1 or 2) \n\e[93m1\e[0m. Wifi \n\e[93m2\e[0m. Ethernet\n'
echo -ne '\e[95mType \e[93m(1 or 2)\e[95m then press Enter:\e[0m '
read choice

case $choice in

1)
#Wifi

#Environment variables
export wifi_dev=$(ip a | grep -o '\bwl[^[:space:]]*'|grep :|sed 's/://g')
export wifi_connectability=$(
        ls /usr/bin | grep -qx wpa_supplicant \
        || ls /usr/sbin | grep -qx wpa_supplicant \
        && echo -e '\nconnect by wpa_supplicant' \
        || echo -e '\nNOTICE: wpa_supplicant is missing to connect wifi')
export wifi_scanability=$(
        ls /usr/bin | grep -qx iw \
        || ls /usr/sbin | grep -qx iw \
        && echo -e '\nscan by iw' \
        || echo -e '\nNOTICE: iw is missing to scan wifi')

echo "$wifi_connectability" | grep -qx 'NOTICE: wpa_supplicant is missing to connect wifi' \
        && echo -e '\n\e[91mNOTICE: wpa_supplicant is missing to connect wifi\e[0m' && exit

echo $wifi_scanability | grep -q 'scan by' && export wifi_list=$(
        echo $(iw dev $wifi_dev scan |grep SSID:) \
        | sed 's/ SSID: /\\n/g' | sed 's/SSID: /\\n/g')

#Main process
if [ "$wifi_dev" = "" ] ; then
        echo -e '\e[91mWifi device not found\e[0m' ;
        exit ; else
        ip link set $wifi_dev up ; fi
echo $wifi_scanability | grep -q 'scan by' \
        && echo -e "\n$(iw dev $wifi_dev scan |grep SSID:|echo -e "$(sed 's/SSID: /\\e[0mSSID: \\e[93m/g')")\n" \
        || echo -e '\n\e[91mNOTICE: iw is missing to scan wifi\e[0m\n'

echo -ne '\e[95mType Wifi \e[93mname\e[95m then press Enter \e[93m(Include Checking Process)\e[95m:\e[0m '
read wifi_name

export ssid_validation=$(
        echo -e "\nSSID: \e[93m$wifi_name\e[0m is $(echo -e "$wifi_list" \
        | grep -qx "$wifi_name" && echo 'Valid. PERFECT.' \
        || echo -e '\e[91mInvalid\e[0m. \e[96mRequire Script Restart.\e[0m')\n")

echo $wifi_scanability | grep -qx 'scan by iw' \
        && echo "$ssid_validation" \
        && echo "$ssid_validation" \
        | grep -q Restart \
        && exit

echo $wifi_scanability | grep -qx 'scan by iw' \
        || echo -e "\n\e[91mCannot Checking: iw is missing to scan wifi\e[0m\n"

echo -ne '\n\e[95mType Wifi \e[93mpassword\e[95m then press Enter \e[93m(No Checking Process)\e[95m:\e[0m '
read wifi_pass

wpa_passphrase "$wifi_name" "$wifi_pass" > /etc/wpa_supplicant/wifi_name_pass.conf
wpa_supplicant -i $wifi_dev -B -c /etc/wpa_supplicant/wifi_name_pass.conf
cat /etc/dhcpcd.conf | grep "interface $wifi_dev" \
        || echo -e "interface $wifi_dev\nstatic domain_name_servers=1.1.1.1 1.0.0.1" >> /etc/dhcpcd.conf
dhcpcd $wifi_dev
echo -e 'nameserver 1.1.1.1\nnameserver 1.0.0.1' > /etc/resolv.conf

;;

2)
#Ethermet

#Environment variables
export ethernet_dev=$(ip a | grep -o '\ben[^[:space:]]*'|grep :|sed 's/://g')

#Main process
cat /etc/dhcpcd.conf | grep "interface $ethernet_dev" \
        || echo -e "interface $ethernet_dev\nstatic domain_name_servers=1.1.1.1 1.0.0.1" >> /etc/dhcpcd.conf
dhcpcd $ethernet_dev
echo -e 'nameserver 1.1.1.1\nnameserver 1.0.0.1' > /etc/resolv.conf

;;

esac

