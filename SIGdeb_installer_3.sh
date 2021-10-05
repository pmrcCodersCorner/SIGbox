#!/bin/bash

###
### SIGdeb_installer
###

###
###   REVISION: 20210929-2300
###

###
### This script is part of the SIGbox Project.
###
### Given a Ubunto 20.04 desktop installed this script installs drivers and
### applications for RF use cases that include hacking and 
### Amateur Radio Digital Modes.
###

###
### INIT VARIABLES AND DIRECTORIES
###

# Package Versions
HAMLIB_PKG="hamlib-4.3.tar.gz"
FLXMLRPC_PKG="flxmlrpc-0.1.4.tar.gz"
FLRIG_PKG="flrig-1.4.2.tar.gz"
FLDIGI_PKG="fldigi-4.1.20.tar.gz"
WSJTX_PKG="wsjtx_2.4.0_armhf.deb"
QSSTV_PKG="qsstv_9.5.8.tar.gz"
GNURADIO_PKG="gnuradio_3.9"

# Source Directory
SIGDEB_SOURCE=$HOME/source

# SIGdeb Home directory
SIGDEB_HOME=$SIGDEB_SOURCE/SIGdeb

# SDRangel Source directory
SIGDEB_SDRANGEL=$SIGDEB_SOURCE/SDRangel

# Desktop directories
SIGDEB_THEMES=$SIGDEB_HOME/themes
SIGDEB_BACKGROUNDS=$SIGDEB_THEMES/backgrounds
SIGDEB_ICONS=$SIGDEB_THEMES/icons
SIGDEB_LOGO=$SIGDEB_THEMES/logo
SIGDEB_DESKTOP=$SIGDEB_THEMES/desktop

# Desktop Destination Directories
DESKTOP_DIRECTORY=/usr/share/desktop-directories
DESKTOP_FILES=/usr/share/applications
DESKTOP_ICONS=/usr/share/icons
DESKTOP_XDG_MENU=/usr/share/extra-xdg-menus

# SIGdeb Menu category
SIGDEB_MENU_CATEGORY=SIGdeb

# SIGdeb Install Support files
SIG_CONFIG=$SIGDEB_HOME/sigdeb_installer_config.txt
SIG_INSTALL_TXT1=$SIGDEB_HOME/updates/SIGdeb-installer-1.txt
SIG_BANNER_COLOR="\e[0;104m\e[K"   # blue
SIG_BANNER_RESET="\e[0m"


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
    TERM=ansi whiptail --title "SIGdeb Installer" --textbox $SIG_INSTALL_TXT1 24 120 16
}

select_sdrdevices() {
    FUN=$(whiptail --title "SDR Devices" --checklist --separate-output \
        "Choose SDR devices " 20 80 12\
        "rtl-sdr" "RTL2832U & R820T2-Based " ON \
        "hackrf" "Hack RF One " OFF \
        "libiio" "PlutoSDR " OFF \
        "limesuite" "LimeSDR " OFF \
        "soapysdr" "SoapySDR Library " ON \
        "soapyremote" "Use any Soapy SDR Remotely " ON \
        "soapyrtlsdr" "Soapy SDR Module for RTLSDR " ON \
        "soapyhackrf" "Soapy SDR Module for HackRF One " OFF \
        "soapyplutosdr" "Soapy SDR Module for PlutoSD " OFF \
        3>&1 1>&2 2>&3)
    RET=$?
    if [ $RET -eq 1 ]; then
        $FUN = "NONE"
    fi
    echo $FUN >> $SIG_CONFIG
}

select_gnuradio() {
    FUN=$(whiptail --title "GNUradio" --radiolist --separate-output \
        "Choose GNUradio version" 20 80 12 \
        "gnuradio-3.7" "Installed from distro (Raspberry Pi OS) " ON \
        "gnuradio-3.8" "Compiled from Repo (required for gr-gsm) " OFF \
        3>&1 1>&2 2>&3)
    RET=$?
    if [ $RET -eq 1 ]; then
        $FUN = "NONE"
    fi
    echo $FUN >> $SIG_CONFIG
}

select_decoders() {
    FUN=$(whiptail --title "Digital Decoders" --checklist --separate-output \
        "Choose Decoders " 20 120 12\
        "aptdec" "Decodes images transmitted by NOAA weather satellites " ON \
        "rtl_433" "Generic data receiver with sensor support mainly for UHF ISM Bands " ON \
        "op25" "P25 digital voice decoder which works with RTL-SDR dongles" ON \
        "multimon-ng" "Decoder for POCSGA, FLEX, X10, DTMF, ZVEi, UFSK, AFSK, etc" ON \
        "ubertooth-tools" "Bluetooth BLE and BR tools for Ubertooth device" ON \
        3>&1 1>&2 2>&3)
    RET=$?
    if [ $RET -eq 1 ]; then
        $FUN = "NONE"
    fi
    echo $FUN >> $SIG_CONFIG
}

select_sdrapps() {
    FUN=$(whiptail --title "SDR Applications" --checklist --separate-output \
        "Choose SDR Applications" 20 80 12 \
        "gqrx" "SDR Receiver " ON \
        "cubicsdr" "SDR Receiver " OFF \
        "sdrangel" "SDRangel " OFF \
        3>&1 1>&2 2>&3)
    RET=$?
    if [ $RET -eq 1 ]; then
        $FUN = "NONE"
    fi
    echo $FUN >> $SIG_CONFIG
}

