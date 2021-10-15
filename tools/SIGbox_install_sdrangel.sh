#!/bin/bash

###
### SIGbox_install_sdrangel
###

###
###   REVISION: 20211014-2300
###

###
### This script is part of the SIGbox Project.
###
### Given a Ubunto 20.04 desktop installation, this script installs drivers and applications
### to build a SDR station for use in signal intelligences.
###

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
SIGBOX_SDRPLUSPLUS=$SIGBOX_SOURCE/SDplusplus

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


###
### FUNCTIONS
###


install_sdrangel_compile(){
	echo -e "${SIGBOX_BANNER_COLOR}"
	echo -e "${SIGBOX_BANNER_COLOR} #SIGBOX#"
	echo -e "${SIGBOX_BANNER_COLOR} #SIGBOX#   Install SDRangel"
	echo -e "${SIGBOX_BANNER_COLOR} #SIGBOX#"
	echo -e "${SIGBOX_BANNER_RESET}"
	cd $SIGBOX_SOURCE
    sudo mkdir -p /opt/build
	sudo chown $USER:users /opt/build
	sudo mkdir -p /opt/install
	sudo chown $USER:users /opt/install

	# SDRangel Dependencies
	sudo apt-get install -y git cmake g++ pkg-config autoconf automake libtool libfftw3-dev libusb-1.0-0-dev libusb-dev \
	qtbase5-dev qtchooser libqt5multimedia5-plugins qtmultimedia5-dev libqt5websockets5-dev qttools5-dev qttools5-dev-tools libqt5opengl5-dev \
	qtbase5-dev libqt5quick5 libqt5charts5-dev qml-module-qtlocation  qml-module-qtlocation qml-module-qtpositioning qml-module-qtquick-window2 \
	qml-module-qtquick-dialogs qml-module-qtquick-controls qml-module-qtquick-controls2 qml-module-qtquick-layouts \
	libqt5serialport5-dev qtdeclarative5-dev qtpositioning5-dev qtlocation5-dev libqt5texttospeech5-dev \
	libfaad-dev zlib1g-dev libboost-all-dev libasound2-dev pulseaudio libopencv-dev libxml2-dev bison flex \
	ffmpeg libavcodec-dev libavformat-dev libopus-dev doxygen graphviz

	# APT
	# Aptdec is a FOSS program that decodes images transmitted by NOAA weather satellites.
    cd $SIGBOX_SDRANGEL
	git clone https://github.com/srcejon/aptdec.git
	cd aptdec
	git checkout libaptdec
	mkdir build; cd build
	cmake -Wno-dev -DCMAKE_INSTALL_PREFIX=/opt/install/aptdec ..
	make -j $(nproc) install

	# CM265cc
    cd $SIGBOX_SDRANGEL
	git clone https://github.com/f4exb/cm256cc.git
	cd cm256cc
	git reset --hard c0e92b92aca3d1d36c990b642b937c64d363c559
	mkdir build; cd build
	cmake -Wno-dev -DCMAKE_INSTALL_PREFIX=/opt/install/cm256cc ..
	make -j $(nproc) install

	# LibDAB
    cd $SIGBOX_SDRANGEL
	git clone https://github.com/srcejon/dab-cmdline
	cd dab-cmdline/library
	git checkout msvc
	mkdir build; cd build
	cmake -Wno-dev -DCMAKE_INSTALL_PREFIX=/opt/install/libdab ..
	make -j $(nproc) install

	# MBElib
    cd $SIGBOX_SDRANGEL
	git clone https://github.com/szechyjs/mbelib.git
	cd mbelib
	git reset --hard 9a04ed5c78176a9965f3d43f7aa1b1f5330e771f
	mkdir build; cd build
	cmake -Wno-dev -DCMAKE_INSTALL_PREFIX=/opt/install/mbelib ..
	make -j $(nproc) install

	# SerialDV
    cd $SIGBOX_SDRANGEL
	git clone https://github.com/f4exb/serialDV.git
	cd serialDV
	git reset --hard "v1.1.4"
	mkdir build; cd build
	cmake -Wno-dev -DCMAKE_INSTALL_PREFIX=/opt/install/serialdv ..
	make -j $(nproc) install

	# DSDcc
    cd $SIGBOX_SDRANGEL
	git clone https://github.com/f4exb/dsdcc.git
	cd dsdcc
	git reset --hard "v1.9.3"
	mkdir build; cd build
	cmake -Wno-dev -DCMAKE_INSTALL_PREFIX=/opt/install/dsdcc -DUSE_MBELIB=ON -DLIBMBE_INCLUDE_DIR=/opt/install/mbelib/include -DLIBMBE_LIBRARY=/opt/install/mbelib/lib/libmbe.so -DLIBSERIALDV_INCLUDE_DIR=/opt/install/serialdv/include/serialdv -DLIBSERIALDV_LIBRARY=/opt/install/serialdv/lib/libserialdv.so ..
	make -j $(nproc) install

	# Codec2/FreeDV
	# Codec2 is already installed from the packager, but this version is required for SDRangel.
    cd $SIGBOX_SDRANGEL
	git clone https://github.com/drowe67/codec2.git
	cd codec2
	git reset --hard 76a20416d715ee06f8b36a9953506876689a3bd2
	mkdir build_linux; cd build_linux
	cmake -Wno-dev -DCMAKE_INSTALL_PREFIX=/opt/install/codec2 ..
	make -j $(nproc) install

	# SGP4
	# python-sgp4 1.4-1 is available in the packager, installing this version just to be sure.
    cd $SIGBOX_SDRANGEL
	git clone https://github.com/dnwrnr/sgp4.git
	cd sgp4
	mkdir build; cd build
	cmake -Wno-dev -DCMAKE_INSTALL_PREFIX=/opt/install/sgp4 ..
	make -j $(nproc) install

	# LibSigMF
    cd $SIGBOX_SDRANGEL
	git clone https://github.com/f4exb/libsigmf.git
	cd libsigmf
	git checkout "new-namespaces"
	mkdir build; cd build
	cmake -Wno-dev -DCMAKE_INSTALL_PREFIX=/opt/install/libsigmf .. 
	make -j $(nproc) install
	sudo ldconfig

	# RTLSDR
	cd $SIGBOX_SDRANGEL
	git clone https://github.com/osmocom/rtl-sdr.git librtlsdr
	cd librtlsdr
	git reset --hard be1d1206bfb6e6c41f7d91b20b77e20f929fa6a7
	mkdir build; cd build
	cmake -Wno-dev -DDETACH_KERNEL_DRIVER=ON -DCMAKE_INSTALL_PREFIX=/opt/install/librtlsdr ..
	make -j4 install

	# PlutoSDR
	cd $SIGBOX_SDRANGEL
	git clone https://github.com/analogdevicesinc/libiio.git
	cd libiio
	git reset --hard v0.21
	mkdir build; cd build
	cmake -Wno-dev -DCMAKE_INSTALL_PREFIX=/opt/install/libiio -DINSTALL_UDEV_RULE=OFF ..
	make -j4 install

	# HackRF
	cd $SIGBOX_SDRANGEL
	git clone https://github.com/mossmann/hackrf.git
	cd hackrf/host
	git reset --hard "v2018.01.1"
	mkdir build; cd build
	cmake -Wno-dev -DCMAKE_INSTALL_PREFIX=/opt/install/libhackrf -DINSTALL_UDEV_RULES=OFF ..
	make -j4 install

	# LimeSDR
	cd $SIGBOX_SDRANGEL
	git clone https://github.com/myriadrf/LimeSuite.git
	cd LimeSuite
	git reset --hard "v20.01.0"
	mkdir builddir; cd builddir
	cmake -Wno-dev -DCMAKE_INSTALL_PREFIX=/opt/install/LimeSuite ..
	make -j4 install

	#SoapySDR
	cd $SIGBOX_SDRANGEL
	git clone https://github.com/pothosware/SoapySDR.git
	cd SoapySDR
	git reset --hard "soapy-sdr-0.7.1"
	mkdir build; cd build
	cmake -DCMAKE_INSTALL_PREFIX=/opt/install/SoapySDR ..
	make -j4 install
	
	#SoapyRTLSDR
	cd $SIGBOX_SDRANGEL
	git clone https://github.com/pothosware/SoapyRTLSDR.git
	cd SoapyRTLSDR
	mkdir build && cd build
	cmake -DCMAKE_INSTALL_PREFIX=/opt/install/SoapySDR  -DRTLSDR_INCLUDE_DIR=/opt/install/librtlsdr/include -DRTLSDR_LIBRARY=/opt/install/librtlsdr/lib/librtlsdr.so -DSOAPY_SDR_INCLUDE_DIR=/opt/install/SoapySDR/include -DSOAPY_SDR_LIBRARY=/opt/install/SoapySDR/lib/libSoapySDR.so ..
	make -j4 install

	#SoapyHackRF
    cd $SIGBOX_SDRANGEL
	git clone https://github.com/pothosware/SoapyHackRF.git
	cd SoapyHackRF
	mkdir build; cd build
	cmake -DCMAKE_INSTALL_PREFIX=/opt/install/SoapySDR -DLIBHACKRF_INCLUDE_DIR=/opt/install/libhackrf/include/libhackrf -DLIBHACKRF_LIBRARY=/opt/install/libhackrf/lib/libhackrf.so -DSOAPY_SDR_INCLUDE_DIR=/opt/install/SoapySDR/include -DSOAPY_SDR_LIBRARY=/opt/install/SoapySDR/lib/libSoapySDR.so ..
	make -j4 install

	#SoapyLimeRF
    cd $SIGBOX_SDRANGEL
	cd LimeSuite/builddir
	cmake -Wno-dev -DCMAKE_INSTALL_PREFIX=/opt/install/LimeSuite -DCMAKE_PREFIX_PATH=/opt/install/SoapySDR ..
	make -j4 install
	cp /opt/install/LimeSuite/lib/SoapySDR/modules0.7/libLMS7Support.so /opt/install/SoapySDR/lib/SoapySDR/modules0.7

	#SoapyRemote
	cd $SIGBOX_SDRANGEL
	git clone https://github.com/pothosware/SoapyRemote.git
	cd SoapyRemote
	git reset --hard "soapy-remote-0.5.1"
	mkdir build; cd build
	cmake -DCMAKE_INSTALL_PREFIX=/opt/install/SoapySDR -DSOAPY_SDR_INCLUDE_DIR=/opt/install/SoapySDR/include -DSOAPY_SDR_LIBRARY=/opt/install/SoapySDR/lib/libSoapySDR.so ..
	make -j4 install

	#SDRangel
    cd $SIGBOX_SDRANGEL
	git clone https://github.com/f4exb/sdrangel.git
	cd sdrangel
	mkdir build; cd build
	cmake -Wno-dev -DDEBUG_OUTPUT=ON -DRX_SAMPLE_24BIT=ON \
	-DCMAKE_BUILD_TYPE=RelWithDebInfo \
	-DHACKRF_DIR=/opt/install/libhackrf \
	-DRTLSDR_DIR=/opt/install/librtlsdr \
	-DLIMESUITE_DIR=/opt/install/LimeSuite \
	-DIIO_DIR=/opt/install/libiio \
	-DSOAPYSDR_DIR=/opt/install/SoapySDR \
	-DAPT_DIR=/opt/install/aptdec \
	-DCM256CC_DIR=/opt/install/cm256cc \
	-DDSDCC_DIR=/opt/install/dsdcc \
	-DSERIALDV_DIR=/opt/install/serialdv \
	-DMBE_DIR=/opt/install/mbelib \
	-DCODEC2_DIR=/opt/install/codec2 \
	-DSGP4_DIR=/opt/install/sgp4 \
	-DLIBSIGMF_DIR=/opt/install/libsigmf \
	-DDAB_DIR=/opt/install/libdab \
	-DCMAKE_INSTALL_PREFIX=/opt/install/sdrangel ..
	make -j4 install
	# Copy special startup script for this snowflake
	sudo cp $SIGBOX_HOME/tools/SIGbox_sdrangel.sh /usr/local/bin/sdrangel
	# Copy Desktop file
	sudo cp $SIGBOX_SOURCE/SDRangel/sdrangel/build/sdrangel.desktop $DESKTOP_FILES

    cd $HOME/.config/
	mkdir f4exb
	cd f4exb
	# Generate a new wisdom file for FFT sizes : 128, 256, 512, 1024, 2048, 4096, 8192, 16384 and 32768.
	# This will take a very long time.
	fftwf-wisdom -n -o fftw-wisdom 128 256 512 1024 2048 4096 8192 16384 32768
}


###
###  MAIN
###

install_sdrangel_compile

echo -e "${SIGBOX_BANNER_COLOR}"
echo -e "${SIGBOX_BANNER_COLOR} #SIGBOX#"
echo -e "${SIGBOX_BANNER_COLOR} #SIGBOX#   Install SDRangel"
echo -e "${SIGBOX_BANNER_COLOR} #SIGBOX#"
echo -e "${SIGBOX_BANNER_RESET}"

#
# Copy Menu items into relevant directories
# 
	
cp $SIGBOX_DESKTOP/SIGbox*.desktop /home/$USER/Desktop
sudo cp $SIGBOX_DESKTOP/sdrangel.desktop $DESKTOP_DIRECTORY
sudo cp /opt/install/sdrangel/share/icons/hicolor/scalable/apps/sdrangel_icon.svg $DESKTOP_ICONS
sudo cp /opt/install/sdrangel/share/icons/hicolor/scalable/apps/sdrangel_icon.svg $DESKTOP_PIXMAPS
