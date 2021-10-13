#!/bin/bash

###
### SIGdeb_installer
###

###
###   REVISION: 20211010-2300
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

calc_wt_size() {

  # NOTE: it's tempting to redirect stderr to /dev/null, so supress error 
  # output from tput. However in this case, tput detects neither stdout or 
  # stderr is a tty and so only gives default 80, 24 values
  WT_HEIGHT=26
  WT_WIDTH=$(tput cols)

  if [ -z "$WT_WIDTH" ] || [ "$WT_WIDTH" -lt 60 ]; then
    WT_WIDTH=60
  fi
  if [ "$WT_WIDTH" -gt 178 ]; then
    WT_WIDTH=80
  fi
  WT_MENU_HEIGHT=$(($WT_HEIGHT-7))
}

select_startscreen(){
    TERM=ansi whiptail --title "SIGbox Installer" --textbox $SIGBOX_INSTALL_TXT1 24 120 16
}

select_sdrdevices() {
    FUN=$(whiptail --title "SDR Devices" --checklist --separate-output \
        "Choose SDR devices " 20 80 12\
        "rtl-sdr" "RTL2832U & R820T2-Based " ON \
        "hackrf" "Hack RF One " OFF \
        "libiio" "PlutoSDR " OFF \
        "limesuite" "LimeSDR " OFF \
        "soapysdr" "SoapySDR Library " ON \
        "soapyremote" "Use any SoapySDR Remotely " ON \
        "soapyrtlsdr" "SoapySDR Module for RTLSDR " ON \
        "soapyhackrf" "SoapySDR Module for HackRF One " OFF \
        "soapyplutosdr" "SoapySDR Module for PlutoSD " OFF \
        3>&1 1>&2 2>&3)
    RET=$?
    if [ $RET -eq 1 ]; then
        $FUN = "NONE"
    fi
    echo $FUN >> $SIGBOX_CONFIG
}

select_decoders() {
    FUN=$(whiptail --title "Digital Decoders" --checklist --separate-output \
        "Choose Decoders " 20 120 12\
        "aptdec" "NOAA weather satellites images" ON \
        "rtl_433" "Various OT and IoT sensors using UHF ISM Bands " ON \
        "op25" "P25 Digital Voice" ON \
        "multimon-ng" "POCSAG, FLEX, X10, DTMF, ZVEi, UFSK, AFSK, etc" ON \
        "ubertooth-tools" "Bluetooth BLE and BR tools for Ubertooth device" ON \
        3>&1 1>&2 2>&3)
    RET=$?
    echo $FUN >> $SIGBOX_CONFIG
}

select_sdrapps() {
    FUN=$(whiptail --title "SDR Applications" --checklist --separate-output \
        "Choose SDR Applications" 20 80 12 \
        "sdrangel" "SDRangel " OFF \
		"sdrplusplus" "SDR++ " OFF \
        3>&1 1>&2 2>&3)
    RET=$?
    echo $FUN >> $SIGBOX_CONFIG
}

select_amateurradio() {
    FUN=$(whiptail --title "Amateur Radio Digital Modes" --checklist --separate-output \
        "Choose which applications you want installed" 20 100 12 \
        "fldigi-4.1.06" "A graphical application for CW, RTTY, PSK31, MFSK and many others" OFF \
		"wsjt-x_2.5.0" "A graphical application for using FT8, JT4, JT9, JT65, MSK144, and WSPR " OFF \
		"qsstv-9.4.4" "A graphicall application for Slow Scan Television" OFF \
        3>&1 1>&2 2>&3)
    RET=$?
    echo $FUN >> $SIGBOX_CONFIG
}

select_packetradio() {
    FUN=$(whiptail --title "Packet Radio and APRS" --checklist --separate-output \
        "Choose Packet Radio Applications" 20 80 12 \
        "direWolf" "DireWolf 1.7 Soundcard TNC for APRS " OFF \
        "linpac" "Packet Radio Temrinal with mail client " OFF \
        "xastir" "APRS Station Tracking and Reporting " OFF \
        3>&1 1>&2 2>&3)
    RET=$?
    echo $FUN >> $SIGBOX_CONFIG
}

select_usefulapps() {
    FUN=$(whiptail --title "Useful Applications" --checklist --separate-output \
        "Choose other Useful Applications" 20 120 12 \
		"artemis" "Real-tim RF Signal Recognition to a large database of signals " OFF \
		"gps" "GPS client and NTP sync " OFF \
		"gpredict" "Satellite Tracking " OFF \
		"splat" "RF Signal Propagation, Loss, And Terrain analysis tool for 20 MHz to 20 GHz " OFF \
        "wireshark" "Network Traffic Analyzer useful for WiFi and Bluetooth. " OFF \
        "kismet" "Wireless sniffer and monitor " OFF \
        3>&1 1>&2 2>&3)
    RET=$?
    echo $FUN >> $SIGBOX_CONFIG
}

