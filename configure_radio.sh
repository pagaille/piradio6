#!/bin/bash
# set -x
# Raspberry Pi Internet Radio
# $Id: configure_radio.sh,v 1.85 2018/12/13 13:40:41 bob Exp $
#
# Author : Bob Rathbone
# Site   : http://www.bobrathbone.com
#
# This program is used during installation to set up which
# radio daemon is to be used
#
# License: GNU V3, See https://www.gnu.org/copyleft/gpl.html
#
# Disclaimer: Software is provided as is and absolutly no warranties are implied or given.
#	     The authors shall not be liable for any loss or damage however caused.
#
# This program uses whiptail. Set putty terminal to use UTF-8 charachter set
# for best results

# If -s flag specified (See piradio.postinst script)
FLAGS=$1

INIT=/etc/init.d/radiod
SERVICE=/lib/systemd/system/radiod.service
BINDIR="\/usr\/share\/radio\/"	# Used for sed so \ needed
DIR=/usr/share/radio
CONFIG=/etc/radiod.conf
BOOTCONFIG=/boot/config.txt
LOG=${DIR}/install.log

LXSESSION=""	# Start desktop radio at boot time
FULL_SCREEN=""	# Start graphic radio fullscreen
SCREEN_SIZE="800x480"	# Screen size 800x480, 720x480 or 480x320
PROGRAM="Daemon radiod configured"
GPROG=""	# Which graphical radio (gradio or vgradio)
FLIP_OLED_DISPLAY=0	# 1 = Flip OLED idisplay upside down

# Wiring type and schemes
BUTTON_WIRING=0	# 0 Not used or SPI/I2C, 1=Buttons, 2=Rotary encoders, 3=PHat BEAT
LCD_WIRING=0	# 0 not used, 1=standard LCD wiring, 
GPIO_PINS=0	# 0 Not configured, 1=40 pin wiring, 2=26 pin 
PULL_UP_DOWN=0  # Pull up/down resistors 1=Up, 0=Down
USER_INTERFACE=0	# 0 Not configured, 1=Buttons, 2=Rotary encoders, 3=HDMI/Touch-screen
			# 4=IQaudIO(I2C), 5=Pimoroni pHAT(SPI), 6=Adafruit RGB(I2C),
			# 7=PiFace CAD
# Display type
DISPLAY_TYPE=""
I2C_REQUIRED=0
I2C_ADDRESS="0x0"
SPI_REQUIRED=0

# Display characteristics
I2C_ADDRESS=0x00	# I2C device address
LINES=4			# Number of display lines
WIDTH=20		# Display character width

# Old wiring down switch
DOWN_SWITCH=10

# Volume sensitivity
VOLUME_RANGE=20

# Date format (Use default in radiod.conf)
DATE_FORMAT=""	

sudo rm -f ${LOG}
echo "$0 configuration log, $(date) " | tee ${LOG}

# Check if user wants to configure radio if upgrading
if [[ -f ${CONFIG}.org ]]; then
	ans=0
	ans=$(whiptail --title "Upgrading, Re-configure radio?" --menu "Choose your option" 15 75 9 \
	"1" "Run radio configuration?" \
	"2" "Do not change configuration?" 3>&1 1>&2 2>&3) 

	exitstatus=$?
	if [[ $exitstatus != 0 ]] || [[ ${ans} == '2' ]]; then
		echo "Current configuration in ${CONFIG} unchanged" | tee -a ${LOG}
		exit 0
	fi
fi

# Copy the distribution configuration
ans=$(whiptail --title "Replace your configuration file ?" --menu "Choose your option" 15 75 9 \
"1" "Replace configuration file" \
"2" "Do not replace configuration" 3>&1 1>&2 2>&3) 

exitstatus=$?
if [[ $exitstatus != 0 ]]; then
	exit 0

elif [[ ${ans} == '1' ]]; then
	pwd 
	sudo mv ${CONFIG} ${CONFIG}.save	
	echo "Existing configuration  copied to ${CONFIG}.save" | tee -a ${LOG}
	sudo cp ${DIR}/radiod.conf ${CONFIG}
	echo "Current configuration ${CONFIG} replaced with distribution" | tee -a ${LOG}
fi

# Select the user interface (Buttons or Rotary encoders)
ans=0
selection=1 
while [ $selection != 0 ]
do
	ans=$(whiptail --title "Select user interface" --menu "Choose your option" 15 75 9 \
	"1" "Push button directly connected to GPIO pins" \
	"2" "Radio with Rotary Encoders" \
	"3" "Mouse or touch screen only" \
	"4" "IQAudio Cosmic Controller" \
	"5" "Pimoroni pHat BEAT with own push buttons" \
	"6" "Adafruit RGB plate with own push buttons" \
	"7" "PiFace CAD with own push buttons" \
	"8" "Do not change configuration" 3>&1 1>&2 2>&3) 

	exitstatus=$?
	if [[ $exitstatus != 0 ]]; then
		exit 0
	fi

	if [[ ${ans} == '1' ]]; then
		DESC="Push buttons selected"
		USER_INTERFACE=1
		BUTTON_WIRING=1

	elif [[ ${ans} == '2' ]]; then
		DESC="Rotary encoders selected"
		USER_INTERFACE=2
		BUTTON_WIRING=2
		PULL_UP_DOWN=1

	elif [[ ${ans} == '3' ]]; then
		DESC="HDMI or touch screen only"
		USER_INTERFACE=3

	elif [[ ${ans} == '4' ]]; then
		DESC="IQAudio Cosmic Controller"
		USER_INTERFACE=4
		BUTTON_WIRING=3
		PULL_UP_DOWN=1

	elif [[ ${ans} == '5' ]]; then
		DESC="Pimoroni pHat BEAT with buttons"
		USER_INTERFACE=5
		BUTTON_WIRING=4
		PULL_UP_DOWN=1

	elif [[ ${ans} == '6' ]]; then
		DESC="Adafruit RGB plate with buttons"
		USER_INTERFACE=6
		I2C_REQUIRED=1
		I2C_ADDRESS="0x20"

	elif [[ ${ans} == '7' ]]; then
		DESC="PiFace CAD with buttons"
		USER_INTERFACE=7
		SPI_REQUIRED=1
		GPIO_PINS=1
	else
		DESC="User interface in ${CONFIG} unchanged"	
		echo ${DESC} | tee -a ${LOG}
	fi

	whiptail --title "${DESC}" --yesno "Is this correct?" 10 60
	selection=$?