select_hamradio() {
	FUN=$(whiptail --title "Ham Control Library" --radiolist --separate-output \
        "USed for exterbal control of Aateur Radio and some SDR transceivers as \
		well as antenna rotors. Choose HAMlib version" 20 80 12 \
        "hamlib-3.3" "Installed from distro " ON \
        "hamlib-4.3" "Compiled from Repo (~20 minutes compile time) " OFF \
        3>&1 1>&2 2>&3)
    RET=$?
    if [ $RET -eq 1 ]; then
        $FUN = "NONE"
    fi
    echo $FUN >> $SIG_CONFIG

    FUN=$(whiptail --title "Fldigi Suite" --radiolist --separate-output \
        "Used for MFSK, PSK31, CW, RTTY. WEFAX and many others \
		Choose Fldigi version" 20 80 12 \
        "fldigi-4.1.01" "Installed from distro " ON \
        "fldigi-4.1.20" "Compiled from Repo (~40 minutes compile time) " OFF \
        3>&1 1>&2 2>&3)
    RET=$?
    if [ $RET -eq 1 ]; then
        $FUN = "NONE"
    fi
    echo $FUN >> $SIG_CONFIG

	FUN=$(whiptail --title "Weak Signal Amateur Radio" --radiolist --separate-output \
        "Used for FT8, JT4, JT9, JT65, QRA64, ISCAT, MSK144, and WSPR \
		digital modes. Choose WSJT-X version" 20 80 12 \
        "wsjtx-2.0" "Installed from distro " ON \
        "wsjtx-2.4.0" "Compiled from Repo (~20 minutes compile time) " OFF \
        3>&1 1>&2 2>&3)
    RET=$?
    if [ $RET -eq 1 ]; then
        $FUN = "NONE"
    fi
    echo $FUN >> $SIG_CONFIG

	FUN=$(whiptail --title "SIGdeb Installer" --radiolist --separate-output \
        "Choose QSSTV version" 20 80 12 \
        "qsstv-9.2.6" "Installed from distro " ON \
        "qsstv-9.5.8" "Compiled from Repo (~20 minutes compile time) " OFF \
        3>&1 1>&2 2>&3)
    RET=$?
    if [ $RET -eq 1 ]; then
        $FUN = "NONE"
    fi
    echo $FUN >> $SIG_CONFIG

    FUN=$(whiptail --title "SIGdeb Installer" --checklist --separate-output \
        "Choose Packet Radio Applications" 20 80 12 \
        "direWolf" "DireWolf 1.7 Soundcard TNC for APRS " OFF \
        "linpac" "Packet Radio Temrinal with mail client " OFF \
        "xastir" "APRS Station Tracking and Reporting " OFF \
        3>&1 1>&2 2>&3)
    RET=$?
    if [ $RET -eq 1 ]; then
        $FUN = "NONE"
    fi
    echo $FUN >> $SIG_CONFIG
}

select_utilities() {
    FUN=$(whiptail --title "SIGdeb Installer" --checklist --separate-output \
        "Choose other Useful Applications" 20 120 12 \
        "wireshark" "Network Traffic Analyzer " OFF \
        "kismet" "Wireless snifferand monitor " OFF \
        "audacity" "Audio Editor " OFF \
        "pavu" "PulseAudio Control " OFF \
        "mumble" "VoIP Server and Client " OFF \
        "gpsPS" "GPS client and NTP sync " OFF \
        "gpredict" "Satellite Tracking " OFF \
        "splat" "RF Signal Propagation, Loss, And Terrain analysis tool for 20 MHz to 20 GHz " OFF \
        "tempest" "Uses your computer monitor to send out AM radio signals" OFF \
        3>&1 1>&2 2>&3)
    RET=$?
    if [ $RET -eq 1 ]; then
        $FUN = "NONE"
    fi
    echo $FUN >> $SIG_CONFIG
}