install_dependencies(){
	echo -e "${SIGBOX_BANNER_COLOR}"
	echo -e "${SIGBOX_BANNER_COLOR} #SIGBOX#"
	echo -e "${SIGBOX_BANNER_COLOR} #SIGBOX#   Install Dependencies"
	echo -e "${SIGBOX_BANNER_COLOR} #SIGBOX#"
	echo -e "${SIGBOX_BANNER_RESET}"
    if [ ! -d "$SIGBOX_SOURCE" ]; then
    	mkdir $SIGBOX_SOURCE
    fi
    
    if [ ! -d "$SIGBOX_HOME" ]; then
    	mkdir $SIGBOX_HOME
    fi
    
	if [ ! -d "$SIGBOX_SDRANGEL" ]; then
    	mkdir $SIGBOX_SDRANGEL
    fi

	cd $SIGBOX_SOURCE

    sudo apt-get install -y git cmake g++ pkg-config autoconf automake libtool build-essential pulseaudio bison flex gettext ffmpeg
	sudo apt-get install -y portaudio19-dev doxygen graphviz gnuplot gnuplot-x11 swig  icu-doc libjs-jquery-ui-docs tcl8.6 tk8.6 libvolk2-doc python-cycler-doc
	sudo apt-get install -y tk8.6-blt2.5 ttf-bitstream-vera uhd-host dvipng texlive-latex-extra ttf-staypuft tix openssl
	
	sudo apt-get install -y libusb-1.0-0 libusb-1.0-0-dev libusb-dev libudev1
	sudo apt-get install -y libaio-dev libusb-1.0-0-dev libserialport-dev libxml2-dev libavahi-client-dev doxygen graphviz
	sudo apt-get install -y libfltk1.3 libfltk1.3-dev 
	sudo apt-get install -y libopenjp2-7 libopenjp2-7-dev libv4l-dev
	sudo apt-get install -y libsdl1.2-dev libfaad2 libfftw3-dev libfftw3-doc libfftw3-bin libfftw3-dev libfftw3-long3 libfftw3-quad3

	sudo apt-get install -y libvolk2-bin libvolk2-dev libvolk2.2 libfaad-dev zlib1g zlib1g-dev libasound2-dev 
	sudo apt-get install -y libopencv-dev libxml2-dev libaio-dev libnova-dev libwxgtk-media3.0-dev libcairo2-dev libavcodec-dev libpthread-stubs0-dev
	sudo apt-get install -y libavformat-dev libfltk1.3-dev libfltk1.3 libsndfile1-dev libopus-dev libavahi-common-dev libavahi-client-dev libavdevice-dev libavutil-dev
	sudo apt-get install -y libsdl1.2-dev libgsl-dev liblog4cpp5-dev libzmq3-dev liborc-0.4 liborc-0.4-0 liborc-0.4-dev libsamplerate0-dev libgmp-dev
	sudo apt-get install -y libpcap-dev libcppunit-dev libbluetooth-dev qt5-default libpulse-dev libliquid-dev libswscale-dev libswresample-dev
	sudo apt-get install -y libgles1 libosmesa6 gmp-doc libgmp10-doc libmpfr-dev libmpfrc++-dev libntl-dev libcppunit-doc zlib-dev libpng-dev
	
	sudo apt-get install -y libcanberra-gtk-module libcanberra-gtk0 libcppunit-1.15-0 libcppunit-dev  
	sudo apt-get install -y libfreesrp0 libglfw3 libgmp-dev libgmpxx4ldbl libhidapi-libusb0 libicu-dev libjs-jquery-ui 
	sudo apt-get install -y liblog4cpp5-dev liblog4cpp5v5 faad libfaad2 libfaad-dev

	sudo apt-get install -y python3-pip python3-numpy python3-mako python3-sphinx python3-lxml python3-yaml python3-click python3-click-plugins 
	sudo apt-get install -y python3-zmq python3-scipy python3-scapy python3-setuptools python3-pyqt5 python3-gi-cairo python-docutils python-gobject python3-nose

	sudo apt-get install -y python3-tornado texlive-extra-utils python-networkx-doc python3-gdal python3-pygraphviz python3-pydot libgle3 python-pyqtgraph-doc 
	sudo apt-get install -y python-matplotlib-doc python3-cairocffi python3-tk-dbg python-matplotlib-data python3-cycler python3-kiwisolver python3-matplotlib python3-networkx 
	sudo apt-get install -y python3-opengl python3-pyqt5.qtopengl python3-pyqtgraph python3-tk

	sudo python3 -m pip install --upgrade pip
	sudo pip3 install pyinstaller
	sudo pip3 install pygccxml
	sudo pip3 install qtawesome
	sudo pip3 install PyQt5
	sudo pip3 install PyQt4
	sudo pip3 install PySide

	# RTL-SDR Dependencies
	sudo apt-get install -y libusb-1.0-0-dev

	# APTdec dependencies
	sudo apt-get install -y libsndfile-dev libpng-dev

	# LibDAB dab-cmdline dependencies
	sudo apt-get install -y pkg-config libsndfile1-dev libfftw3-dev portaudio19-dev libfaad-dev zlib1g-dev libusb-1.0-0-dev mesa-common-dev libgl1-mesa-dev libsamplerate0-dev

	# MBElib, SerialDV, SGP4, LibTBB- no dependencies specified
	
	# DSDcc - requires MBElib installed prior

	# Liquid-DSP - prefers FFTW installed prior

	# Codec2
	sudo apt-get install -y octave octave-common octave-signal liboctave-dev gnuplot python3-numpy sox valgrind

	# QSSTV - None

}

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