done

# Check how push-buttons are wired
if [[ ${USER_INTERFACE} == "1" ]]; then
	ans=0
	selection=1 
	while [ $selection != 0 ]
	do
		ans=$(whiptail --title "How are the push buttons wired?" --menu "Choose your option" 15 75 9 \
		"1" "GPIO --> Button --> +3.3V - Original wiring scheme" \
		"2" "GPIO --> Button --> GND(0V) - Alternative wiring scheme" \
		"3" "Do not change configuration" 3>&1 1>&2 2>&3) 

		exitstatus=$?
		if [[ $exitstatus != 0 ]]; then
			exit 0
		fi

		if [[ ${ans} == '1' ]]; then
			DESC="Buttons wired to +3.3V (GPIO low to high)"
			PULL_UP_DOWN=0

		elif [[ ${ans} == '2' ]]; then
			DESC="Buttons wired to GND(0V) (GPIO high to low)"
			PULL_UP_DOWN=1

		else
			DESC="Wiring configuration in ${CONFIG} unchanged"	
			echo ${DESC} | tee -a ${LOG}
		fi

		whiptail --title "${DESC}" --yesno "Is this correct?" 10 60
		selection=$?
	done
	echo ${DESC} | tee -a ${LOG}
fi

# Select the wiring type (40 or 26 pin) if not already specified
if [[ ${GPIO_PINS} == "0" ]]; then
	ans=0
	selection=1 
	while [ $selection != 0 ]
	do
		ans=$(whiptail --title "Select wiring version" --menu "Choose your option" 15 75 9 \
		"1" "40 pin version wiring" \
		"2" "26 pin version wiring" \
		"3" "Do not change configuration" 3>&1 1>&2 2>&3) 

		exitstatus=$?
		if [[ $exitstatus != 0 ]]; then
			exit 0
		fi

		if [[ ${ans} == '1' ]]; then
			DESC="40 pin version selected"
			GPIO_PINS=1

		elif [[ ${ans} == '2' ]]; then
			DESC="26 pin version selected"
			GPIO_PINS=2

		else
			DESC="Wiring configuration in ${CONFIG} unchanged"	
			echo ${DESC} | tee -a ${LOG}
		fi

		whiptail --title "${DESC}" --yesno "Is this correct?" 10 60
		selection=$?
	done
	echo ${DESC} | tee -a ${LOG}
fi


# Configure the down switch (24 pin wiring)
if [[ ${GPIO_PINS} == "2" ]]; then
	ans=0
	selection=1 
	while [ $selection != 0 ]
	do
		ans=$(whiptail --title "How is the down switch wired?" --menu "Choose your option" 15 75 9 \
		"1" "GPIO 10 - Physical pin 19 (Select this if using a DAC)" \
		"2" "GPIO 18 - Physical pin 12 (Old wiring configuration)" \
		"3" "Do not change configuration" 3>&1 1>&2 2>&3) 

		exitstatus=$?
		if [[ $exitstatus != 0 ]]; then
			exit 0
		fi

		if [[ ${ans} == '1' ]]; then
			DESC="Down switch -> GPIO 10 - Physical pin 19"
			DOWN_SWITCH=10

		elif [[ ${ans} == '2' ]]; then
			DESC="Down switch -> GPIO 18 - Physical pin 12"
			DOWN_SWITCH=18

		else
			DESC="Down switch configuration in ${CONFIG} unchanged"	
			echo ${DESC} | tee -a ${LOG}
		fi

		whiptail --title "${DESC} " --yesno "Is this correct?" 10 60
		selection=$?
	done
fi 