install_dependencies(){
	echo -e "${SIG_BANNER_COLOR}"
	echo -e "${SIG_BANNER_COLOR} #SIGDEB#"
	echo -e "${SIG_BANNER_COLOR} #SIGDEB#   Install Dependencies"
	echo -e "${SIG_BANNER_COLOR} #SIGDEB#"
	echo -e "${SIG_BANNER_RESET}"
    if [ ! -d "$SIGDEB_SOURCE" ]; then
    	mkdir $SIGDEB_SOURCE
    fi
    
    if [ ! -d "$SIGDEB_HOME" ]; then
    	mkdir $SIGDEB_HOME
    fi
    
	if [ ! -d "$SIGDEB_SDRANGEL" ]; then
    	mkdir $SIGDEB_SDRANGEL
    fi

	cd $SIGDEB_SOURCE

	sudo fallocate -l 2G /swapfile
	sudo chmod 600 /swapfile
	sudo mkswap /swapfile
	sudo swapon /swapfile

    sudo apt-get install -y git cmake g++ pkg-config autoconf automake libtool build-essential pulseaudio bison flex gettext ffmpeg \
	portaudio19-dev doxygen graphviz gnuplot gnuplot-x11 swig  icu-doc libjs-jquery-ui-docs tcl8.6 tk8.6 libvolk2-doc python-cycler-doc inkscape \
	tk8.6-blt2.5 ttf-bitstream-vera uhd-host dvipng texlive-latex-extra ttf-staypuft tix openssl

	sudo apt-get install -y libboost-all-dev libboost1.71-dev libboost1.71-tools-dev libboost1.71-doc libboost-container1.71-dev libboost-context1.71-dev \
	libboost-contract1.71-dev libboost-coroutine1.71-dev libboost-exception1.71-dev libboost-fiber1.71-dev libboost-graph1.71-dev libboost-graph-parallel1.71-dev \
	libboost-iostreams1.71-dev libboost-locale1.71-dev libboost-log1.71-dev libboost-math1.71-dev libboost-mpi1.71-dev libboost-mpi-python1.71-dev \
	libboost-numpy1.71-dev libboost-python1.71-dev libboost-random1.71-dev libboost-stacktrace1.71-dev libboost-timer1.71-dev libboost-type-erasure1.71-dev \
    libboost-wave1.71-dev libboost-atomic1.71-dev libboost-atomic1.71.0 libboost-chrono1.71-dev libboost-chrono1.71.0 libboost-date-time-dev \
	libboost-date-time1.71-dev libboost-filesystem-dev libboost-filesystem1.71-dev libboost-program-options-dev libboost-program-options1.71-dev \
	libboost-program-options1.71.0 libboost-regex-dev libboost-regex1.71-dev libboost-regex1.71.0 libboost-serialization1.71-dev libboost-serialization1.71.0 \
	libboost-system-dev libboost-system1.71-dev libboost-system1.71.0 libboost-test-dev libboost-test1.71-dev libboost-test1.71.0 \
	libboost-thread-dev libboost-thread1.71-dev libcanberra-gtk-module libcanberra-gtk0 libcppunit-1.15-0 libcppunit-dev libfftw3-bin \
	libfftw3-dev libfftw3-long3 libfftw3-quad3 libfreesrp0 libglfw3 libgmp-dev libgmpxx4ldbl libhidapi-libusb0 libicu-dev libjs-jquery-ui \
	liblimesuite20.01-1 liblog4cpp5-dev liblog4cpp5v5 libmirisdr0 libtk8.6 libfaad libfaad-dev

  
	sudo apt-get install -y libvolk2-bin libvolk2-dev libvolk2.2 libfaad-dev zlib1g-dev libasound2-dev libfftw3-dev libusb-1.0 libusb-1.0-0 libusb-1.0-0-dev libusb-dev \
	libopencv-dev libxml2-dev libaio-dev libnova-dev libwxgtk-media3.0-dev libcairo2-dev libavcodec-dev libpthread-stubs0-dev \
	libavformat-dev libfltk1.3-dev libfltk1.3 libsndfile1-dev libopus-dev libavahi-common-dev libavahi-client-dev libavdevice-dev libavutil-dev \
	libsdl1.2-dev libgsl-dev liblog4cpp5-dev libzmq3-dev libudev-dev liborc-0.4 liborc-0.4-0 liborc-0.4-dev libsamplerate0-dev libgmp-dev \
	libpcap-dev libcppunit-dev libbluetooth-dev qt5-default libpulse-dev libliquid-dev libswscale-dev libswresample-dev \
	libfftw3-doc libgles1 libosmesa6 gmp-doc libgmp10-doc libmpfr-dev libmpfrc++-dev libntl-dev libcppunit-doc zlib-devel libpng-devel

	sudo apt-get install -y python3-pip python3-numpy python3-mako python3-sphinx python3-lxml python3-yaml python3-click python3-click-plugins \
	python3-zmq python3-scipy python3-scapy python3-setuptools python3-pyqt5 python3-gi-cairo python-docutils python3-gobject python3-nose \
	python3-tornado texlive-extra-utils python-networkx-doc python3-gdal python3-pygraphviz | python3-pydot libgle3 python-pyqtgraph-doc \
	python-matplotlib-doc python3-cairocffi python3-tk-dbg python-matplotlib-data python3-cycler python3-kiwisolver python3-matplotlib python3-networkx \
	python3-opengl python3-pyqt5.qtopengl python3-pyqtgraph python3-tk python-pyside python-qt4 python3-qwt-qt5

	sudo apt-get install -y qtchooser libqt5multimedia5-plugins qtmultimedia5-dev libqt5websockets5-dev qttools5-dev qttools5-dev-tools \
	libqt5opengl5-dev qtbase5-dev libqt5quick5 libqt5charts5-dev qml-module-qtlocation  qml-module-qtpositioning qml-module-qtquick-window2 \
	qml-module-qtquick-dialogs qml-module-qtquick-controls qml-module-qtquick-controls2 qml-module-qtquick-layouts libqt5serialport5-dev \
	qtdeclarative5-dev qtpositioning5-dev qtlocation5-dev libqt5texttospeech5-dev libqwt-qt5-dev

	sudo python3 -m pip install --upgrade pip
	sudo pip3 install pygccxml

}