install_sdrplusplus(){
	echo -e "${SIGBOX_BANNER_COLOR}"
	echo -e "${SIGBOX_BANNER_COLOR} #SIGBOX#"
	echo -e "${SIGBOX_BANNER_COLOR} #SIGBOX#   Install SDRplusplus"
	echo -e "${SIGBOX_BANNER_COLOR} #SIGBOX#"
	echo -e "${SIGBOX_BANNER_RESET}"

	sudo apt-get install -y libfftw3-dev libglfw3-dev libglew-dev libvolk2-dev libsoapysdr-dev libad9361-devl ibairspyhf-dev 

	cd $SIGBOX_SOURCE
	git clone https://github.com/AlexandreRouma/SDRPlusPlus
	cd SDRPlusPlus
	mkdir build && cd build
	cmake ../ -DOPT_BUILD_AUDIO_SINK=OFF \
	-DOPT_BUILD_BLADERF_SOURCE=OFF \
	-DOPT_BUILD_M17_DECODER=ON \
	-DOPT_BUILD_NEW_PORTAUDIO_SINK=ON \
	-DOPT_BUILD_PLUTOSDR_SOURCE=ON \
	-DOPT_BUILD_PORTAUDIO_SINK=ON \
	-DOPT_BUILD_SOAPY_SOURCE=ON \
	-DOPT_BUILD_AIRSPY_SOURCE=OFF
	make -j4
	sudo make install
	sudo ldconfig

	# SDRplusplus dependencies
	#sudo apt-get install -y libfftw3-dev libglfw3-dev libglew-dev libvolk2-dev libsoapysdr-dev libairspyhf-dev libiio-dev libad9361-dev librtaudio-dev libhackrf-dev
	#
	#wget https://github.com/AlexandreRouma/SDRPlusPlus/releases/download/1.0.3/sdrpp_ubuntu_focal_amd64.deb -D $HOME/Downloads
	#sudo dpkg -i $HOME/Downloads/sdrpp_ubuntu_focal_amd64.deb
}

install_kismet(){
	TERM=ansi whiptail --title "SIGbox Installer" --msgbox "Installing Kismet" 12 120

	echo -e "${SIGBOX_BANNER_COLOR}"
	echo -e "${SIGBOX_BANNER_COLOR} #SIGBOX#"
	echo -e "${SIGBOX_BANNER_COLOR} #SIGBOX#   Install Kismet"
	echo -e "${SIGBOX_BANNER_COLOR} #SIGBOX#"
	echo -e "${SIGBOX_BANNER_RESET}"
    wget -O - https://www.kismetwireless.net/repos/kismet-release.gpg.key | sudo apt-key add -
    echo 'deb https://www.kismetwireless.net/repos/apt/release/buster buster main' | sudo tee /etc/apt/sources.list.d/kismet.list
	sudo apt update
    sudo apt-get install -y kismet
    #
    # Say yes when asked about suid helpers
    #
}

install_fldigi_compile(){
	echo -e "${SIGBOX_BANNER_COLOR}"
	echo -e "${SIGBOX_BANNER_COLOR} #SIGBOX#"
	echo -e "${SIGBOX_BANNER_COLOR} #SIGBOX#   Install Fldigi Suite"
	echo -e "${SIGBOX_BANNER_COLOR} #SIGBOX#"
	echo -e "${SIGBOX_BANNER_RESET}"
    # Install FLxmlrpc
	wget http://www.w1hkj.com/files/flxmlrpc/flxmlrpc-0.1.4.tar.gz -P $HOME/Downloads
	tar -zxvf $HOME/Downloads/flxmlrpc-0.1.4.tar.gz -C $SIGBOX_SOURCE
	cd $SIGBOX_SOURCE/flxmlrpc-0.1.4
	./configure --prefix=/usr/local --enable-static
	make
	sudo make install
	sudo ldconfig
	
	# Install FLrig
	wget http://www.w1hkj.com/files/flrig/flrig-1.4.2.tar.gz -P $HOME/Downloads
	tar -zxvf $HOME/Downloads/flrig-1.4.2.tar.gz -C $SIGBOX_SOURCE
	cd $SIGBOX_SOURCE/flrig-1.4.2
	./configure --prefix=/usr/local --enable-static
	make
	sudo make install
	sudo ldconfig
	sudo cp $SIGBOX_SOURCE/flrig-1.4.2/data/flrig.desktop $SIGBOX_DESKTOP

	#Install Fldigi
	wget http://www.w1hkj.com/files/fldigi/fldigi-4.1.20.tar.gz -P $HOME/Downloads
	tar -zxvf $HOME/Downloads/fldigi-4.1.20.tar.gz -C $SIGBOX_SOURCE
	cd $SIGBOX_SOURCE/fldigi-4.1.20
	./configure --prefix=/usr/local --enable-static
	make
	sudo make install
	sudo ldconfig
	sudo cp $SIGBOX_SOURCE/fldigi-4.1.20/data/fldigi.desktop $SIGBOX_DESKTOP
	sudo cp $SIGBOX_SOURCE/fldigi-4.1.20/data/flarq.desktop $SIGBOX_DESKTOP
}

