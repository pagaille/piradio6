#!/usr/bin/env python
#
# Raspberry Pi Internet Radio Configuration Class
# $Id: config_class.py,v 1.72 2018/12/04 07:59:51 bob Exp $
#
# Author : Bob Rathbone
# Site   : http://www.bobrathbone.com
#
# This class reads the /etc/radiod.conf file for configuration parameters
#
# License: GNU V3, See https://www.gnu.org/copyleft/gpl.html
#
# Disclaimer: Software is provided as is and absolutly no warranties are implied or given.
#	     The authors shall not be liable for any loss or damage however caused.
#

import os
import sys
import ConfigParser
from log_class import Log
from __init__ import *

# System files
ConfigFile = "/etc/radiod.conf"
Airplay = "/usr/local/bin/shairport-sync"

log = Log()
config = ConfigParser.ConfigParser()

class Configuration:
	# Input source
	RADIO = 0
	PLAYER = 1
	AIRPLAY = 2

	"""
	Station name source. LIST= from stationlist file 
	or STREAM from radio stream
	"""
	LIST = 0
        STREAM = 1

	# Display types
	NO_DISPLAY = 0		# No screen attached
	LCD = 1	   		# Directly connected LCD
	LCD_I2C_PCF8574 = 2	# LCD PCF8574 I2C backpack
	LCD_I2C_ADAFRUIT = 3	# Adafruit I2C LCD backpack
	LCD_ADAFRUIT_RGB = 4	# Adafruit RGB plate
	GRAPHICAL_DISPLAY = 5	# Graphical or touchscreen  display
	OLED_128x64 = 6		# OLED 128 by 64 pixels
	PIFACE_CAD = 7		# Piface CAD 

	display_type = LCD
	DisplayTypes = [ 'NO_DISPLAY','LCD', 'LCD_I2C_PCF8574', 
			 'LCD_I2C_ADAFRUIT', 'LCD_ADAFRUIT_RGB', 
			 'GRAPHICAL_DISPLAY', 'OLED_128x64', 'PIFACE_CAD']

	# User interface ROTARY or BUTTONS
	ROTARY_ENCODER = 0
	BUTTONS = 1
	GRAPHICAL=2
	COSMIC_CONTROLLER = 3	# IQAudio cosmic controller
	PIFACE_BUTTONS = 4	# PiFace CAD buttons 
	ADAFRUIT_RGB = 5	# Adafruit RGB I2C 5 button interface
	user_interface = ROTARY_ENCODER

	UserInterfaces = [ 'ROTARY_ENCODER','BUTTONS', 'GRAPHICAL', 
			 'COSMIC_CONTROLLER', 'PIFACE_BUTTONS', 'ADAFRUIT_RGB', 
			 ] 

	# Rotary class selection
	STANDARD = 0	# Select rotary_class.py
	ALTERNATIVE = 1	# Select rotary_class_alternate.py

	# Configuration parameters
	mpdport = 6600  # MPD port number
	dateFormat = "%H:%M %d/%m/%Y"   # Date format
	volume_range = 100 		# Volume range 10 to 100
	volume_increment = 1 		# Volume increment 1 to 10
	display_playlist_number = False # Two line displays only, display station(n)
	source = RADIO  		# Source RADIO or Player
	load_last = False 		# Auto load media if no Internet on startup
	rotary_class = STANDARD		# Rotary class STANDARD or ALTERNATIVE 
	display_width = 0		# Line width of display width 0 = use program default
	display_lines = 2		# Number of display lines
	airplay = False		# Use airplay
	mixerPreset = 0		# Mixer preset volume (0 disable setting as MPD controls it)
	display_blocks = False	# Display volume in blocks
	fullscreen = True	# Graphics screen fullscreen yes no 
	startup_playlist = ""	# Startup playlist if defined
	screen_saver = 0	# Screen saver time n minutes, 0 = No screen save
	flip_display_vertically = False	# Flip OLED display vertically
	stationNamesSource = LIST # Station names from playlist names or STREAM

	# Remote control parameters 
	remote_led = 0  # Remote Control activity LED 0 = No LED	
	remote_control_host = 'localhost' 	# Remote control to radio communication port
	remote_listen_host = 'localhost' 	# Remote control to radio communication port
	remote_control_port = 5100 	  	# Remote control to radio communication port

	i2c_address = 0x00	# Use defaults or use setting in radiod.conf 
	i2c_bus = 1		# The I2C bus is normally 1
	speech = False 	    	# Speech on for visually impaired or blind persons
	isVerbose = False     	# Extra speech verbosity
	speak_info = False	# If speach enable also speak info (IP address and hostname)
	speech_volume = 80  	# Percentage speech volume 

	# Shoutcast ID
	shoutcast_key = "anCLSEDQODrElkxl"

	# Graphics screen default parameters [SCREEN] section
	full_screen = True	# Display graphics fulll screen
	window_title = "Bob Rathbone Internet Radio %V - %H"	# Window title
	window_color = 'blue'	# Graphics screen background colour
	labels_color = 'white'	# Graphics screen labels colour
	display_window_color = 'navy'		# Display window background colour
	display_window_labels_color = 'white'	# Display window labels colour
	display_mouse = False	# Hide mouse
	switch_programs = False	# Allow switch between gradio and vgradio
	slider_color = 'red'	# Search window slider default colour 
	banner_color = 'black'	# Time banner text colour
	wallpaper = ''		# Background wallpaper
	graphicDateFormat="%H:%M:%S %A %e %B %Y"	# Format for graphic screen

	# Specific to the vintage graphic radio
	scale_labels_color = 'white'	# Vintage screen labels colour
	stations_per_page = 50 		# maximum stations per page
	display_date = True		# Display time and date
	display_title = True		# Display title play (at bottom of screen)
	splash_screen = 'bitmaps/raspberry-pi-logo.bmp'	# Splash screen (OLED)
	screen_size = (800,480)		# Screen size 800x480 (7 inch) or 720x480 (3.5 inch)

	shutdown = True		# Shutdown when exiting radio
	
	# Colours for Adafruit LCD
	color = { 'OFF': 0x0, 'RED' : 0x1, 'GREEN' : 0x2, 'YELLOW' : 0x3,
		  'BLUE' : 0x4, 'VIOLET' : 0x5, 'TEAL' : 0x6, 'WHITE' : 0x7 }

	colorName = { 0: 'Off', 1 : 'Red', 2 : 'Green', 3 : 'Yellow',
		    4 : 'Blue', 5 : 'Violet', 6 : 'Teal', 7 : 'White' }

	colors = { 'bg_color' : 0x0,
		   'mute_color' : 0x0,
		   'shutdown_color' : 0x0,
		   'error_color' : 0x0,
		   'search_color' : 0x0,
		   'source_color' : 0x0,
		   'info_color' : 0x0,
		   'menu_color' : 0x0,
		   'sleep_color': 0x0 }

	# List of loaded options for display
	configOptions = {}

	#  GPIOs for switches and rotary encoder configuration (40 pin wiring)
	switches = { "menu_switch": 17,
		     "mute_switch": 4,
		     "left_switch": 14,
		     "right_switch": 15,
		     "up_switch": 24,
		     "down_switch": 23,
		   }

	# Pull up/down resistors (For button class only)
	pull_up_down = DOWN	# Default

	# Values for the rotary switch on vintage radio (Not rotary encoders)
	# Zero values disable usage 
	menu_switches = {"menu_switch_value_1": 0,	# Normally 24
			 "menu_switch_value_2": 0,	# Normally 8
			 "menu_switch_value_4": 0,	# Normally 7
			}
	
	# RGB LED definitions for vintage radio
	# Zero values disable usage 
	rgb_leds = { "rgb_green": 0,	# Normally 27
		     "rgb_blue": 0,	# Normally 22
		     "rgb_red": 0,	# Normally 23
		   }

	#  GPIOs for LCD connections
	lcdconnects = { 
		     "lcd_enable": 8,
		     "lcd_select": 7,
		     "lcd_data4": 27,
		     "lcd_data5": 22,
		     "lcd_data6": 23,
		     "lcd_data7": 24,
		   }

	# Initialisation routine
	def __init__(self):
		log.init('radio')
		if not os.path.isfile(ConfigFile) or os.path.getsize(ConfigFile) == 0:
			log.message("Missing configuration file " + ConfigFile, log.ERROR)
		else:
			self.getConfig()

		return

	# Get configuration options from /etc/radiod.conf
	def getConfig(self):
		section = 'RADIOD'

		# Get options
		config.read(ConfigFile)
		try:
			options =  config.options(section)
			for option in options:
				option = option.lower()
				parameter = config.get(section,option)
				
				self.configOptions[option] = parameter

				if option == 'loglevel':
					next

				elif option == 'volume_range':
					range = 100
					try:
						range = int(parameter)
						if range < 10:
							range = 10
						if range > 100:
							range = 100
						self.volume_range = range
						self.volume_increment = int(100/range)
					except:
						self.invalidParameter(ConfigFile,option,parameter)

				elif option == 'user_interface':
					if parameter == 'buttons':
						self.user_interface =  self.BUTTONS
					elif parameter == 'rotary_encoder':
						self.user_interface =  self.ROTARY_ENCODER
					elif parameter == 'graphical':
						self.user_interface =  self.GRAPHICAL
					elif parameter == 'cosmic_controller':
						self.user_interface =  self.COSMIC_CONTROLLER
					elif parameter == 'phatbeat':
						self.user_interface =  self.BUTTONS
					elif parameter == 'pifacecad':
						self.user_interface =  self.PIFACE_BUTTONS

				elif option == 'remote_led':
					try:
						self.remote_led = int(parameter)
					except:
						self.invalidParameter(ConfigFile,option,parameter)

				elif option == 'remote_control_host':
					self.remote_control_host = parameter

				elif option == 'remote_control_port':
					try:
						self.remote_control_port = int(parameter)
					except:
						self.invalidParameter(ConfigFile,option,parameter)

				elif option == 'remote_listen_host':
					self.remote_listen_host = parameter

				elif option == 'mpdport':
					try:
						self.mpdport = int(parameter)
					except:
						self.invalidParameter(ConfigFile,option,parameter)

				elif option == 'dateformat':
					self.dateFormat = parameter

				elif option == 'display_playlist_number':
					if parameter == 'yes':
						self.display_playlist_number = True

				elif option == 'station_names':
					if parameter == 'stream':
						self.stationNamesSource =  self.STREAM
					else:
						self.stationNamesSource =  self.LIST

				elif option == 'flip_display_vertically':
					if parameter == 'yes':
						self.flip_display_vertically = True

				elif option == 'splash':
					self.splash_screen = parameter

				elif option == 'startup':
					if parameter == 'RADIO': 
						self.source =  self.RADIO
					elif parameter == 'MEDIA':
						self.source =  self.PLAYER
					elif parameter == 'AIRPLAY':
						self.source =  self.AIRPLAY
					elif parameter == 'LAST': 
						self.load_last = True
					elif len(parameter) > 0:
						self.startup_playlist = parameter

				elif option == 'i2c_address':
					try:
						value = int(parameter,16)
						if parameter  > 0x00:
							self.i2c_address =  value
					except:
						self.invalidParameter(ConfigFile,option,parameter)

				elif option == 'i2c_bus':
					try:
						value = int(parameter)
						if parameter  > 0 or parameter <= 1:
							self.i2c_bus =  value
						else:
							self.invalidParameter(ConfigFile,option,parameter)

					except:
						self.invalidParameter(ConfigFile,option,parameter)

				elif 'color' in option:
					try:
						self.colors[option] = self.color[parameter]
					except:
						self.invalidParameter(ConfigFile,option,parameter)

				elif option == 'speech':
					if parameter == 'yes':
						self.speech = True
					else:
						self.speech = False

				elif option == 'verbose':
					if parameter == 'yes':
						self.isVerbose = True
					else:
						self.isVerbose = False

				elif option == 'speak_info':
					if parameter == 'yes':
						self.speak_info = True
					else:
						self.speak_info = False

				elif option == 'volume_display':
					if parameter == 'blocks':
						self.display_blocks = True

				elif option == 'speech_volume':
					try:
						self.speech_volume = int(parameter)
					except:
						self.invalidParameter(ConfigFile,option,parameter)

				elif option == 'pull_up_down':
					if parameter == 'up':
						self.pull_up_down = UP
					else:
						self.pull_up_down = DOWN

				elif '_switch' in option and not 'menu_switch_value'in option:
					try:
						self.switches[option] = int(parameter)
					except:
						self.invalidParameter(ConfigFile,option,parameter)

				elif 'display_width' in option:
					try:
						self.display_width = int(parameter)
					except:
						self.invalidParameter(ConfigFile,option,parameter)

				elif 'display_lines' in option:
					try:
						self.display_lines = int(parameter)
					except:
						self.invalidParameter(ConfigFile,option,parameter)

				elif 'lcd_' in option:
					try:
						lcdconnect = int(parameter)
						self.lcdconnects[option] = lcdconnect
					except:
						self.invalidParameter(ConfigFile,option,parameter)

				elif 'rgb' in option:
					try:
						led = int(parameter)
						self.rgb_leds[option] = led
					except:
						msg = "Invalid RGB LED connect parameter " +  option
						log.message(msg,log.ERROR)

				elif 'menu_switch_value_' in option:
					try:
						menuswitch = int(parameter)
						self.menu_switches[option] = menuswitch
					except:
						self.invalidParameter(ConfigFile,option,parameter)

				elif 'display_type' in option:
					self.display_type = self.LCD 	# Default

					if parameter == 'LCD':
						self.display_type = self.LCD

					elif parameter == 'LCD_I2C_PCF8574':
						self.display_type = self.LCD_I2C_PCF8574

					elif parameter == 'LCD_I2C_ADAFRUIT':
						self.display_type = self.LCD_I2C_ADAFRUIT

					elif parameter == 'LCD_ADAFRUIT_RGB':
						self.display_type = self.LCD_ADAFRUIT_RGB

					elif parameter == 'NO_DISPLAY':
						self.display_type = self.NO_DISPLAY

					elif parameter == 'GRAPHICAL':
						self.display_type = self.GRAPHICAL_DISPLAY

					elif parameter == 'OLED_128x64':
						self.display_type = self.OLED_128x64

					elif parameter == 'PIFACE_CAD':
						self.display_type = self.PIFACE_CAD

					else:
						self.invalidParameter(ConfigFile,option,parameter)

				elif option == 'rotary_class':
					if parameter == 'standard':
						self.rotary_class = self.STANDARD
					else:
						self.rotary_class = self.ALTERNATIVE

				elif option == 'exit_action':
					if parameter == 'stop_radio':
						self.shutdown = False
					else:
						self.shutdown = True

				elif option == 'shoutcast_key':
					self.shoutcast_key = parameter

				else:
					msg = "Invalid option " + option + ' in section ' \
						+ section + ' in ' + ConfigFile
					log.message(msg,log.ERROR)

		except ConfigParser.NoSectionError:
			msg = ConfigParser.NoSectionError(section),'in',ConfigFile
			log.message(msg,log.ERROR)

		# Read Airplay parameters
		section = 'AIRPLAY'

		# Get options
		config.read(ConfigFile)
		try:
			options =  config.options(section)
			for option in options:
				option = option.lower()
				parameter = config.get(section,option)
				
				self.configOptions[option] = parameter

				if option == 'airplay':
					if parameter == 'yes' and os.path.isfile(Airplay):
						self.airplay = True

				# Name has been changed from mixer_volume to mixer_preset in v6.7
				elif option == 'mixer_volume' or option == 'mixer_preset':
					volume = 100
					try:
						volume = int(parameter)
						if volume < 0:
							volume = 0
						if volume > 100:
							volume = 100
						self.mixerPreset = volume
					except:
						self.invalidParameter(ConfigFile,option,parameter)

				elif option == 'mixer_volume_id':
					next	# No longer used 

				else:
					msg = "Invalid option " + option + ' in section ' \
						+ section + ' in ' + ConfigFile
					log.message(msg,log.ERROR)


		except ConfigParser.NoSectionError:
			msg = ConfigParser.NoSectionError(section),'in',ConfigFile
			log.message(msg,log.WARNING)

		section = 'SCREEN'
		# Get options
		config.read(ConfigFile)
		try:
			options =  config.options(section)
			for option in options:
				option = option.lower()
				parameter = config.get(section,option)
				
				self.configOptions[option] = parameter

				if option == 'screen_size':
					sW,sH = parameter.split('x')	
					w = int(sW)
					h = int(sH)
					self.screen_size = (w,h)
			
				if option == 'fullscreen':
					if parameter == 'yes':
						self.full_screen = True
					elif parameter == 'no':
						self.full_screen = False
				
				elif option == 'window_color':
					self.window_color = parameter
					
				elif option == 'window_title':
					self.window_title = parameter
					
				elif option == 'banner_color':
					self.banner_color = parameter
					
				elif option == 'labels_color':
					self.labels_color = parameter
					
				elif option == 'scale_labels_color':
					self.scale_labels_color = parameter
					
				elif option == 'display_window_color':
					self.display_window_color = parameter
					
				elif option == 'display_window_labels_color':
					self.display_window_labels_color = parameter
					
				elif option == 'slider_color':
					self.slider_color = parameter

				elif option == 'stations_per_page':
					self.stations_per_page = int(parameter)

				elif option == 'screen_saver':
					self.screen_saver = int(parameter)

				elif option == 'wallpaper':
					if os.path.exists(parameter):
						self.wallpaper = parameter

				elif option == 'dateformat':
					self.graphicDateFormat = parameter

				elif option == 'display_mouse':
					if parameter == 'yes':
						self.display_mouse = True
					else:
						self.display_mouse = False
					
				elif option == 'switch_programs':
					if parameter == 'yes':
						self.switch_programs = True
					else:
						self.switch_programs = False
					
				elif option == 'display_date':
					if parameter == 'yes':
						self.display_date = True
					else:
						self.display_date = False
					
				elif option == 'display_title':
					if parameter == 'yes':
						self.display_title = True
					else:
						self.display_title = False

		except ConfigParser.NoSectionError:
			msg = ConfigParser.NoSectionError(section),'in',ConfigFile
			log.message(msg,log.WARNING)
		return


	# Invalid parametrs message
	def invalidParameter(self, ConfigFile, option, parameter):
		msg = "Invalid parameter " + parameter + ' in option ' \
			+ option + ' in ' + ConfigFile
		log.message(msg,log.ERROR)
	
	# Get routines

	# Get I2C backpack address
	def getI2Caddress(self):
		return self.i2c_address

	# Get I2C bus number
	def getI2Cbus(self):
		return self.i2c_bus

	# Get the volume range
	def getVolumeRange(self):
		return self.volume_range

	# Get the volume increment
	def getVolumeIncrement(self):
		return self.volume_increment

	# Get the volume display
	def displayVolumeBlocks(self):
		return self.display_blocks

	# Get the remote control activity LED number
	def getRemoteLed(self):
		return self.remote_led

	# Get the remote Host default localhost
	def getRemoteUdpHost(self):
		return self.remote_control_host

	# Get the UDP server listener IP Host default localhost
	# or 0.0.0.0 for all interfaces
	def getRemoteListenHost(self):
		return self.remote_listen_host

	# Get the remote Port  default 5100
	def getRemoteUdpPort(self):
		return self.remote_control_port

	# Get the mpdport
	def getMpdPort(self):
		return self.mpdport

	# Get the date format
	def getDateFormat(self):
		return self.dateFormat

	# Get the date format for graphic screen
	def getGraphicDateFormat(self):
		return self.graphicDateFormat

	# Get display playlist number (Two line displays only)
	def getDisplayPlaylistNumber(self):
		return self.display_playlist_number

	# Get the startup source 0=RADIO or 1=MEDIA
	def getSource(self):
		return self.source

	# Get load last playlist option
	def loadLast(self):
		return self.load_last

	# Get the startup source name RADIO MEDIA
	def getSourceName(self):
		source_name = "MEDIA"
		if self.getSource() < 1:
			source_name = "RADIO"
		return source_name

	# Get the remote Port  default 5100
	def getRemoteUdpPort(self):
		return self.remote_control_port

	# Get the mpdport
	def getMpdPort(self):
		return self.mpdport

	# Get the date format
	def getDateFormat(self):
		return self.dateFormat

	# Get display playlist number (Two line displays only)
	def getDisplayPlaylistNumber(self):
		return self.display_playlist_number

	# Get the startup source 0=RADIO or 1=MEDIA
	def getSource(self):
		return self.source

	# Get the startup source name RADIO MEDIA
	def getSourceName(self):
		source_name = "MEDIA"
		if self.getSource() < 1:
			source_name = "RADIO"
		return source_name

	# Get the background color (Integer)
	def getBackColor(self,sColor):
		color = 0x0
		try: 
			color = self.colors[sColor]
		except:
			log.message("Invalid option " + sColor, log.ERROR)
		return color

	# Get the background colour string name
	def getBackColorName(self,iColor):
		sColor = 'None' 
		try: 
			sColor = self.colorName[iColor]
		except:
			log.message("Invalid option " + int(iColor), log.ERROR)
		return sColor

	# Get speech
	def hasSpeech(self):
		return self.speech	

	# Get verbose
	def verbose(self):
		return self.isVerbose	

	# Get verbose
	def speakInfo(self):
		return self.speak_info	

	# Get speech volume % of normal volume level
	def getSpeechVolumeAdjust(self):
		return self.speech_volume

	# Display parameters
	def display(self):
		for option in sorted(self.configOptions):
			param = self.configOptions[option]
			if option != 'None':
				log.message(option + " = " + param, log.DEBUG)
		return

	# Return the ID of the rotary class to be used STANDARD or ALTERNATIVE
	def getRotaryClass(self):
		return self.rotary_class

	# Returns the switch GPIO configuration by label
	def getSwitchGpio(self,label):
		switch = -1
		try:
			switch = self.switches[label]
		except:
			msg = "Invalid switch label " + label
			log.message(msg, log.ERROR)
		return switch

	# Returns the LCD GPIO configuration by label
	def getLcdGpio(self,label):
		lcdconnect = -1
		try:
			lcdconnect = self.lcdconnects[label]
		except:
			msg = "Invalid LCD connection label " + label
			log.message(msg, log.ERROR)
		return lcdconnect

	# Get the RGB Led configuration by label (Retro radio only)
	def getRgbLed(self,label):
		led = -1
		try:
			led = self.rgb_leds[label]
		except:
			msg = "Invalid RGB configuration label " + label
			log.message(msg, log.ERROR)
		return led

	# Get the RGB Led configuration by label (Retro radio only)
	def getMenuSwitch(self,label):
		menuswitch = -1
		try:
			menuswitch = self.menu_switches[label]
		except:
			msg = "Invalid menu switch configuration label " + label
			log.message(msg, log.ERROR)
		return menuswitch

	# User interface (Buttons or Rotary encoders or uther)
	def getUserInterface(self):
		return self.user_interface

	# User interface (Buttons or Rotary encoders)
	def getUserInterfaceName(self):
		return self.UserInterfaces[self.user_interface]

	# Get Display type
	def getDisplayType(self):
		return self.display_type

	# Get Display name
	def getDisplayName(self):
		return self.DisplayTypes[self.display_type]

	# Get LCD width
	def getWidth(self):
		return self.display_width

	# Get Display lines
	def getLines(self):
		return self.display_lines

	# Get airplay option
	def getAirplay(self):
		return self.airplay

	# Get mixer volume preset
	def getMixerPreset(self):
		return self.mixerPreset

	# Get startup playlist
	def getStartupPlaylist(self):
		return self.startup_playlist

	# Shutdown option
	def doShutdown(self):
		return self.shutdown

	# Pull Up/Down resistors (Button interface only)
	def getPullUpDown(self):
		return self.pull_up_down

	# SCREEN section
	# Fullscreen option for graphical screen
	def getSize(self):
		return self.screen_size

	def fullScreen(self):
		return self.full_screen

	# Get graphics window title
	def getWindowTitle(self):
		return self.window_title

	# Get graphics window colour
	def getWindowColor(self):
		return self.window_color

	# Get time banner text colour
	def getBannerColor(self):
		return self.banner_color

	# Get graphics labels colour
	def getLabelsColor(self):
		return self.labels_color

	# Get graphics labels colour
	def getScaleLabelsColor(self):
		return self.scale_labels_color

	# Get display window colour
	def getDisplayWindowColor(self):
		return self.display_window_color

	# Get display window labels colour
	def getDisplayLabelsColor(self):
		return self.display_window_labels_color

	# Get slider colour
	def getSliderColor(self):
		return self.slider_color

	# Get maximum stations displayed per page (vintage graphic radio)
	def getMaximumStations(self):
		if self.stations_per_page > 50:
			self.stations_per_page = 50
		return self.stations_per_page

	# Get window wallpaper
	def getWallPaper(self):
		return self.wallpaper

	# Mouse hidden 
	def displayMouse(self):
		return self.display_mouse

	# Allow program switch
	def switchPrograms(self):
		return self.switch_programs

	# Display date and time yes/no
	def displayDate(self):
		return self.display_date

	# Display date and time yes/no
	def displayTitle(self):
		return self.display_title

	# Screensaver time
	def screenSaverTime(self):
		return self.screen_saver

	# Shoutcast key
	def getShoutcastKey(self):
		return self.shoutcast_key

	# Oled flip display setting
	def flipVertical(self):
		return self.flip_display_vertically

	# Oled flip display setting
	def getSplash(self):
		return self.splash_screen

	# Station names from playlist names or from the stream 
	def getStationNamesSource(self):
		return self.stationNamesSource