install_libraries(){
	echo -e "${SIG_BANNER_COLOR}"
	echo -e "${SIG_BANNER_COLOR} #SIGDEB#"
	echo -e "${SIG_BANNER_COLOR} #SIGDEB#   Install Libraries   (ETA: +30 Minutes)"
	echo -e "${SIG_BANNER_COLOR} #SIGDEB#"
	echo -e "${SIG_BANNER_RESET}"
	cd $SIGDEB_SOURCE

	# APT
	# Aptdec is a FOSS program that decodes images transmitted by NOAA weather satellites.
    cd $SIGDEB_SOURCE
	git clone https://github.com/srcejon/aptdec.git
	cd aptdec
	mkdir build; cd build
	cmake ..
	make -j4
	sudo make install
	sudo ldconfig

	# CM265cc
    cd $SIGDEB_SOURCE
	git clone https://github.com/f4exb/cm256cc.git
	cd cm256cc
	mkdir build; cd build
	cmake ..
	make -j4
	sudo make install
	sudo ldconfig

	# LibDAB
    cd $SIGDEB_SOURCE
	git clone https://github.com/srcejon/dab-cmdline
	cd dab-cmdline/library
	mkdir build; cd build
	cmake ..
	make -j4
	sudo make install
	sudo ldconfig

	# MBElib
    cd $SIGDEB_SOURCE
	git clone https://github.com/szechyjs/mbelib.git
	cd mbelib
	mkdir build; cd build
	cmake ..
	make -j4
	sudo make install
	sudo ldconfig

	# SerialDV
    cd $SIGDEB_SOURCE
	git clone https://github.com/f4exb/serialDV.git
	cd serialDV
	mkdir build; cd build
	cmake ..
	make -j4
	sudo make install
	sudo ldconfig

	# DSDcc
    cd $SIGDEB_SOURCE
	git clone https://github.com/f4exb/dsdcc.git
	cd dsdcc
	mkdir build; cd build
	cmake ..
	make -j4
	sudo make install
	sudo ldconfig

	# SGP4
	# python-sgp4 1.4-1 is available in the packager, installing this version just to be sure.
    cd $SIGDEB_SOURCE
	git clone https://github.com/dnwrnr/sgp4.git
	cd sgp4
	mkdir build; cd build
	cmake ..
	make -j4
	sudo make install
	sudo ldconfig

	# LibSigMF
    cd $SIGDEB_SOURCE
	git clone https://github.com/deepsig/libsigmf.git
	cd libsigmf
	mkdir build; cd build
	cmake ..
	make -j4
	sudo make install
	sudo ldconfig
	
    # Liquid-DSP
	cd $SIGDEB_SOURCE
	git clone https://github.com/jgaeddert/liquid-dsp
	cd liquid-dsp
	./bootstrap.sh
	./configure --enable-fftoverride 
	make -j4
	sudo make install
	sudo ldconfig

    # Bluetooth Baseband Library
	cd $SIGDEB_SOURCE
	git clone https://github.com/greatscottgadgets/libbtbb.git
	cd libbtbb
	mkdir build && cd build
	cmake ..
	make -j4
	sudo make install
	sudo ldconfig

	# Hamlib
	wget https://github.com/Hamlib/Hamlib/releases/download/4.3/hamlib-4.3.tar.gz -P $HOME/Downloads
	tar -zxvf $HOME/Downloads/hamlib-4.3.tar.gz -C $SIGDEB_SOURCE
	cd $SIGDEB_SOURCE/hamlib-4.3
	./configure --prefix=/usr/local --enable-static
	make
	sudo make install
	sudo ldconfig
}

install_gnuradio38(){
	cd $SIGDEB_SOURCE
	echo -e "${SIG_BANNER_COLOR}"
	echo -e "${SIG_BANNER_COLOR} #SIGDEB#"
	echo -e "${SIG_BANNER_COLOR} #SIGDEB#   Install GNUradio 3.8    (ETA: +60 Minutes)"
	echo -e "${SIG_BANNER_COLOR} #SIGDEB#"
	echo -e "${SIG_BANNER_RESET}"
	git clone https://github.com/gnuradio/gnuradio.git
	cd gnuradio
	git checkout maint-3.8
	git submodule update --init --recursive
	mkdir build && cd build
	cmake -DCMAKE_BUILD_TYPE=Release -DPYTHON_EXECUTABLE=/usr/bin/python3 ../
	make -j4
	sudo make install
	sudo ldconfig
	cd ~
	echo "export PYTHONPATH=/usr/local/lib/python3/dist-packages:/usr/local/lib/python3.6/dist-packages:$PYTHONPATH" >> .profile
	echo "export LD_LIBRARY_PATH=/usr/local/lib:$LD_LIBRARY_PATH" >> .profile
}