install_wsjtx(){
	echo -e "${SIGBOX_BANNER_COLOR}"
	echo -e "${SIGBOX_BANNER_COLOR} #SIGBOX#"
	echo -e "${SIGBOX_BANNER_COLOR} #SIGBOX#   Install WSJT-X"
	echo -e "${SIGBOX_BANNER_COLOR} #SIGBOX#"
	echo -e "${SIGBOX_BANNER_RESET}"
    wget https://www.physics.princeton.edu/pulsar/k1jt/wsjtx_2.5.0_amd64.deb -P $HOME/Downloads
	sudo dpkg -i $HOME/Downloads/wsjtx_2.5.0_amd64.deb
	# Will get error next command fixes error and downloads dependencies
	sudo apt-get --fix-broken install
	sudo dpkg -i $HOME/Downloads/wsjtx_2.5.0_amd64.deb
}

install_qsstv(){
	echo -e "${SIGBOX_BANNER_COLOR}"
	echo -e "${SIGBOX_BANNER_COLOR} #SIGBOX#"
	echo -e "${SIGBOX_BANNER_COLOR} #SIGBOX#   Install QSSTV"
	echo -e "${SIGBOX_BANNER_COLOR} #SIGBOX#"
	echo -e "${SIGBOX_BANNER_RESET}"
    sudo apt-get install -y libhamlib-dev libv4l-dev
	sudo apt-get install -y libopenjp2-7 libopenjp2-7-dev
	wget http://users.telenet.be/on4qz/qsstv/downloads/qsstv_9.5.8.tar.gz -P $HOME/Downloads
	tar -xvzf $HOME/Downloads/qsstv_9.5.8.tar.gz -C $SIGBOX_SOURCE
	cd $SIGBOX_SOURCE/qsstv
	qmake
	make
	sudo make install
}

install_SIGBOXmenu(){
	echo -e "${SIGBOX_BANNER_COLOR}"
	echo -e "${SIGBOX_BANNER_COLOR} #SIGBOX#"
	echo -e "${SIGBOX_BANNER_COLOR} #SIGBOX#   Install SIGbox Desktop Shortcuts"
	echo -e "${SIGBOX_BANNER_COLOR} #SIGBOX#"
	echo -e "${SIGBOX_BANNER_RESET}"
    
	#
	# Copy Menu items into relevant directories
	# 
	
	cp $SIGBOX_DESKTOP/SIGbox*.desktop /home/$USER/Desktop
	sudo cp $SIGBOX_DESKTOP/SIGbox.directory $DESKTOP_DIRECTORY
	sudo cp $SIGBOX_DESKTOP/SIGbox.menu $DESKTOP_XDG_MENU
	sudo cp $SIGBOX_DESKTOP/SIGbox*.desktop $DESKTOP_FILES
	sudo cp $SIGBOX_ICONS/* $DESKTOP_ICONS
	sudo cp $SIGBOX_PIXMAPS/* $DESKTOP_PIXMAPS
	
	sudo cp $SIGBOX_SOURCE/LimeSuite/Desktop/lime-suite.desktop $DESKTOP_FILES
	#sudo cp $SIGBOX_SOURCE/flrig-1.4.2/data/flrig.desktop $DESKTOP_FILES
	#sudo cp $SIGBOX_SOURCE/fldigi-4.1.20/data/flarq.desktop $DESKTOP_FILES
	#sudo cp $SIGBOX_SOURCE/fldigi-4.1.20/data/fldigi.desktop $DESKTOP_FILES
	#sudo cp $SIGBOX_SOURCE/qsstv/qsstv.desktop $DESKTOP_FILES
	#sudo cp $DESKTOP_FILES/gnuradio-grc.desktop $USER/Desktop/gnuradio-grc.desktop
	
	#
	# Add SigPi Category for each installed application
	#

	sudo sed -i "s/Categories.*/Categories=$SIGPI_MENU_CATEGORY;/" $DESKTOP_FILES/lime-suite.desktop
	sudo sed -i "s/Categories.*/Categories=$SIGPI_MENU_CATEGORY;/" $DESKTOP_FILES/gnuradio-grc.desktop
	#sudo sed -i "s/Categories.*/Categories=$SIGPI_MENU_CATEGORY;/" $DESKTOP_FILES/gqrx.desktop
	sudo sed -i "s/Categories.*/Categories=$SIGPI_MENU_CATEGORY;/" $DESKTOP_FILES/sdrangel.desktop
	sudo sed -i "s/Categories.*/Categories=$SIGPI_MENU_CATEGORY;/" $DESKTOP_FILES/SDRPlusPlus.desktop
	sudo sed -i "s/Categories.*/Categories=$SIGPI_MENU_CATEGORY;/" $DESKTOP_FILES/direwolf.desktop
	sudo sed -i "s/Categories.*/Categories=$SIGPI_MENU_CATEGORY;/" $DESKTOP_FILES/linpac.desktop
	sudo sed -i "s/Categories.*/Categories=$SIGPI_MENU_CATEGORY;/" $DESKTOP_FILES/xastir.desktop
	sudo sed -i "s/Categories.*/Categories=$SIGPI_MENU_CATEGORY;/" $DESKTOP_FILES/flarq.desktop
	sudo sed -i "s/Categories.*/Categories=$SIGPI_MENU_CATEGORY;/" $DESKTOP_FILES/fldigi.desktop
	sudo sed -i "s/Categories.*/Categories=$SIGPI_MENU_CATEGORY;/" $DESKTOP_FILES/flrig.desktop
	sudo sed -i "s/Categories.*/Categories=$SIGPI_MENU_CATEGORY;/" $DESKTOP_FILES/wsjtx.desktop
	sudo sed -i "s/Categories.*/Categories=$SIGPI_MENU_CATEGORY;/" $DESKTOP_FILES/message_aggregator.desktop
	sudo sed -i "s/Categories.*/Categories=$SIGPI_MENU_CATEGORY;/" $DESKTOP_FILES/qsstv.desktop
	#sudo sed -i "s/Categories.*/Categories=$SIGPI_MENU_CATEGORY;/" $DESKTOP_FILES/mumble.desktop
	sudo sed -i "s/Categories.*/Categories=$SIGPI_MENU_CATEGORY;/" $DESKTOP_FILES/gpredict.desktop
	sudo sed -i "s/Categories.*/Categories=$SIGPI_MENU_CATEGORY;/" $DESKTOP_FILES/wireshark.desktop
	sudo sed -i "s/Categories.*/Categories=$SIGPI_MENU_CATEGORY;/" $DESKTOP_FILES/sigidwiki.desktop
	sudo sed -i "s/Categories.*/Categories=$SIGPI_MENU_CATEGORY;/" $DESKTOP_FILES/SIGbox_home.desktop
	sudo sed -i "s/Categories.*/Categories=$SIGPI_MENU_CATEGORY;/" $DESKTOP_FILES/SIGbox_reddit.desktop	

}


