#!/bin/bash

###
### SIGdeb Install GR_GSM
###
### 

###
###
### This script is part of the SIGbox Project.
###
### Applications and driver updates include
###
### - GR-GSM
###

##
## INIT VARIABLES AND DIRECTORIES
##

# Package Versions

# Source Directory
SIGDEB_SOURCE=$HOME/source

# Executable Directory (will be created as root)
SIGDEB_OPT=/opt/SIGdeb
SIGDEB_EXE=$SIGDEB_OPT/bin

# SIGdeb Home directory
SIGDEB_HOME=$SIGDEB_SOURCE/SIGbox

# SDRangel Source directory
SIGDEB_SDRANGEL=$SIGDEB_SOURCE/SDRangel

# Desktop directories
SIGDEB_DESKTOP=$SIGDEB_HOME/desktop
SIGDEB_BACKGROUNDS=$SIGDEB_DESKTOP/backgrounds
SIGDEB_ICONS=$SIGDEB_DESKTOP/icons
SIGDEB_LOGO=$SIGDEB_DESKTOP/logo
SIGDEB_MENU=$SIGDEB_DESKTOP/menu

# Desktop Destination Directories
DESKTOP_DIRECTORY=/usr/share/desktop-directories
DESKTOP_FILES=/usr/share/applications
DESKTOP_ICONS=/usr/share/icons
DESKTOP_XDG_MENU=/usr/share/extra-xdg-menus

# SIGdeb Menu category
SIGDEB_MENU_CATEGORY=SIGdeb

# SIGdeb SSL Cert and Key
SIGDEB_API_SSL_KEY=$SIGDEB_HOME/SIGdeb_api.key
SIGDEB_API_SSL_CRT=$SIGDEB_HOME/SIGdeb_api.crt


##
## START
##

echo "### "
echo "### "
echo "###  SIGdeb - GR-GSM Install"
echo "### "
echo "### "
echo " "

#
# INSTALL GR-GSM (requires GNUradio 3.8)
#

echo " "
echo " ##"
echo " ##"
echo " - Install GR-GSM"
echo " ##"
echo " ##"
echo " "
sudo apt-get install -y osmo-sdr libosmosdr-dev
sudo apt-get install -y libosmocore libosmocore-dev
sudo apt-get install -y libosmocore-utils
sudo dpkg -L libosmocore-utils
cd $SIGDEB_SOURCE
git clone https://git.osmocom.org/gr-gsm
cd gr-gsm
mkdir build && cd build
cmake ..
make -j4
sudo make install
sudo ldconfig
echo 'export PYTHONPATH=/usr/local/lib/python3/dist-packages/:$PYTHONPATH' >> ~/.bashrc

#
# Copy Menuitems into relevant directories
# 

#sudo cp $SIGDEB_MENU/sigdeb_example.desktop $DESKTOP_FILES
sudo cp $SIGDEB_MENU/SIGdeb.directory $DESKTOP_DIRECTORY
sudo cp $SIGDEB_MENU/SIGdeb.menu $DESKTOP_XDG_MENU
sudo cp $SIGDEB_ICONS/* $DESKTOP_ICONS
sudo cp /usr/local/share/Lime/Desktop/lime-suite.desktop $DESKTOP_FILES
sudo cp $SIGDEB_MENU/*.desktop $DESKTOP_FILES
sudo ln -s $DESKTOP_XDG_MENU/SIGdeb.menu /etc/xdg/menus/applications-merged/SIGdeb.menu

#
# Add SIGdeb Category for each installed application
#

sudo sed -i "s/Categories.*/Categories=$SIGDEB_MENU_CATEGORY;/" /usr/local/share/gnuradio-grc.desktop

echo "*** "
echo "*** "
echo "***   UPDATEE COMPLETE"
echo "*** "
echo "*** "
echo " "
exit 0