install_sdrangel(){
	echo -e "${SIG_BANNER_COLOR}"
	echo -e "${SIG_BANNER_COLOR} #SIGDEB#"
	echo -e "${SIG_BANNER_COLOR} #SIGDEB#   Install SDRangel (ETA: +80 Minutes)"
	echo -e "${SIG_BANNER_COLOR} #SIGDEB#"
	echo -e "${SIG_BANNER_RESET}"
	cd $SIGDEB_SOURCE
    sudo mkdir -p /opt/build
	sudo chown pi:users /opt/build
	sudo mkdir -p /opt/install
	sudo chown pi:users /opt/install

	# APT
	# Aptdec is a FOSS program that decodes images transmitted by NOAA weather satellites.
    cd $SIGDEB_SDRANGEL
	git clone https://github.com/srcejon/aptdec.git
	cd aptdec
	git checkout libaptdec
	mkdir build; cd build
	cmake -Wno-dev -DCMAKE_INSTALL_PREFIX=/opt/install/aptdec ..
	make -j $(nproc) install

	# CM265cc
    cd $SIGDEB_SDRANGEL
	git clone https://github.com/f4exb/cm256cc.git
	cd cm256cc
	git reset --hard c0e92b92aca3d1d36c990b642b937c64d363c559
	mkdir build; cd build
	cmake -Wno-dev -DCMAKE_INSTALL_PREFIX=/opt/install/cm256cc ..
	make -j $(nproc) install

	# LibDAB
    cd $SIGDEB_SDRANGEL
	git clone https://github.com/srcejon/dab-cmdline
	cd dab-cmdline/library
	git checkout msvc
	mkdir build; cd build
	cmake -Wno-dev -DCMAKE_INSTALL_PREFIX=/opt/install/libdab ..
	make -j $(nproc) install

	# MBElib
    cd $SIGDEB_SDRANGEL
	git clone https://github.com/szechyjs/mbelib.git
	cd mbelib
	git reset --hard 9a04ed5c78176a9965f3d43f7aa1b1f5330e771f
	mkdir build; cd build
	cmake -Wno-dev -DCMAKE_INSTALL_PREFIX=/opt/install/mbelib ..
	make -j $(nproc) install

	# SerialDV
    cd $SIGDEB_SDRANGEL
	git clone https://github.com/f4exb/serialDV.git
	cd serialDV
	git reset --hard "v1.1.4"
	mkdir build; cd build
	cmake -Wno-dev -DCMAKE_INSTALL_PREFIX=/opt/install/serialdv ..
	make -j $(nproc) install

	# DSDcc
    cd $SIGDEB_SDRANGEL
	git clone https://github.com/f4exb/dsdcc.git
	cd dsdcc
	git reset --hard "v1.9.3"
	mkdir build; cd build
	cmake -Wno-dev -DCMAKE_INSTALL_PREFIX=/opt/install/dsdcc -DUSE_MBELIB=ON -DLIBMBE_INCLUDE_DIR=/opt/install/mbelib/include -DLIBMBE_LIBRARY=/opt/install/mbelib/lib/libmbe.so -DLIBSERIALDV_INCLUDE_DIR=/opt/install/serialdv/include/serialdv -DLIBSERIALDV_LIBRARY=/opt/install/serialdv/lib/libserialdv.so ..
	make -j $(nproc) install

	# Codec2/FreeDV
	# Codec2 is already installed from the packager, but this version is required for SDRangel.
    cd $SIGDEB_SDRANGEL
	git clone https://github.com/drowe67/codec2.git
	cd codec2
	git reset --hard 76a20416d715ee06f8b36a9953506876689a3bd2
	mkdir build_linux; cd build_linux
	cmake -Wno-dev -DCMAKE_INSTALL_PREFIX=/opt/install/codec2 ..
	make -j $(nproc) install

	# SGP4
	# python-sgp4 1.4-1 is available in the packager, installing this version just to be sure.
    cd $SIGDEB_SDRANGEL
	git clone https://github.com/dnwrnr/sgp4.git
	cd sgp4
	mkdir build; cd build
	cmake -Wno-dev -DCMAKE_INSTALL_PREFIX=/opt/install/sgp4 ..
	make -j $(nproc) install

	# LibSigMF
    cd $SIGDEB_SDRANGEL
	git clone https://github.com/f4exb/libsigmf.git
	cd libsigmf
	git checkout "new-namespaces"
	mkdir build; cd build
	cmake -Wno-dev -DCMAKE_INSTALL_PREFIX=/opt/install/libsigmf .. 
	make -j $(nproc) install
	sudo ldconfig

	# RTLSDR
	cd $SIGDEB_SDRANGEL
	git clone https://github.com/osmocom/rtl-sdr.git librtlsdr
	cd librtlsdr
	git reset --hard be1d1206bfb6e6c41f7d91b20b77e20f929fa6a7
	mkdir build; cd build
	cmake -Wno-dev -DDETACH_KERNEL_DRIVER=ON -DCMAKE_INSTALL_PREFIX=/opt/install/librtlsdr ..
	make -j4 install

	# PlutoSDR
	cd $SIGDEB_SDRANGEL
	git clone https://github.com/analogdevicesinc/libiio.git
	cd libiio
	git reset --hard v0.21
	mkdir build; cd build
	cmake -Wno-dev -DCMAKE_INSTALL_PREFIX=/opt/install/libiio -DINSTALL_UDEV_RULE=OFF ..
	make -j4 install

	# HackRF
	cd $SIGDEB_SDRANGEL
	git clone https://github.com/mossmann/hackrf.git
	cd hackrf/host
	git reset --hard "v2018.01.1"
	mkdir build; cd build
	cmake -Wno-dev -DCMAKE_INSTALL_PREFIX=/opt/install/libhackrf -DINSTALL_UDEV_RULES=OFF ..
	make -j4 install

	# LimeSDR
	cd $SIGDEB_SDRANGEL
	git clone https://github.com/myriadrf/LimeSuite.git
	cd LimeSuite
	git reset --hard "v20.01.0"
	mkdir builddir; cd builddir
	cmake -Wno-dev -DCMAKE_INSTALL_PREFIX=/opt/install/LimeSuite ..
	make -j4 install

	#SoapySDR
	cd $SIGDEB_SDRANGEL
	git clone https://github.com/pothosware/SoapySDR.git
	cd SoapySDR
	git reset --hard "soapy-sdr-0.7.1"
	mkdir build; cd build
	cmake -DCMAKE_INSTALL_PREFIX=/opt/install/SoapySDR ..
	make -j4 install
	
	#SoapyRTLSDR
	cd $SIGDEB_SDRANGEL
	git clone https://github.com/pothosware/SoapyRTLSDR.git
	cd SoapyRTLSDR
	mkdir build && cd build
	cmake -DCMAKE_INSTALL_PREFIX=/opt/install/SoapySDR  -DRTLSDR_INCLUDE_DIR=/opt/install/librtlsdr/include -DRTLSDR_LIBRARY=/opt/install/librtlsdr/lib/librtlsdr.so -DSOAPY_SDR_INCLUDE_DIR=/opt/install/SoapySDR/include -DSOAPY_SDR_LIBRARY=/opt/install/SoapySDR/lib/libSoapySDR.so ..
	make -j4 install

	#SoapyHackRF
    cd $SIGDEB_SDRANGEL
	git clone https://github.com/pothosware/SoapyHackRF.git
	cd SoapyHackRF
	mkdir build; cd build
	cmake -DCMAKE_INSTALL_PREFIX=/opt/install/SoapySDR -DLIBHACKRF_INCLUDE_DIR=/opt/install/libhackrf/include/libhackrf -DLIBHACKRF_LIBRARY=/opt/install/libhackrf/lib/libhackrf.so -DSOAPY_SDR_INCLUDE_DIR=/opt/install/SoapySDR/include -DSOAPY_SDR_LIBRARY=/opt/install/SoapySDR/lib/libSoapySDR.so ..
	make -j4 install

	#SoapyLimeRF
    cd $SIGDEB_SDRANGEL
	cd LimeSuite/builddir
	cmake -Wno-dev -DCMAKE_INSTALL_PREFIX=/opt/install/LimeSuite -DCMAKE_PREFIX_PATH=/opt/install/SoapySDR ..
	make -j4 install
	cp /opt/install/LimeSuite/lib/SoapySDR/modules0.7/libLMS7Support.so /opt/install/SoapySDR/lib/SoapySDR/modules0.7

	#SoapyRemote
	cd $SIGDEB_SDRANGEL
	git clone https://github.com/pothosware/SoapyRemote.git
	cd SoapyRemote
	git reset --hard "soapy-remote-0.5.1"
	mkdir build; cd build
	cmake -DCMAKE_INSTALL_PREFIX=/opt/install/SoapySDR -DSOAPY_SDR_INCLUDE_DIR=/opt/install/SoapySDR/include -DSOAPY_SDR_LIBRARY=/opt/install/SoapySDR/lib/libSoapySDR.so ..
	make -j4 install

	#SDRangel
    cd $SIGDEB_SDRANGEL
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
	sudo cp $SIGDEB_HOME/snowflakes/SIGdeb_sdrangel.sh /usr/local/bin

    cd $HOME/.config/
	mkdir f4exb
	cd f4exb
	# Generate a new wisdom file for FFT sizes : 128, 256, 512, 1024, 2048, 4096, 8192, 16384 and 32768.
	# This will take a very long time.
	fftwf-wisdom -n -o fftw-wisdom 128 256 512 1024 2048 4096 8192 16384 32768

    # Add VOX for Transimtting with SDRangel
	cd $SIGDEB_SOURCE
	git clone https://gitlab.wibisono.or.id/published/voxangel.git
	
}