###
###  MAIN
###

touch $SIGBOX_CONFIG
calc_wt_size
select_startscreen
select_sdrdevices
select_decoders
select_sdrapps
select_amateurradio
select_packetradio
select_usefulapps
TERM=ansi whiptail --title "SIGbox Installer" --msgbox "Ready to Install" 12 120

echo -e "${SIGBOX_BANNER_COLOR}"
echo -e "${SIGBOX_BANNER_COLOR} #SIGBOX#"
echo -e "${SIGBOX_BANNER_COLOR} #SIGBOX#   System Update & Upgrade"
echo -e "${SIGBOX_BANNER_COLOR} #SIGBOX#"
echo -e "${SIGBOX_BANNER_RESET}"

sudo apt-get -y update
sudo apt-get -y upgrade


##
##  INSTALL DEPENDENCIES
##
TERM=ansi whiptail --title "SIGbox Installer" --msgbox "Install Dependencies" 12 120
install_dependencies


##
##  INSTALL DRIVERS
##
TERM=ansi whiptail --title "SIGbox Installer" --msgbox "Install Drivers" 12 120

echo -e "${SIGBOX_BANNER_COLOR}"
echo -e "${SIGBOX_BANNER_COLOR} #SIGBOX#"
echo -e "${SIGBOX_BANNER_COLOR} #SIGBOX#   Install Drivers"
echo -e "${SIGBOX_BANNER_COLOR} #SIGBOX#"
echo -e "${SIGBOX_BANNER_RESET}"

# AX.25 and utilities"
sudo apt-get install -y libax25 ax25-apps ax25-tools
echo "ax0 N0CALL-3 1200 255 7 APRS" | sudo tee -a /etc/ax25/axports

# RTL-SDR
if grep rtl-sdr "$SIGBOX_CONFIG"
then
    cd $SIGBOX_SOURCE
	git clone https://github.com/osmocom/rtl-sdr.git
	cd rtl-sdr
	mkdir build	
	cd build
	cmake ../ -DINSTALL_UDEV_RULES=ON -DDETACH_KERNEL_DRIVER=ON
	make
	sudo make install
	sudo ldconfig
fi

# HackRF
if grep hackrf "$SIGBOX_CONFIG"
then
    sudo apt-get install -y hackrf libhackrf-dev
	sudo hackrf_info
fi

# PlutoSDR
if grep libiio "$SIGBOX_CONFIG"
then
    cd $SIGBOX_SOURCE
	git clone https://github.com/analogdevicesinc/libiio.git
	cd libiio
	mkdir build; cd build
	cmake ..
	make -j4
	sudo make install
	sudo ldconfig
