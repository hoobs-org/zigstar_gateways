#!/bin/bash

PORT=/dev/ttyAMA0
RST_PIN=24
BSL_PIN=27

CYAN='\033[1;36m'
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

echo -e "${CYAN}Running Pi_Flasher_CC2538 script${NC}"
sleep 3
if [ $1 ]; then
  PORT=$1
fi
echo -e "${CYAN}Flash port set to $PORT${NC}"

if [ $2 ]; then
  RST_PIN=$2
fi
echo -e "${CYAN}RST pin set to $RST_PIN${NC}"

if [ $3 ]; then
  BSL_PIN=$3
fi
echo -e "${CYAN}BSL pin set to $BSL_PIN${NC}"

echo
echo -e "${CYAN}Installing dependencies${NC}"
apt install -y git unzip python3 python3-pip pigpio
pip3 install pyserial intelhex


echo
echo -e "${CYAN}Cloning flash tool and firmware${NC}"
rm -rf cc2538-bsl && rm -rf CC1352P2_CC2652P_launchpad_coordinator_20230507.zip -rf CC1352P2_CC2652P_launchpad_coordinator_20230507.hex
git clone https://github.com/JelmerT/cc2538-bsl.git
wget https://github.com/Koenkk/Z-Stack-firmware/blob/master/coordinator/Z-Stack_3.x.0/bin/CC1352P2_CC2652P_launchpad_coordinator_20230507.zip

echo
echo -e "${CYAN}Unpacking latest hex file${NC}"
unzip /CC1352P2_CC2652P_launchpad_coordinator_20230507.zip
echo $hexfile


echo
echo -e "${CYAN}Enable BSL and RST pins${NC}"
if [ ! -e /sys/class/gpio/gpio$BSL_PIN ]; then
    echo $BSL_PIN > /sys/class/gpio/export
fi
echo out > /sys/class/gpio/gpio$BSL_PIN/direction

if [ ! -e /sys/class/gpio/gpio$RST_PIN ]; then
    echo $RST_PIN > /sys/class/gpio/export
fi
echo out > /sys/class/gpio/gpio$RST_PIN/direction

echo
echo -e "${CYAN}Enable BSL mode and restart ZigBee${NC}"
echo 0 > /sys/class/gpio/gpio$BSL_PIN/value
echo 0 > /sys/class/gpio/gpio$RST_PIN/value
echo 1 > /sys/class/gpio/gpio$RST_PIN/value

echo
echo -e "${CYAN}Wait 4 seconds before start${NC}"
sleep 4

echo
echo -e "${CYAN}Disable BSL mode${NC}"
echo 1 > /sys/class/gpio/gpio$BSL_PIN/value

echo
echo -e "${CYAN}Flashing${NC}"
python3 cc2538-bsl/cc2538-bsl.py -p $PORT -ewv $hexfile

echo
echo -e "${CYAN}Restart ZigBee${NC}"
echo 0 > /sys/class/gpio/gpio$RST_PIN/value
echo 1 > /sys/class/gpio/gpio$RST_PIN/value

echo
echo -e "${RED}Deleting all files${NC}"
rm -rf cc2538-bsl && rm -rf zigbee-firmware
rm $hexfile
rm -- "$0"
echo
echo -e "${GREEN}Flashing complete${NC}"