# Select the display type
ans=0
selection=1 
while [ $selection != 0 ]
do
	ans=$(whiptail --title "Select display type" --menu "Choose your option" 15 75 9 \
	"1" "LCD wired directly to GPIO pins" \
	"2" "LCD with Arduino (PCF8574) backpack" \
	"3" "LCD with Adafruit (MCP23017) backpack" \
	"4" "Adafruit RGB LCD plate with 5 push buttons" \
	"5" "HDMI or touch screen display" \
	"6" "Olimex 128x64 pixel OLED display" \
	"7" "PiFace CAD display" \
	"8" "No display used" \
	"9" "Do not change display type" 3>&1 1>&2 2>&3) 

	exitstatus=$?
	if [[ $exitstatus != 0 ]]; then
		exit 0
	fi

	if [[ ${ans} == '1' ]]; then
		DISPLAY_TYPE="LCD"
		LCD_WIRING=1
		DESC="LCD wired directly to GPIO pins"

	elif [[ ${ans} == '2' ]]; then
		DISPLAY_TYPE="LCD_I2C_PCF8574"
		I2C_ADDRESS="0x27"
		I2C_REQUIRED=1
		DESC="LCD with Arduino (PCF8574) backpack"

	elif [[ ${ans} == '3' ]]; then
		DISPLAY_TYPE="LCD_I2C_ADAFRUIT"
		I2C_ADDRESS="0x20"
		I2C_REQUIRED=1
		DESC="LCD with Adafruit (MCP23017) backpack"

	elif [[ ${ans} == '4' ]]; then
		DISPLAY_TYPE="LCD_ADAFRUIT_RGB"
		I2C_ADDRESS="0x20"
		I2C_REQUIRED=1
		DESC="Adafruit RGB LCD plate with 5 push buttons" 

	elif [[ ${ans} == '5' ]]; then
		DISPLAY_TYPE="GRAPHICAL"
		DESC="HDMI or touch screen display"
		LINES=0
		WIDTH=0

	elif [[ ${ans} == '6' ]]; then
		DISPLAY_TYPE="OLED_128x64"
		I2C_ADDRESS="0x3C"
		I2C_REQUIRED=1
		DESC="Olimex 128x64 pixel OLED display"
		VOLUME_RANGE=10
		DATE_FORMAT="%H:%M %d%m"
		LINES=5
		WIDTH=20

	elif [[ ${ans} == '7' ]]; then
		DISPLAY_TYPE="PIFACE_CAD"
		DESC="PiFace CAD display"
		VOLUME_RANGE=10
		LINES=2
		WIDTH=16
		SPI_REQUIRED=1

	elif [[ ${ans} == '8' ]]; then
		DISPLAY_TYPE="NO_DISPLAY"
		LINES=0
		WIDTH=0
		DESC="No display used"

	else
		DESC="Display type unchanged"
		echo ${DESC} | tee -a ${LOG}

	fi

	whiptail --title "$DESC" --yesno "Is this correct?" 10 60
	selection=$?
done 

# Flip display upside down option
if [[ ${DISPLAY_TYPE} == "OLED_128x64" ]]; then
	ans=0
	selection=1 
	while [ $selection != 0 ]
	do
		ans=$(whiptail --title "Flip OLED display upside down " --menu "Choose your option" 15 75 9 \
		"1" "Flip OLED display upside down" \
		"2" "Do not flip OLED display upside down" 3>&1 1>&2 2>&3) 

		exitstatus=$?
		if [[ $exitstatus != 0 ]]; then
			exit 0
		fi

		if [[ ${ans} == '1' ]]; then
			DESC="OLED display flipped upside down"
			FLIP_OLED_DISPLAY=1	# Flip OLED display upside down
		else
			DESC="OLED display NOT flipped upside down"
		fi

		whiptail --title "${DESC}" --yesno "Is this correct?" 10 60
		selection=$?
	done
	echo ${DESC} | tee -a ${LOG}
fi

if [[ ${SPI_REQUIRED} != 0 ]]; then
        echo | tee -a ${LOG}
        echo "The PiFace CAD display requires the" | tee -a ${LOG}
        echo "SPI kernel module to be loaded at boot time." | tee -a ${LOG}
        echo "The program will call the raspi-config program" | tee -a ${LOG}
        echo "Select the following options on the next screens:" | tee -a ${LOG}
        echo "   5 Interfacing options" | tee -a ${LOG}
        echo "   P4 Enable/Disable automatic loading of SPI kernel module" | tee -a ${LOG}
        echo; echo -n "Press enter to continue: "
        read ans

	# Enable the SPI kernel interface 
	ans=0
	ans=$(whiptail --title "Enable SPI interface" --menu "Choose your option" 15 75 9 \
	"1" "Enable SPI Kernel Interface " \
	"2" "Do not change configuration" 3>&1 1>&2 2>&3) 

	exitstatus=$?
	if [[ $exitstatus != 0 ]]; then
		exit 0
	fi

	if [[ ${ans} == '1' ]]; then
		sudo raspi-config
		echo "The selected interface requires the PiFace CAD Python library" | tee -a ${LOG}
		echo "It is necessary to install the python-pifacecad library" | tee -a ${LOG}
		echo "After this program finishes carry out the following command:" | tee -a ${LOG}
		echo "   sudo apt-get install python-pifacecad" | tee -a ${LOG}
		echo "and reboot the system." | tee -a ${LOG}
		echo; echo -n "Press enter to continue: "
		read ans
	else
		echo "SPI configuration unchanged"	 | tee -a ${LOG}
	fi
fi