fi

# LimeSDR
if grep limesuite "$SIGBOX_CONFIG"
then
    cd $SIGBOX_SOURCE
	git clone https://github.com/myriadrf/LimeSuite.git
	cd LimeSuite
	git checkout stable
	mkdir build && cd build
	cmake ../
	make -j4
	sudo make install
	sudo ldconfig
fi

# SoapySDR
if grep soapysdr "$SIGBOX_CONFIG"
then
    cd $SIGBOX_SOURCE
	git clone https://github.com/pothosware/SoapySDR.git
	cd SoapySDR
	mkdir build && cd build
	cmake ../ -DCMAKE_BUILD_TYPE=Release
	make -j4
	sudo make install
	sudo ldconfig
	SoapySDRUtil --info
fi

# SoapyRTLSDR
if grep soapyrtlsdr "$SIGBOX_CONFIG"
then
    cd $SIGBOX_SOURCE
	git clone https://github.com/pothosware/SoapyRTLSDR.git
	cd SoapyRTLSDR
	mkdir build && cd build
	cmake .. -DCMAKE_BUILD_TYPE=Release
	make
	sudo make install
	sudo ldconfig
fi

# SoapyHackRF
if grep soapyhackrf "$SIGBOX_CONFIG"
then
    cd $SIGBOX_SOURCE
	git clone https://github.com/pothosware/SoapyHackRF.git
	cd SoapyHackRF
	mkdir build && cd build
	cmake .. -DCMAKE_BUILD_TYPE=Release
	make
	sudo make install
	sudo ldconfig
fi

# SoapyPlutoSDR
if grep soapyplutosdr "$SIGBOX_CONFIG"
then
    cd $SIGBOX_SOURCE
	git clone https://github.com/pothosware/SoapyPlutoSDR
	cd SoapyPlutoSDR
	mkdir build && cd build
	cmake ..
	make
	sudo make install
	sudo ldconfig
fi

# SoapyRemote
if grep soapyremote "$SIGBOX_CONFIG"
then
     cd $SIGBOX_SOURCE
	git clone https://github.com/pothosware/SoapyRemote.git
	cd SoapyRemote
	mkdir build && cd build
	cmake ..
	make
	sudo make install
	sudo ldconfig
fi

##
##  INSTALL LIBRARIES
##
TERM=ansi whiptail --title "SIGbox Installer" --msgbox "Install Libraries" 12 120
echo -e "${SIGBOX_BANNER_COLOR}"
echo -e "${SIGBOX_BANNER_COLOR} #SIGBOX#"
echo -e "${SIGBOX_BANNER_COLOR} #SIGBOX#   Install Libraries"
echo -e "${SIGBOX_BANNER_COLOR} #SIGBOX#"
echo -e "${SIGBOX_BANNER_RESET}"
cd $SIGBOX_SOURCE

# Hamlib
wget https://github.com/Hamlib/Hamlib/releases/download/4.3/hamlib-4.3.tar.gz -P $HOME/Downloads
tar -zxvf $HOME/Downloads/hamlib-4.3.tar.gz -C $SIGBOX_SOURCE
cd $SIGBOX_SOURCE/hamlib-4.3
./configure --prefix=/usr/local --enable-static
make
sudo make install
sudo ldconfig


##
##  INSTALL DECODERS
##
TERM=ansi whiptail --title "SIGbox Installer" --msgbox "Install Decoders" 12 120
echo -e "${SIGBOX_BANNER_COLOR}"
echo -e "${SIGBOX_BANNER_COLOR} #SIGBOX#"
echo -e "${SIGBOX_BANNER_COLOR} #SIGBOX#   Install Decoders"
echo -e "${SIGBOX_BANNER_COLOR} #SIGBOX#"
echo -e "${SIGBOX_BANNER_RESET}"
cd $SIGBOX_SOURCE

# APT
# Aptdec is a FOSS program that decodes images transmitted by NOAA weather satellites.
cd $SIGBOX_SOURCE
sudo apt install libsndfile-dev libpng-dev
git clone https://github.com/Xerbo/aptdec.git && cd aptdec
mkdir build && cd build
cmake -DCMAKE_BUILD_TYPE=Release ..
make

# CM256cc
cd $SIGBOX_SOURCE
git clone https://github.com/f4exb/cm256cc.git
cd cm256cc
mkdir build; cd build
cmake ..
make -j4
sudo make install
sudo ldconfig

# LibDAB
cd $SIGBOX_SOURCE
git clone https://github.com/srcejon/dab-cmdline
cd dab-cmdline/library
mkdir build; cd build
cmake ..
make -j4
sudo make install
sudo ldconfig

# MBElib 1.3.0 
#
# Supports the 7200x4400 bit/s codec used in P25 Phase 1, the 7100x4400 bit/s codec used
# in ProVoice and the "Half Rate" 3600x2250 bit/s vocoder used in various radio systems
cd $SIGBOX_SOURCE
git clone https://github.com/szechyjs/mbelib.git
cd mbelib
mkdir build; cd build
cmake ..
make -j4
sudo make install
sudo ldconfig

