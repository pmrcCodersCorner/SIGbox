#!/bin/bash

###
### SIGbox_Install_GR-GSM
###
### 

### 20121015 - Broken - Need to address device conf;icy since osmosdr not found

###
### INIT VARIABLES AND DIRECTORIES
###

# Package Versions
HAMLIB_VER="hamlib-4.3"
GNURADIO_VER="gnuradio_3.8.1"
FLDIGI_VERPKG="fldigi-4.1.06"
WSJTX_VER="wsjtx_2.5.0"
QSSTV_VER="qsstv_9.4.4"

# Package Source Directory
SIGBOX_SOURCE=$HOME/source

# SIGbox Home directory
SIGBOX_HOME=$SIGBOX_SOURCE/SIGdeb

# SDRangel Source directory
SIGBOX_SDRANGEL=$SIGBOX_SOURCE/SDRangel

# SDR++ Source directory
SIGBOX_SDRPLUSPLUS=$SIGBOX_SOURCE/SDRplusplus

# Desktop Files
SIGBOX_THEMES=$SIGBOX_HOME/themes
SIGBOX_BACKGROUNDS=$SIGBOX_THEMES/backgrounds
SIGBOX_ICONS=$SIGBOX_THEMES/icons
SIGBOX_PIXMAPS=$SIGBOX_THEMES/pixmaps
SIGBOX_DESKTOP=$SIGBOX_THEMES/desktop
SIGBOX_MENU_CATEGORY=SIGbox

# Desktop Destination Directories
DESKTOP_DIRECTORY=/usr/share/desktop-directories
DESKTOP_FILES=/usr/share/applications
DESKTOP_ICONS=/usr/share/icons
DESKTOP_PIXMAPS=/usr/share/pixmaps
DESKTOP_XDG_MENU=/usr/share/extra-xdg-menus

# SIGbox Install Support files
SIGBOX_CONFIG=$SIGBOX_HOME/SIGbox_config
SIGBOX_INSTALL_TXT1=$SIGBOX_HOME/updates/SIGbox-installer-1.txt
SIGBOX_BANNER_COLOR="\e[0;104m\e[K"   # blue
SIGBOX_BANNER_RESET="\e[0m"

install_gr-gsm(){

    sudo apt-get install -y osmo-sdr libosmosdr-dev
    sudo apt-get install -y libosmocore libosmocore-dev
    sudo apt-get install -y libosmocore-utils
    sudo dpkg -L libosmocore-utils
    cd $SIGBOX_SOURCE
    git clone https://git.osmocom.org/gr-gsm
    cd gr-gsm
    mkdir build && cd build
    cmake ..
    make -j4
    sudo make install
    sudo ldconfig
    echo 'export PYTHONPATH=/usr/local/lib/python3/dist-packages/:$PYTHONPATH' >> ~/.bashrc
}

###
###  MAIN
###

install_gr-gsm

echo -e "${SIGBOX_BANNER_COLOR}"
echo -e "${SIGBOX_BANNER_COLOR} #SIGBOX#"
echo -e "${SIGBOX_BANNER_COLOR} #SIGBOX#   Install GR-GSM"
echo -e "${SIGBOX_BANNER_COLOR} #SIGBOX#"
echo -e "${SIGBOX_BANNER_RESET}"

#
# Copy Menu items into relevant directories
# 
	
cp $SIGBOX_DESKTOP/SIGbox*.desktop /home/$USER/Desktop
sudo cp $SIGBOX_DESKTOP/sdrangel.desktop $DESKTOP_DIRECTORY
sudo cp /opt/install/sdrangel/share/icons/hicolor/scalable/apps/sdrangel_icon.svg $DESKTOP_ICONS
sudo cp /opt/install/sdrangel/share/icons/hicolor/scalable/apps/sdrangel_icon.svg $DESKTOP_PIXMAPS