if [[ ${I2C_REQUIRED} != 0 ]]; then
	# Select the I2C address
	ans=0
	selection=1 
	while [ $selection != 0 ]
	do
		ans=$(whiptail --title "Select I2C hex address" --menu "Choose your option" 15 75 9 \
		"1" "Hex 0x20 (Adafruit devices)" \
		"2" "Hex 0x27 (PCF8574 devices)" \
		"3" "Hex 0x37 (PCF8574 devices alternative address)" \
		"4" "Hex 0x3C (Olimex OLED with Cosmic controller)" \
		"5" "Manually configure i2c_address in ${CONFIG}" \
		"6" "Do not change configuration" 3>&1 1>&2 2>&3) 

		exitstatus=$?
		if [[ $exitstatus != 0 ]]; then
			exit 0
		fi

		if [[ ${ans} == '1' ]]; then
			DESC="Hex 0x20 selected"
			I2C_ADDRESS="0x20"

		elif [[ ${ans} == '2' ]]; then
			DESC="Hex 0x27 selected"
			I2C_ADDRESS="0x27"

		elif [[ ${ans} == '3' ]]; then
			DESC="Hex 0x37 selected"
			I2C_ADDRESS="0x37"

		elif [[ ${ans} == '4' ]]; then
			DESC="Hex 0x3C selected"
			I2C_ADDRESS="0x3C"

		elif [[ ${ans} == '5' ]]; then
			DESC="Manually configure i2c_address in ${CONFIG} "
			echo ${DESC} | tee -a ${LOG}

		else
			echo "Wiring configuration in ${CONFIG} unchanged"	 | tee -a ${LOG}
		fi

		whiptail --title "$DESC" --yesno "Is this correct?" 10 60
		selection=$?
	done

	echo | tee -a ${LOG}
	echo "The selected display interface type requires the" | tee -a ${LOG}
	echo "I2C kernel libraries to be loaded at boot time." | tee -a ${LOG}
	echo "The program will call the raspi-config program" | tee -a ${LOG}
	echo "Select the following options on the next screens:" | tee -a ${LOG}
	echo "   5 Interfacing options" | tee -a ${LOG}
 	echo "   P5 Enable/Disable automatic loading of I2C kernel module" | tee -a ${LOG}
	echo; echo -n "Press enter to continue: "
	read ans

	# Enable the I2C libraries 
	ans=0
	ans=$(whiptail --title "Enable I2C interface" --menu "Choose your option" 15 75 9 \
	"1" "Enable I2C libraries " \
	"2" "Do not change configuration" 3>&1 1>&2 2>&3) 

	exitstatus=$?
	if [[ $exitstatus != 0 ]]; then
		exit 0
	fi

	if [[ ${ans} == '1' ]]; then
		sudo raspi-config

		echo "The selected interface requires the Python I2C libraries" | tee -a ${LOG}
		echo "It is necessary to install the python-smbus library" | tee -a ${LOG}
		echo "After this program finishes carry out the following command:" | tee -a ${LOG}
		echo "   sudo apt-get install python-smbus" | tee -a ${LOG}
		echo "and reboot the system." | tee -a ${LOG}
		echo; echo -n "Press enter to continue: "
		read ans

		# Update boot config
		echo "Enabling I2C interface in ${BOOTCONFIG}" | tee -a ${LOG}
		sudo sed -i -e "0,/^\#dtparam=i2c_arm/{s/\#dtparam=i2c_arm.*/dtparam=i2c_arm=yes/}" ${BOOTCONFIG}
	else
		echo "I2C configuration unchanged"	 | tee -a ${LOG}
	fi
fi

# Select the display type (Lines and Width)
if [[ ${DISPLAY_TYPE} =~ "LCD" ]]; then
	ans=0
	selection=1 
	while [ $selection != 0 ]
	do
		ans=$(whiptail --title "Select display type" --menu "Choose your option" 15 75 9 \
		"1" "Four line 20 character LCD" \
		"2" "Four line 16 character LCD" \
		"3" "Two line 16 character LCD/PiFace CAD" \
		"4" "Two line 8 character LCD" \
		"5" "Do not change display type" 3>&1 1>&2 2>&3) 

		exitstatus=$?
		if [[ $exitstatus != 0 ]]; then
			exit 0
		fi

		if [[ ${ans} == '1' ]]; then
			DESC="Four line 20 character LCD" 
			LINES=4;WIDTH=20

		elif [[ ${ans} == '2' ]]; then
			DESC="Four line 16 character LCD" 
			LINES=4;WIDTH=16

		elif [[ ${ans} == '3' ]]; then
			DESC="Two line 16 character LCD" 
			LINES=2;WIDTH=16

		elif [[ ${ans} == '4' ]]; then
			DESC="Two line 8 character LCD" 
			LINES=2;WIDTH=8

		else
			echo "Wiring configuration in ${CONFIG} unchanged"	 | tee -a ${LOG}
		fi

		whiptail --title "${DESC}" --yesno "Is this correct?" 10 60
		selection=$?
	done