# SerialDV
cd $SIGBOX_SOURCE
git clone https://github.com/f4exb/serialDV.git
cd serialDV
mkdir build; cd build
cmake ..	
make -j4 
sudo make install
sudo ldconfig

# Codec2/FreeDV
cd $SIGBOX_SOURCE
git clone https://github.com/drowe67/codec2.git
cd codec2
mkdir build && cd build
cmake ..
make -j4
sudo make install
sudo ldconfig

# DSDcc
cd $SIGBOX_SOURCE
git clone https://github.com/f4exb/dsdcc.git
cd dsdcc
mkdir build; cd build
cmake ..
make -j4
sudo make install
sudo ldconfig

# SGP4
# python-sgp4 1.4-1 is available in the packager, installing this version just to be sure.
cd $SIGBOX_SOURCE
git clone https://github.com/dnwrnr/sgp4.git
cd sgp4
mkdir build; cd build
cmake ..
make -j4
sudo make install
sudo ldconfig

# LibSigMF
cd $SIGBOX_SOURCE
git clone https://github.com/deepsig/libsigmf.git
cd libsigmf
mkdir build; cd build
cmake ..
make -j4
sudo make install
sudo ldconfig
	
# Liquid-DSP
cd $SIGBOX_SOURCE
git clone https://github.com/jgaeddert/liquid-dsp.git
cd liquid-dsp
./bootstrap.sh
./configure --enable-fftoverride 
make -j4
sudo make install
sudo ldconfig

# Bluetooth Baseband Library
cd $SIGBOX_SOURCE
git clone https://github.com/greatscottgadgets/libbtbb.git
cd libbtbb
mkdir build && cd build
cmake ..
make -j4
sudo make install
sudo ldconfig
 
# OP25 ---- script crashes at next line and goes to and with EOF error
#if grep op25 "$SIGBOX_CONFIG"
#then
#    cd $SIGBOX_SOURCE
#	 git clone https://github.com/osmocom/op25.git
#	 cd op25
#	 if grep gnuradio-3.8 "$SIGBOX_CONFIG"
#	 then
#	     cat gr3.8.patch | patch -p1
#		 ./install_sh
#	 else
#		 ./install.sh
#fi

# Multimon-NG
if grep multimon-ng "$SIGBOX_CONFIG"
then
    cd $SIGBOX_SOURCE
	git clone https://github.com/EliasOenal/multimon-ng.git
	cd multimon-ng
	mkdir build && cd build
	qmake ../multimon-ng.pro
	make
	sudo make install
	sudo ldconfig
fi

# Ubertooth Tools
if grep ubertooth-tools "$SIGBOX_CONFIG"
then
	cd $SIGBOX_SOURCE
	git clone https://github.com/greatscottgadgets/ubertooth.git
	cd ubertooth/host
	mkdir build && cd build
	cmake ..
	make -j4
	sudo make install
	sudo ldconfig
fi


##
## INSTALL GNURADIO
##
TERM=ansi whiptail --title "SIGbox Installer" --msgbox "Install GNUradio 3.8" 12 120
sudo apt-get install -y gnuradio gnuradio-dev
# Copy Desktop
sudo cp $SIGBOX_SOURCE/gnuradio/grc/scripts/freedesktop/gnuradio-grc.desktop $DESKTOP_FILES


##
## INSTALL SDRAPPS
##
TERM=ansi whiptail --title "SIGbox Installer" --msgbox "Install SDRapps" 12 120

echo -e "${SIGBOX_BANNER_COLOR}"
echo -e "${SIGBOX_BANNER_COLOR} #SIGBOX#"
echo -e "${SIGBOX_BANNER_COLOR} #SIGBOX#   Install SDR Applications"
echo -e "${SIGBOX_BANNER_COLOR} #SIGBOX#"
echo -e "${SIGBOX_BANNER_RESET}"

# rtl_433
if grep rtl_433 "$SIGBOX_CONFIG"
then
    cd $SIGBOX_SOURCE
	git clone https://github.com/merbanan/rtl_433.git
	cd rtl_433
	mkdir build && cd build
	cmake ..
	make
	sudo make install
	sudo ldconfig

fi

# SDRangel
if grep sdrangel "$SIGBOX_CONFIG"
then
    install_sdrangel_compile
fi

# SDR++
if grep sdrplusplus "$SIGBOX_CONFIG"
then
    install_sdrplusplus
fi

##
## INSTALL AMATEUR RADIO APPLICATIONS
##
TERM=ansi whiptail --title "SIGbox Installer" --msgbox "Install Amateur Radio Apps" 12 120

echo -e "${SIGBOX_BANNER_COLOR}"
echo -e "${SIGBOX_BANNER_COLOR} #SIGBOX#"
echo -e "${SIGBOX_BANNER_COLOR} #SIGBOX#   Install Amateur Radio Applications"
echo -e "${SIGBOX_BANNER_COLOR} #SIGBOX#"
echo -e "${SIGBOX_BANNER_RESET}"