install_kismet(){
	echo -e "${SIG_BANNER_COLOR}"
	echo -e "${SIG_BANNER_COLOR} #SIGDEB#"
	echo -e "${SIG_BANNER_COLOR} #SIGDEB#   Install Kismet"
	echo -e "${SIG_BANNER_COLOR} #SIGDEB#"
	echo -e "${SIG_BANNER_RESET}"
	TERM=ansi whiptail --infobox "Installing Kismet" 10 100
    wget -O - https://www.kismetwireless.net/repos/kismet-release.gpg.key | sudo apt-key add -
    echo 'deb https://www.kismetwireless.net/repos/apt/release/buster buster main' | sudo tee /etc/apt/sources.list.d/kismet.list
	sudo apt update
    sudo apt-get install -y kismet
    #
    # Say yes when asked about suid helpers
    #
}

install_fldigi(){
	echo -e "${SIG_BANNER_COLOR}"
	echo -e "${SIG_BANNER_COLOR} #SIGDEB#"
	echo -e "${SIG_BANNER_COLOR} #SIGDEB#   Install Fldigi Suite"
	echo -e "${SIG_BANNER_COLOR} #SIGDEB#"
	echo -e "${SIG_BANNER_RESET}"
    # Install FLxmlrpc
	wget http://www.w1hkj.com/files/flxmlrpc/flxmlrpc-0.1.4.tar.gz -P $HOME/Downloads
	tar -zxvf $HOME/Downloads/flxmlrpc-0.1.4.tar.gz -C $SIGDEB_SOURCE
	cd $SIGDEB_SOURCE/flxmlrpc-0.1.4
	./configure --prefix=/usr/local --enable-static
	make
	sudo make install
	sudo ldconfig
	
	# Install FLrig
	wget http://www.w1hkj.com/files/flrig/flrig-1.4.2.tar.gz -P $HOME/Downloads
	tar -zxvf $HOME/Downloads/flrig-1.4.2.tar.gz -C $SIGDEB_SOURCE
	cd $SIGDEB_SOURCE/flrig-1.4.2
	./configure --prefix=/usr/local --enable-static
	make
	sudo make install
	sudo ldconfig
	sudo cp $SIGDEB_SOURCE/flrig-1.4.2/data/flrig.desktop $SIGDEB_DESKTOP

	#Install Fldigi
	wget http://www.w1hkj.com/files/fldigi/fldigi-4.1.20.tar.gz -P $HOME/Downloads
	tar -zxvf $HOME/Downloads/fldigi-4.1.20.tar.gz -C $SIGDEB_SOURCE
	cd $SIGDEB_SOURCE/fldigi-4.1.20
	./configure --prefix=/usr/local --enable-static
	make
	sudo make install
	sudo ldconfig
	sudo cp $SIGDEB_SOURCE/fldigi-4.1.20/data/fldigi.desktop $SIGDEB_DESKTOP
	sudo cp $SIGDEB_SOURCE/fldigi-4.1.20/data/flarq.desktop $SIGDEB_DESKTOP
}

install_wsjtx(){
	echo -e "${SIG_BANNER_COLOR}"
	echo -e "${SIG_BANNER_COLOR} #SIGDEB#"
	echo -e "${SIG_BANNER_COLOR} #SIGDEB#   Install WSJT-Xt"
	echo -e "${SIG_BANNER_COLOR} #SIGDEB#"
	echo -e "${SIG_BANNER_RESET}"
    wget https://physics.princeton.edu/pulsar/K1JT/wsjtx_2.4.0_armhf.deb -P $HOME/Downloads
	sudo dpkg -i $HOME/Downloads/wsjtx_2.4.0_armhf.deb
	# Will get error next command fixes error and downloads dependencies
	sudo apt-get --fix-broken install
	sudo dpkg -i $HOME/Downloads/wsjtx_2.4.0_armhf.deb
}