#elif [[ ${DISPLAY_TYPE} != "NO_DISPLAY" &&  ${DISPLAY_TYPE} != "PIFACE_CAD" ]]; then
elif [[ ${DISPLAY_TYPE} == "GRAPHICAL" ]]; then
	# Configure graphical display
	ans=0
	selection=1 
	while [ $selection != 0 ]
	do
		ans=$(whiptail --title "Select graphical display type?" --menu "Choose your option" 15 75 9 \
		"1" "Raspberry Pi 7-inch touch-screen (800x480)" \
		"2" "Adafruit 3.5 inch TFT touch-screen (720x480)" \
		"3" "Small 2.8 inch TFT touch-screen (480x320)" \
		"4" "7-inch TFT touch-screen (1024x600)" \
		"5" "HDMI television or monitor (800x480)" \
		"6" "Do not change configuration" 3>&1 1>&2 2>&3) 

		exitstatus=$?
		if [[ $exitstatus != 0 ]]; then
			exit 0
		fi

		if [[ ${ans} == '1' ]]; then
			DESC="Raspberry Pi 7 inch touch-screen"
			SCREEN_SIZE="800x480"

		elif [[ ${ans} == '2' ]]; then
			DESC="Adafruit 3.5 inch TFT touch-screen"
			SCREEN_SIZE="720x480"

		elif [[ ${ans} == '3' ]]; then
			DESC="Small 3.5 inch TFT touch-screen"
			SCREEN_SIZE="480x320"

		elif [[ ${ans} == '4' ]]; then
			DESC="7-inch TFT touch-screen (1024x600)"
			SCREEN_SIZE="1024x600"

		elif [[ ${ans} == '4' ]]; then
			DESC="HDMI television or monitor"
			SCREEN_SIZE="800x480"

		else
			DESC="Graphical displayn type unchanged"	
			echo ${DESC} | tee -a ${LOG}
			GPROG=""
		fi

		whiptail --title "${DESC} " --yesno "Is this correct?" 10 60
		selection=$?
		
	done
	
	ans=0
	selection=1 
	while [ $selection != 0 ]
	do
		ans=$(whiptail --title "Which type of graphical display?" --menu "Choose your option" 15 75 9 \
		"1" "Full feature radio" \
		"2" "Vintage look-alike (Radio only)" \
		"3" "Do not change configuration" 3>&1 1>&2 2>&3) 

		exitstatus=$?
		if [[ $exitstatus != 0 ]]; then
			exit 0
		fi

		if [[ ${ans} == '1' ]]; then
			DESC="Full feature radio"
			GPROG="gradio"

		elif [[ ${ans} == '2' ]]; then
			DESC="Vintage look-alike (Radio only)"
			GPROG="vgradio"

		else
			DESC="Graphical display unchanged"	
			echo ${DESC} | tee -a ${LOG}
			GPROG=""
		fi

		whiptail --title "${DESC} " --yesno "Is this correct?" 10 60
		selection=$?
		
	done
	
	if [[ ${GPROG}  != "" ]];then
		PROGRAM="Graphical/touch-screen program ${GPROG} configured"
	else
		PROGRAM="Graphical/touch-screen program unchanged"
	fi

	# Set up boot option for graphical radio
	ans=0
	selection=1 
	while [ $selection != 0 ]
	do
		ans=$(whiptail --title "Boot option" --menu "Choose your option" 15 75 9 \
		"1" "Start radio at boot time" \
		"2" "Do not start at boot time" \
		"3" "Do not change configuration" 3>&1 1>&2 2>&3) 

		exitstatus=$?
		if [[ $exitstatus != 0 ]]; then
			exit 0
		fi

		if [[ ${ans} == '1' ]]; then
			DESC="Start radio at boot time" 
			LXSESSION="yes"

		elif [[ ${ans} == '2' ]]; then
			DESC="Do not start radio at boot time" 
			LXSESSION="no"

		else
			echo "Boot configuration unchanged"	 | tee -a ${LOG}
		fi

		whiptail --title "${DESC}" --yesno "Is this correct?" 10 60
		selection=$?
	done

	ans=0
	selection=1 
	while [ $selection != 0 ]
	do
		ans=$(whiptail --title "Full screen option" --menu "Choose your option" 15 75 9 \
		"1" "Start graphical radio full screen" \
		"2" "Start graphical radio in a desktop window" \
		"3" "Do not change configuration" 3>&1 1>&2 2>&3) 

		exitstatus=$?
		if [[ $exitstatus != 0 ]]; then
			exit 0
		fi

		if [[ ${ans} == '1' ]]; then
			DESC="Start graphical radio full screen"
			FULLSCREEN="yes"

		elif [[ ${ans} == '2' ]]; then
			DESC="Do not start radio at boot time" 
			FULLSCREEN="no"

		else
			echo "Desktop configuration unchanged"	 | tee -a ${LOG}
		fi

		whiptail --title "${DESC}" --yesno "Is this correct?" 10 60
		selection=$?
	done

	echo "Desktop program ${GPROG}.py configured" | tee -a ${LOG}
fi

# Configure desktop autostart if X-Windows installed
cmd="@sudo /usr/share/radio/${GPROG}.py"
AUTOSTART="/home/pi/.config/lxsession/LXDE-pi/autostart"
if [[ -f ${AUTOSTART} ]]; then
	if [[ ${LXSESSION} == "yes" ]]; then
		# Delete old entry if it exists
		sudo sed -i -e "/radio/d" ${AUTOSTART}
		echo "Configuring ${AUTOSTART} for automatic start" | tee -a ${LOG}
		sudo echo ${cmd} | sudo tee -a  ${AUTOSTART}
	else
		sudo sed -i -e "/radio/d" ${AUTOSTART}
	fi
fi

#######################################
# Commit changes to radio config file #
#######################################

# Save original configuration file
if [[ ! -f ${CONFIG}.org ]]; then
	sudo cp ${CONFIG} ${CONFIG}.org
	echo "Original ${CONFIG} copied to ${CONFIG}.org" | tee -a ${LOG}
fi