# Fldigi
if grep fldigi "$SIGBOX_CONFIG"
then
	# Fldigi Dependencies
	sudo apt-get install -y libfltk-images1.3 libfltk1.3 libflxmlrpc1 libgcc-s1 libhamlib2 libmbedcrypto3 libmbedtls12 libmbedx509-0 \
	libpng16-16 libportaudio2 libpulse0 libsamplerate0 libsndfile1

    sudo apt-get install -y fldigi
fi

# DireWolf
if grep direwolf "$SIGBOX_CONFIG"
then
    cd $SIGBOX_SOURCE
	git clone https://www.github.com/wb2osz/direwolf
	cd direwolf
	mkdir build && cd build
	cmake ..
	make -j4
	sudo make install
	make install-conf
fi

# Linpac
if grep linpac "$SIGBOX_CONFIG"
then
    sudo apt-get install -y linpac
fi

# Xastir
if grep xastir "$SIGBOX_CONFIG"
then
    sudo apt-get install -y xastir
fi

# WSJT-X
if grep wsjtx "$SIGBOX_CONFIG"
then
	# WSJT-X Dependencies
	sudo apt-get install -y libgfortran5 libqt5widgets5 libqt5network5 libqt5printsupport5 libqt5multimedia5-plugins libqt5serialport5 \
    libqt5sql5-sqlite libfftw3-single3 libgomp1 libboost-all-dev libusb-1.0-0
	
	sudo apt-get install -y wsjtx
fi

# QSSTV
if grep qsstv "$SIGBOX_CONFIG"
then
    sudo apt-get install -y qsstv
fi

##
## INSTALL OTHER APPS
##
TERM=ansi whiptail --title "SIGbox Installer" --msgbox "Install Other Apps" 12 120

echo -e "${SIGBOX_BANNER_COLOR}"
echo -e "${SIGBOX_BANNER_COLOR} #SIGBOX#"
echo -e "${SIGBOX_BANNER_COLOR} #SIGBOX#   Install Other Applications/Tools"
echo -e "${SIGBOX_BANNER_COLOR} #SIGBOX#"
echo -e "${SIGBOX_BANNER_RESET}"

# Artemis
if grep artemis "$SIGBOX_CONFIG"
then
    cd $HOME/Downloads
	wget https://aresvalley.com/download/193/ 
	mv index.html artemis.tar.gz
	tar -zxvf artemis.tar.gz -C $SIGBOX_SOURCE
fi

# GPS
if grep gps "$SIGBOX_CONFIG"
then
    sudo apt-get install -y gpsd gpsd-client python-gps chrony
fi

# Gpredict
if grep gpredict "$SIGBOX_CONFIG"
then
    sudo apt-get install -y gpredict
fi

# splat
if grep splat "$SIGBOX_CONFIG"
then
	# SPLAT Dependencies
	sudo apt-get install -y aglfn gnuplot gnuplot-data gnuplot-qt gnuplot-doc

    sudo apt-get install -y splat
fi

# Wireshark
if grep wireshark "$SIGBOX_CONFIG"
then
    sudo apt-get install -y wireshark wireshark-dev libwireshark-dev
	cd $SIGBOX_SOURCE/libbtbb/wireshark/plugins/btbb
	mkdir build && cd build
	cmake -DCMAKE_INSTALL_LIBDIR=/usr/lib/x86_64-linux-gnu/wireshark/libwireshark3/plugins ..
	make -j4
	sudo make install
	
	# BTBR Plugin
	cd $SIGBOX_SOURCE/libbtbb/wireshark/plugins/btbredr
	mkdir build && cd build
	cmake -DCMAKE_INSTALL_LIBDIR=/usr/lib/x86_64-linux-gnu/wireshark/libwireshark3/plugins ..
	make -j4
	sudo make install
fi

# Kismet
if grep kismet "$SIGBOX_CONFIG"
then
    install_kismet
fi


##
## INSTALL DESKTOP ITEMS
##
TERM=ansi whiptail --title "SIGbox Installer" --msgbox "Install Desktop items" 12 120

install_SIGBOXmenu

echo -e "${SIGBOX_BANNER_COLOR}"
echo -e "${SIGBOX_BANNER_COLOR} #SIGBOX#"
echo -e "${SIGBOX_BANNER_COLOR} #SIGBOX#   Installation Complete !!"
echo -e "${SIGBOX_BANNER_COLOR} #SIGBOX#"
echo -e "${SIGBOX_BANNER_COLOR}"
echo -e "${SIGBOX_BANNER_COLOR} #SIGBOX#"
echo -e "${SIGBOX_BANNER_COLOR} #SIGBOX#   System needs to reboot for all changes to occur"
echo -e "${SIGBOX_BANNER_COLOR} #SIGBOX#   Reboot will begin in 20 seconsds unless CTRL-C hit"
echo -e "${SIGBOX_BANNER_COLOR} #SIGBOX#"
echo -e "${SIGBOX_BANNER_RESET}"
sleep 20
sudo sync
sudo reboot
exit 0