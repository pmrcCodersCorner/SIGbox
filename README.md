# SIGdeb Build Script

Release: 20211013-0420

## Background

This build script is part of a larger project called SIGbox. 

Much how you see Amateur Radio operators build "go-kits" for remote or emergency operations, SIGbox is a "go-kit" for Signal Intelligence (SIGINT) enthusiasts with emphasis on capabilities in the VHF, UHF, and SHF spectrum. For completeness, HF spectrum related software is included for optional install.

![alt-test](https://github.com/joecupano/SIGbox/blob/main/tools/SIGbox_architecture.png)

## SIGdeb

SIGdeb is the compute component of SIGbox built on Ubuntu 20.04 Desktop. The SIGdeb Build Script is run on desktop machine as user with sudo privileges.

Total install time varies if you choose compile some software versus going with packages available frome the Debian Distro repo. Below is a list of software that is installed.
Asterisk (*) indicate software packages that are compiled.

```

Device Drivers
- rtl-sdr RTL2832U & R820T2-Based *
- hackrf Hack RF One *
- libiio PlutoSDR *
- limesuite LimeSDR *
- soapysdr SoapySDR Library *
- soapyremote Use any Soapy SDR Remotely *
- soapyrtlsdr Soapy SDR Module for RTLSDR *
- soapyhackrf Soapy SDR Module for HackRF One *
- soapyplutosdr Soapy SDR Module for PlutoSD *

Libraries and Decoders
- cm256cc *
- dab-cmdline/library *
- mbelib *
- serialDV *
- dsdcc *
- sgp4 *
- libsigmf *
- liquid-dsp *
- libbtbb *
- Hamlib 4.3 *

SDR Applications
- GNU Radio 3.8.1
- SDRangel *
- SDR++ *

Packet Radio
- AX.25
- linpac
- direwolf 1.7 *
- xastir APRS Station Tracking and Reporting

Amateur Radio
- fldigi 4.1.06
- wsjt-x 2.5.0
- qsstv 9.4.4

Other Useful Applicaiotns
- GPS and NTP Services
- Artemis:    Local SIGint database
- gpredict:   Satellite Tracking
- wireshark:  Network Traffic Analyzer (WiFi, Bluetooth)
- kismet:     Wireless network monitoring tool
- SPLAT:      RF Signal Propagation, Loss, And Terrain analysis tool for 20 MHz to 20 GHz


```

## Fresh Install

- Login as a user with sudo privileges
- Install tools you will need to build and compile applications
- Create a directory in your home called source and switch into it
- Clone the Repo
- Change directory into SIGdeb
- Run SIGdeb_installer.sh
- Follow script instructions.

```
sudo apt-get install -y build-essential git
mkdir ~/source && cd ~/source
git clone https://github.com/joecupano/SIGdeb.git
cd SIGdeb
./SIGdeb_installer.sh
```

## APRS and Packet using a VHF/UHF Transceiver

SDRangel and other SDR applications have the capability to decode APRS and Packet Radio signals and transmit at very low RF power levels with SDR devices supported. If you have an Amateur Radio license and aspire to operate serious distance including satellites then you will need VHF/UHF transceiver capable of 5 watts for the latter interfacing to the transceiver through audio and radio control via Hamlib.

In the past dedicated hardware known as TNCs (terminal node controllers) was used between a computer and transceiver. But the signals themselves are audio so TNCs were replaced with sofwtare and soundcards connected to the transceiver. For this build DireWolf is the software replacing the TNC and AX.25 software providing the data-link layer above it that provides sockets to it.

If you are planning to operate APRS and Packet Radio with a transceiver then configuring DireWolf and AX.25 is necessary. Otherwise you can skip the subsections. 

### AX.25

You will need to edit a line in the /etc/ax25/axports file as follows:sudo apt-get install -y build-essential git

```
sudo nano /etc/ax25/axports
```

- Change **N0CALL** to your callsign followed by a hyphen and a number 1 to 15. (For Example  N3RDY-3)

```
# /etc/ax25/axports
#
# The format of this file is:
#
# name callsign speed paclen window description
#
ax0     N0CALL-3      1200    255     4       APRS / Packet
#1      OH2BNS-1        1200    255     2       144.675 MHz (1200  bps)
#2      OH2BNS-9        38400   255     7       TNOS/Linux  (38400 bps)
```

- Save and exit


### Artemis
Artemis allows for various example signals to be quickly viewed with the corresponding example waterfall image, frequency, bandwidth and other information. There is also a filtering function that allows you to search by frequency and type of signal.

### DireWolf
DireWolf needs to be running for APRS and Packet applications to have use the AX0 interface defined in the previou section. You will need to configure your
callsign, the soundcard device to use, and whether using PTT or VOX in the **$HOME/direwolf.conf** file. The conf file itslef is well documented in how to configure else consult the [DireWolf online docs](https://github.com/wb2osz/direwolf/tree/master/doc).

Because a number of factors go into a successful DireWold setup with your transceiver, configuration discussion is deferred to the [official DireWolf documentation](https://github.com/wb2osz/direwolf/tree/master/doc).

### XASTIR
Xastir is an application that provides geospatial mappng of APRS signals. It needs to configured to use the RF interface provided by DireWolf. You must start Direwolf in a separately terminal window before you start Xastir. Be sure to consult [Xastir online documentation](https://xastir.org/index.php/Main_Page) for more info.

### Gpredict
Some satellites have packet capability. Gpredict is a real-time satellite tracking and orbit prediction application. It needs to be configured with your location’s latitude, longitude, altitude, plus online data feeds for accurate tracking. Be sure to consult [Gpredict documentation]( http://gpredict.oz9aec.net/documents.php} for more info

## Post Installation

Though all the software is installed, many apps will require further configuration. Some will require configuration per use if you are using different SDR devices for different use cases. This section covers the configurations that only need to be done one time.

## What Else
Yes, I know there are more apps installed. There is no short-cut and must defer you to the  documentation on their respective sites