# Configure display width and lines
if [[ ${DISPLAY_TYPE} != "" ]]; then
	sudo sed -i -e "0,/^display_type/{s/display_type.*/display_type=${DISPLAY_TYPE}/}" ${CONFIG}
	sudo sed -i -e "0,/^display_lines/{s/display_lines.*/display_lines=${LINES}/}" ${CONFIG}
	sudo sed -i -e "0,/^display_width/{s/display_width.*/display_width=${WIDTH}/}" ${CONFIG}
	sudo sed -i -e "0,/^volume_range/{s/volume_range.*/volume_range=${VOLUME_RANGE}/}" ${CONFIG}
fi

if [[ $DATE_FORMAT != "" ]]; then
	sudo sed -i -e "0,/^dateformat/{s/dateformat.*/dateformat=${DATE_FORMAT}/}" ${CONFIG}
fi


# Set up graphical screen size
if [[ ${DISPLAY_TYPE} == "GRAPHICAL" ]]; then
	sudo sed -i -e "0,/^screen_size/{s/screen_size.*/screen_size=${SCREEN_SIZE}/}" ${CONFIG}
fi

# Configure user interface (Buttons or Rotary encoders)
if [[ ${USER_INTERFACE} == "1" ]]; then
	sudo sed -i -e "0,/^user_interface/{s/user_interface.*/user_interface=buttons/}" ${CONFIG}

elif [[ ${USER_INTERFACE} == "2" ]]; then
	sudo sed -i -e "0,/^user_interface/{s/user_interface.*/user_interface=rotary_encoder/}" ${CONFIG}

elif [[ ${USER_INTERFACE} == "3" ]]; then
	sudo sed -i -e "0,/^user_interface/{s/user_interface.*/user_interface=graphical/}" ${CONFIG}

elif [[ ${USER_INTERFACE} == "4" ]]; then
	sudo sed -i -e "0,/^user_interface/{s/user_interface.*/user_interface=cosmic_controller/}" ${CONFIG}

elif [[ ${USER_INTERFACE} == "5" ]]; then
	sudo sed -i -e "0,/^user_interface/{s/user_interface.*/user_interface=phatbeat/}" ${CONFIG}

elif [[ ${USER_INTERFACE} == "7" ]]; then
	sudo sed -i -e "0,/^user_interface/{s/user_interface.*/user_interface=pifacecad/}" ${CONFIG}
fi

# Configure user interface (Buttons or Rotary encoders)
if [[ ${I2C_ADDRESS} != "0x00" ]]; then
	sudo sed -i -e "0,/^i2c_address/{s/i2c_address.*/i2c_address=${I2C_ADDRESS}/}" ${CONFIG}
fi

# Configure wiring for directly connected LCD displays
if [[ ${DISPLAY_TYPE} == "LCD" ]]; then
	if [[ ${GPIO_PINS} == "1" ]]; then
		echo "LCD pinouts configured for 40 pin wiring" | tee -a ${LOG}
		sudo sed -i -e "0,/^lcd_select/{s/lcd_select.*/lcd_select=7/}" ${CONFIG}
		sudo sed -i -e "0,/^lcd_enable/{s/lcd_enable.*/lcd_enable=8/}" ${CONFIG}
		sudo sed -i -e "0,/^lcd_data4/{s/lcd_data4.*/lcd_data4=5/}" ${CONFIG}
		sudo sed -i -e "0,/^lcd_data5/{s/lcd_data5.*/lcd_data5=6/}" ${CONFIG}
		sudo sed -i -e "0,/^lcd_data6/{s/lcd_data6.*/lcd_data6=12/}" ${CONFIG}
		sudo sed -i -e "0,/^lcd_data7/{s/lcd_data7.*/lcd_data7=13/}" ${CONFIG}
	else
		echo "LCD pinouts configured for 26 pin wiring" | tee -a ${LOG}
		sudo sed -i -e "0,/^lcd_select/{s/lcd_select.*/lcd_select=7/}" ${CONFIG}
		sudo sed -i -e "0,/^lcd_enable/{s/lcd_enable.*/lcd_enable=8/}" ${CONFIG}
		sudo sed -i -e "0,/^lcd_data4/{s/lcd_data4.*/lcd_data4=27/}" ${CONFIG}
		sudo sed -i -e "0,/^lcd_data5/{s/lcd_data5.*/lcd_data5=22/}" ${CONFIG}
		sudo sed -i -e "0,/^lcd_data6/{s/lcd_data6.*/lcd_data6=23/}" ${CONFIG}
		sudo sed -i -e "0,/^lcd_data7/{s/lcd_data7.*/lcd_data7=24/}" ${CONFIG}
	fi

else
	# LCD not connected 
	echo "LCD pinouts disabled" | tee -a ${LOG}
	sudo sed -i -e "0,/^lcd_select/{s/lcd_select.*/lcd_select=0/}" ${CONFIG}
	sudo sed -i -e "0,/^lcd_enable/{s/lcd_enable.*/lcd_enable=0/}" ${CONFIG}
	sudo sed -i -e "0,/^lcd_data4/{s/lcd_data4.*/lcd_data4=0/}" ${CONFIG}
	sudo sed -i -e "0,/^lcd_data5/{s/lcd_data5.*/lcd_data5=0/}" ${CONFIG}
	sudo sed -i -e "0,/^lcd_data6/{s/lcd_data6.*/lcd_data6=0/}" ${CONFIG}
	sudo sed -i -e "0,/^lcd_data7/{s/lcd_data7.*/lcd_data7=0/}" ${CONFIG}
fi