install_qsstv(){
	echo -e "${SIG_BANNER_COLOR}"
	echo -e "${SIG_BANNER_COLOR} #SIGDEB#"
	echo -e "${SIG_BANNER_COLOR} #SIGDEB#   Install QSSTV"
	echo -e "${SIG_BANNER_COLOR} #SIGDEB#"
	echo -e "${SIG_BANNER_RESET}"
    sudo apt-get install -y libhamlib-dev libv4l-dev
	sudo apt-get install -y libopenjp2-7 libopenjp2-7-dev
	wget http://users.telenet.be/on4qz/qsstv/downloads/qsstv_9.5.8.tar.gz -P $HOME/Downloads
	tar -xvzf $HOME/Downloads/qsstv_9.5.8.tar.gz -C $SIGDEB_SOURCE
	cd $SIGDEB_SOURCE/qsstv
	qmake
	make
	sudo make install
}

install_tempest-eliza(){
	echo -e "${SIG_BANNER_COLOR}"
	echo -e "${SIG_BANNER_COLOR} #SIGDEB#"
	echo -e "${SIG_BANNER_COLOR} #SIGDEB#   Install TEMPEST for Eliza"
	echo -e "${SIG_BANNER_COLOR} #SIGDEB#"
	echo -e "${SIG_BANNER_RESET}"
	wget http://www.erikyyy.de/tempest/tempest_for_eliza-1.0.5.tar.gz -P $HOME/Downloads
	tar -zxvf $HOME/Downloads/tempest_for_eliza-1.0.5.tar.gz -C $SIGDEB_SOURCE
	cd $SIGDEB_SOURCE/tempest_for_eliza-1.0.5
	./configure
	make
	sudo make install
	sudo ldconfig
}