# End Configuration of class

# Test Configuration class
if __name__ == '__main__':

	config = Configuration()
	print "User interface:", config.getUserInterface(), config.getUserInterfaceName()
	print "Configuration file:", ConfigFile
	print "Volume range:", config.getVolumeRange()
	print "Volume increment:", config.getVolumeIncrement()
	print "Mpd port:", config.getMpdPort()
	print "Remote LED:", config.getRemoteLed()
	print "Remote LED port:", config.getRemoteUdpPort()
	print "Date format:", config.getDateFormat()
	print "Display playlist number:", config.getDisplayPlaylistNumber()
	print "Source:", config.getSource(), config.getSourceName()
	print "Load last playlist", config.loadLast()
	print "Background colour number:", config.getBackColor('bg_color')
	print "Background colour:", config.getBackColorName(config.getBackColor('bg_color'))
	print "Speech:", config.hasSpeech()
	print "Speech volume adjustment:", str(config.getSpeechVolumeAdjust()) + '%'
	print "Verbose:", config.verbose()
	print "Speak info:", config.speakInfo()

	print "pull_up_down:", config.getPullUpDown()
	for switch in config.switches:
		print switch, config.getSwitchGpio(switch)
	
	for lcdconnect in sorted(config.lcdconnects):
		print lcdconnect, config.getLcdGpio(lcdconnect)
	
	for led in config.rgb_leds:
		print led, config.getRgbLed(led)
	
	for menuswitch in config.menu_switches:
		print menuswitch, config.getMenuSwitch(menuswitch)
	
	rclass = ['Standard', 'Alternative']
	rotary_class = config.getRotaryClass()
	print "Rotary class:", rotary_class, rclass[rotary_class]
	print "Display type:", config.getDisplayType(), config.getDisplayName()
	print "Display lines:", config.getLines()
	print "Display width:", config.getWidth()
	print "Airplay:", config.getAirplay()
	print "Mixer Volume Preset:", config.getMixerPreset()

	# I2C parameters
	print "I2C bus", config.getI2Cbus()
	print "I2C address:", hex(config.getI2Caddress())
	
	# Shoucast
	print "Shoutcast key:", config.getShoutcastKey()
	
	# OLED
	print "Flip screen vertical:",config.flipVertical()
	print "Splash screen:",config.getSplash()

# End of __main__