# Configure buttons and rotary encoders
if [[ ${BUTTON_WIRING} == "1" || ${BUTTON_WIRING} == "2" ]]; then

	if [[ ${GPIO_PINS} == "1" ]]; then
		echo "Configuring 40 Pin wiring"  | tee -a ${LOG}
		sudo sed -i -e "0,/^menu_switch=/{s/menu_switch=.*/menu_switch=17/}" ${CONFIG}
		sudo sed -i -e "0,/^mute_switch/{s/mute_switch.*/mute_switch=4/}" ${CONFIG}
		sudo sed -i -e "0,/^up_switch/{s/up_switch.*/up_switch=24/}" ${CONFIG}
		sudo sed -i -e "0,/^down_switch/{s/down_switch.*/down_switch=23/}" ${CONFIG}
		sudo sed -i -e "0,/^left_switch/{s/left_switch.*/left_switch=14/}" ${CONFIG}
		sudo sed -i -e "0,/^right_switch/{s/right_switch.*/right_switch=15/}" ${CONFIG}
	else
		echo "Configuring 26 Pin wiring"  | tee -a ${LOG}
		sudo sed -i -e "0,/^menu_switch=/{s/menu_switch=.*/menu_switch=25/}" ${CONFIG}
		sudo sed -i -e "0,/^mute_switch/{s/mute_switch.*/mute_switch=4/}" ${CONFIG}
		sudo sed -i -e "0,/^up_switch/{s/up_switch.*/up_switch=17/}" ${CONFIG}
		sudo sed -i -e "0,/^down_switch/{s/down_switch.*/down_switch=${DOWN_SWITCH}/}" ${CONFIG}
		sudo sed -i -e "0,/^left_switch/{s/left_switch.*/left_switch=14/}" ${CONFIG}
		sudo sed -i -e "0,/^right_switch/{s/right_switch.*/right_switch=15/}" ${CONFIG}
	fi

# Configure the cosmic controller (40 pin only)
elif [[ ${BUTTON_WIRING} == "3" ]]; then
	echo "Configuring Cosmic Controller Pin wiring"  | tee -a ${LOG}
	# Switches
	sudo sed -i -e "0,/^menu_switch=/{s/menu_switch=.*/menu_switch=5/}" ${CONFIG}
	sudo sed -i -e "0,/^mute_switch/{s/mute_switch.*/mute_switch=27/}" ${CONFIG}
	sudo sed -i -e "0,/^up_switch/{s/up_switch.*/up_switch=6/}" ${CONFIG}
	sudo sed -i -e "0,/^down_switch/{s/down_switch.*/down_switch=4/}" ${CONFIG}
	sudo sed -i -e "0,/^left_switch/{s/left_switch.*/left_switch=23/}" ${CONFIG}
	sudo sed -i -e "0,/^right_switch/{s/right_switch.*/right_switch=24/}" ${CONFIG}

	# Configure status LEDs
	sudo sed -i -e "0,/^rgb_red/{s/rgb_red.*/rgb_red=14/}" ${CONFIG}
	sudo sed -i -e "0,/^rgb_green/{s/rgb_green.*/rgb_green=15/}" ${CONFIG}
	sudo sed -i -e "0,/^rgb_blue/{s/rgb_blue.*/rgb_blue=16/}" ${CONFIG}

# Configure the cosmic controller (40 pin only)
elif [[ ${BUTTON_WIRING} == "4" ]]; then
	echo "Configuring Pimoroni pHat BEAT"  | tee -a ${LOG}
	# Switches
	sudo sed -i -e "0,/^menu_switch=/{s/menu_switch=.*/menu_switch=12/}" ${CONFIG}
	sudo sed -i -e "0,/^mute_switch/{s/mute_switch.*/mute_switch=6/}" ${CONFIG}
	sudo sed -i -e "0,/^up_switch/{s/up_switch.*/up_switch=5/}" ${CONFIG}
	sudo sed -i -e "0,/^down_switch/{s/down_switch.*/down_switch=13/}" ${CONFIG}
	sudo sed -i -e "0,/^left_switch/{s/left_switch.*/left_switch=26/}" ${CONFIG}
	sudo sed -i -e "0,/^right_switch/{s/right_switch.*/right_switch=16/}" ${CONFIG}

# Disable switch GPIOs if using SPI or I2C interface
else 
	sudo sed -i -e "0,/^menu_switch=/{s/menu_switch=.*/menu_switch=0/}" ${CONFIG}
	sudo sed -i -e "0,/^mute_switch/{s/mute_switch.*/mute_switch=0/}" ${CONFIG}
	sudo sed -i -e "0,/^up_switch/{s/up_switch.*/up_switch=0/}" ${CONFIG}
	sudo sed -i -e "0,/^down_switch/{s/down_switch.*/down_switch=0/}" ${CONFIG}
	sudo sed -i -e "0,/^left_switch/{s/left_switch.*/left_switch=0/}" ${CONFIG}
	sudo sed -i -e "0,/^right_switch/{s/right_switch.*/right_switch=0/}" ${CONFIG}
fi

# Configure the pull up/down resistors
if [[ ${PULL_UP_DOWN} == "1" ]]; then
	sudo sed -i -e "0,/^pull_up_down/{s/pull_up_down.*/pull_up_down=up/}" ${CONFIG}

else
	sudo sed -i -e "0,/^pull_up_down/{s/pull_up_down.*/pull_up_down=down/}" ${CONFIG}