install_sigdebmenu(){
	echo -e "${SIG_BANNER_COLOR}"
	echo -e "${SIG_BANNER_COLOR} #SIGDEB#"
	echo -e "${SIG_BANNER_COLOR} #SIGDEB#   Install SIGdeb Menu and Desktop Shortcuts"
	echo -e "${SIG_BANNER_COLOR} #SIGDEB#"
	echo -e "${SIG_BANNER_RESET}"
    
	#
	# Copy Menu items into relevant directories
	# 
	
	#sudo cp $SIGDEB_DESKTOP/sigdeb_example.desktop $DESKTOP_FILES
	sudo cp $SIGDEB_SOURCE/LimeSuite/Desktop/lime-suite.desktop $DESKTOP_FILES
	sudo cp $SIGDEB_SOURCE/gnuradio/grc/scripts/freedesktop/gnuradio-grc.desktop $DESKTOP_FILES
	sudo cp $SIGDEB_SOURCE/SDRangel/sdrangel/build/sdrangel.desktop $DESKTOP_FILES
	sudo cp $SIGDEB_SOURCE/flrig-1.4.2/data/flrig.desktop $DESKTOP_FILES
	sudo cp $SIGDEB_SOURCE/fldigi-4.1.20/data/flarq.desktop $DESKTOP_FILES
	sudo cp $SIGDEB_SOURCE/fldigi-4.1.20/data/fldigi.desktop $DESKTOP_FILES
	sudo cp $SIGDEB_SOURCE/qsstv/qsstv.desktop $DESKTOP_FILES
	sudo cp $SIGDEB_DESKTOP/*.desktop $DESKTOP_FILES
	sudo cp $SIGDEB_DESKTOP/SIGdeb.directory $DESKTOP_DIRECTORY
	sudo cp $SIGDEB_DESKTOP/SIGdeb.menu $DESKTOP_XDG_MENU
	sudo cp $SIGDEB_ICONS/* $DESKTOP_ICONS
	
	#
	# Add SIGdeb Category for each installed application
	#

	sudo sed -i "s/Categories.*/Categories=$SIGDEB_MENU_CATEGORY;/" $DESKTOP_FILES/lime-suite.desktop
	sudo sed -i "s/Categories.*/Categories=$SIGDEB_MENU_CATEGORY;/" $DESKTOP_FILES/gnuradio-grc.desktop
	sudo sed -i "s/Categories.*/Categories=$SIGDEB_MENU_CATEGORY;/" $DESKTOP_FILES/gqrx.desktop
	sudo sed -i "s/Categories.*/Categories=$SIGDEB_MENU_CATEGORY;/" $DESKTOP_FILES/CubicSDR.desktop
	sudo sed -i "s/Categories.*/Categories=$SIGDEB_MENU_CATEGORY;/" $DESKTOP_FILES/sdrangel.desktop
	sudo sed -i "s/Categories.*/Categories=$SIGDEB_MENU_CATEGORY;/" $DESKTOP_FILES/direwolf.desktop
	sudo sed -i "s/Categories.*/Categories=$SIGDEB_MENU_CATEGORY;/" $DESKTOP_FILES/linpac.desktop
	sudo sed -i "s/Categories.*/Categories=$SIGDEB_MENU_CATEGORY;/" $DESKTOP_FILES/xastir.desktop
	sudo sed -i "s/Categories.*/Categories=$SIGDEB_MENU_CATEGORY;/" $DESKTOP_FILES/flarq.desktop
	sudo sed -i "s/Categories.*/Categories=$SIGDEB_MENU_CATEGORY;/" $DESKTOP_FILES/fldigi.desktop
	sudo sed -i "s/Categories.*/Categories=$SIGDEB_MENU_CATEGORY;/" $DESKTOP_FILES/flrig.desktop
	sudo sed -i "s/Categories.*/Categories=$SIGDEB_MENU_CATEGORY;/" $DESKTOP_FILES/wsjtx.desktop
	sudo sed -i "s/Categories.*/Categories=$SIGDEB_MENU_CATEGORY;/" $DESKTOP_FILES/message_aggregator.desktop
	sudo sed -i "s/Categories.*/Categories=$SIGDEB_MENU_CATEGORY;/" $DESKTOP_FILES/qsstv.desktop
	sudo sed -i "s/Categories.*/Categories=$SIGDEB_MENU_CATEGORY;/" $DESKTOP_FILES/mumble.desktop
	sudo sed -i "s/Categories.*/Categories=$SIGDEB_MENU_CATEGORY;/" $DESKTOP_FILES/gpredict.desktop
	sudo sed -i "s/Categories.*/Categories=$SIGDEB_MENU_CATEGORY;/" $DESKTOP_FILES/wireshark.desktop
	sudo sed -i "s/Categories.*/Categories=$SIGDEB_MENU_CATEGORY;/" $DESKTOP_FILES/sigidwiki.desktop
	sudo sed -i "s/Categories.*/Categories=$SIGDEB_MENU_CATEGORY;/" $DESKTOP_FILES/sigdeb_example.desktop
	sudo sed -i "s/Categories.*/Categories=$SIGDEB_MENU_CATEGORY;/" $DESKTOP_FILES/sigdeb_home.desktop
	
	#
	# Add installed applications into SIGdeb menu
	#

	xdg-desktop-menu install --novendor --noupdate $DESKTOP_DIRECTORY/SIGdeb.directory $DESKTOP_FILES/lime-suite.desktop
	xdg-desktop-menu install --novendor --noupdate $DESKTOP_DIRECTORY/SIGdeb.directory $DESKTOP_FILES/gnuradio-grc.desktop
	xdg-desktop-menu install --novendor --noupdate $DESKTOP_DIRECTORY/SIGdeb.directory $DESKTOP_FILES/gqrx.desktop
	xdg-desktop-menu install --novendor --noupdate $DESKTOP_DIRECTORY/SIGdeb.directory $DESKTOP_FILES/CubicSDR.desktop
	xdg-desktop-menu install --novendor --noupdate $DESKTOP_DIRECTORY/SIGdeb.directory $DESKTOP_FILES/sdrangel.desktop
	xdg-desktop-menu install --novendor --noupdate $DESKTOP_DIRECTORY/SIGdeb.directory $DESKTOP_FILES/direwolf.desktop
	xdg-desktop-menu install --novendor --noupdate $DESKTOP_DIRECTORY/SIGdeb.directory $DESKTOP_FILES/linpac.desktop
	xdg-desktop-menu install --novendor --noupdate $DESKTOP_DIRECTORY/SIGdeb.directory $DESKTOP_FILES/xastir.desktop
	xdg-desktop-menu install --novendor --noupdate $DESKTOP_DIRECTORY/SIGdeb.directory $DESKTOP_FILES/flarq.desktop
	xdg-desktop-menu install --novendor --noupdate $DESKTOP_DIRECTORY/SIGdeb.directory $DESKTOP_FILES/fldigi.desktop
	xdg-desktop-menu install --novendor --noupdate $DESKTOP_DIRECTORY/SIGdeb.directory $DESKTOP_FILES/flrig.desktop
	xdg-desktop-menu install --novendor --noupdate $DESKTOP_DIRECTORY/SIGdeb.directory $DESKTOP_FILES/wsjtx.desktop
	xdg-desktop-menu install --novendor --noupdate $DESKTOP_DIRECTORY/SIGdeb.directory $DESKTOP_FILES/message_aggregator.desktop
	xdg-desktop-menu install --novendor --noupdate $DESKTOP_DIRECTORY/SIGdeb.directory $DESKTOP_FILES/qsstv.desktop
	xdg-desktop-menu install --novendor --noupdate $DESKTOP_DIRECTORY/SIGdeb.directory $DESKTOP_FILES/mumble.desktop
	xdg-desktop-menu install --novendor --noupdate $DESKTOP_DIRECTORY/SIGdeb.directory $DESKTOP_FILES/gpredict.desktop
	xdg-desktop-menu install --novendor --noupdate $DESKTOP_DIRECTORY/SIGdeb.directory $DESKTOP_FILES/wireshark.desktop
	xdg-desktop-menu install --novendor --noupdate $DESKTOP_DIRECTORY/SIGdeb.directory $DESKTOP_FILES/sigidwiki.desktop
	xdg-desktop-menu install --novendor --noupdate $DESKTOP_DIRECTORY/SIGdeb.directory $DESKTOP_FILES/sigdeb_example.desktop
	xdg-desktop-menu install --novendor --noupdate $DESKTOP_DIRECTORY/SIGdeb.directory $DESKTOP_FILES/sigdeb_home.desktop

	# Add Desktop links
	sudo cp $SIGDEB_DESKTOP/sigdeb_home.desktop $HOME/Desktop/SIGdeb.desktop


	# Remove Rogue desktop file to ensure we use the one we provided for direwolf
	sudo rm -rf /usr/local/share/applications/direwolf.desktop
}

config_stuff(){
	TERM=ansi whiptail --infobox "When the pop-up window appears, answer NO to the first \
	two questions. Last question will ask you to create a password for the SuperUser \
	account to manage the VoIP server" 10 100
	cd $SIGDEB_SOURCE
    sleep 9
	sudo dpkg-reconfigure mumble-server
}


###
###  MAIN
###

touch $SIG_CONFIG
calc_wt_size
##
## INSTALL GNURADIO
##

# GNUradio
if grep gnuradio-3.8 "$SIG_CONFIG"
then
	install_gnuradio38
else
	sudo apt-get install -y gnuradio gnuradio-dev
fi