fi

# Flip OLED display
if [[ ${FLIP_OLED_DISPLAY} == "1" ]]; then
	sudo sed -i -e "0,/^flip_display_vertically/{s/flip_display_vertically.*/flip_display_vertically=yes/}" ${CONFIG}

else
	sudo sed -i -e "0,/^flip_display_vertically/{s/flip_display_vertically.*/flip_display_vertically=no/}" ${CONFIG}
fi

#####################
# Summarise changes #
#####################

echo | tee -a ${LOG}
echo "Changes written to ${CONFIG}" | tee -a ${LOG}
echo "-----------------------------------" | tee -a ${LOG}
if [[ ${USER_INTERFACE} != "0" ]]; then
	echo $(grep "^user_interface=" ${CONFIG} ) | tee -a ${LOG}
fi

if [[ $DISPLAY_TYPE != "" ]]; then
	echo $(grep "^display_type=" ${CONFIG} ) | tee -a ${LOG}
	echo $(grep "^display_lines=" ${CONFIG} ) | tee -a ${LOG}
	echo $(grep "^display_width=" ${CONFIG} ) | tee -a ${LOG}
	echo | tee -a ${LOG}
fi

if [[ ${DISPLAY_TYPE} == "GRAPHICAL" ]]; then
	echo $(grep "^screen_size=" ${CONFIG} ) | tee -a ${LOG}
	echo | tee -a ${LOG}
fi

# LCD wiring
wiring=$(grep "^lcd_" ${CONFIG} )
for item in ${wiring}
do
	echo ${item} | tee -a ${LOG}
done
echo | tee -a ${LOG}

# Button / Rotary encoder wiring
wiring=$(grep "^[a-z]*_switch=" ${CONFIG} )
for item in ${wiring}
do
	echo ${item} | tee -a ${LOG}
done
echo | tee -a ${LOG}

echo $(grep "^pull_up_down=" ${CONFIG} ) | tee -a ${LOG}
echo $(grep "^flip_display_vertically=" ${CONFIG} ) | tee -a ${LOG}

echo $(grep "^volume_range=" ${CONFIG} ) | tee -a ${LOG}
if [[ $DATE_FORMAT != "" ]]; then
	echo $(grep -m 1 "^dateformat=" ${CONFIG} ) | tee -a ${LOG}
fi

echo "-----------------------------------" | tee -a ${LOG}

# Update the System V init script
DAEMON="radiod.py"
sudo sed -i "s/^NAME=.*/NAME=${DAEMON}/g" ${INIT}

# Update systemd script
echo | tee -a ${LOG}
echo "Updating systemd script" | tee -a ${LOG}
sudo sed -i "s/^ExecStart=.*/ExecStart=${BINDIR}${DAEMON} nodaemon/g" ${SERVICE}
sudo sed -i "s/^ExecStop=.*/ExecStop=${BINDIR}${DAEMON} stop/g" ${SERVICE}

echo "Reloading systemd units" | tee -a ${LOG}
sudo systemctl daemon-reload

echo | tee -a ${LOG}
# Update system startup 
if [[ ${DISPLAY_TYPE} == "GRAPHICAL" ]]; then

	# Set up desktop radio execution icon
	sudo cp ${DIR}/Desktop/gradio.desktop /home/pi/Desktop/.
	sudo cp ${DIR}/Desktop/vgradio.desktop /home/pi/Desktop/.


	# Add [SCREEN] section to the configuration file
	grep "\[SCREEN\]" ${CONFIG} >/dev/null 2>&1
	if [[ $? != 0 ]]; then	# Don't seperate from above
		echo "Adding [SCREEN] section to ${CONFIG}" | tee -a ${LOG}
		sudo cat ${DIR}/gradio.conf | sudo tee -a ${CONFIG}
	fi
	sudo systemctl daemon-reload
	cmd="sudo systemctl disable radiod.service"
	echo ${cmd}; ${cmd}  >/dev/null 2>&1

	# Set fullscreen option (Graphical radio version only)
	if [[ ${FULLSCREEN} != "" ]]; then
		sudo sed -i -e "0,/^fullscreen/{s/fullscreen.*/fullscreen=${FULLSCREEN}/}" ${CONFIG}
		echo "fullscreen=${FULLSCREEN}" | tee -a ${LOG}
	fi

# Enable  radio daemon to start radiod
elif [[ ${DISPLAY_TYPE} =~ "LCD" ]]; then
	if [[ -x /bin/systemctl ]]; then
		sudo systemctl daemon-reload
		cmd="sudo systemctl enable radiod.service"
		echo ${cmd}; ${cmd} >/dev/null 2>&1
	else
		sudo update-rc.d radiod enable
	fi
fi

echo ${PROGRAM};echo | tee -a ${LOG}


# Configure audio device
ans=0
ans=$(whiptail --title "Configure audio interface?" --menu "Choose your option" 15 75 9 \
"1" "Run audio configuration program (configure_audio.sh)" \
"2" "Do not change configuration" 3>&1 1>&2 2>&3) 

if [[ ${ans} == '1' ]]; then
	sudo ${DIR}/configure_audio.sh ${FLAGS}
else
	echo "Audio configuration unchanged."	 | tee -a ${LOG}
fi

echo "Reboot Raspberry Pi to enable changes." | tee -a ${LOG}
echo "A log of these changes has been written to ${LOG}"
exit 0

# End of configuration script

