#!/bin/sh

# This script will
# download volt hud, voltron from github, 
# install volt hud,
# build chat menu from sample file (by default), and install it
#
# Require: wget, unzip, tclsh

# Variables:
# home trem base dir, maybe tremfusion u use?
HOME_TREM_DIR=~/.tremulous/base

# config file, default is downloaded from git sample
# if you have own, replace below 
VOLTRON_CONFIG_FILE="voltron/volt.config.tcl.sample"

# change this if you have tclsh8.4 for example
TCLSH="tclsh8.5"


mkdir $HOME_TREM_DIR

echo "Work dir: ./work-volt"
mkdir work-volt
cd work-volt

echo "===>  Download Volt_hud2.0_FINAL.zip"
sleep 1
wget -c http://networkofdoom.net/~bishop3space/Tremulous/Projects/Hud/Volt_hud/Release/Volt_hud2.0_FINAL.zip

echo "===>  Download voltron"
sleep 1
mkdir voltron &>/dev/null
rm voltron/voltron.tcl
wget -nc -P ./voltron http://github.com/osv/voltron/raw/master/voltron.tcl
if [ "$?" -ne "0" ]; then
  echo "Cannot download voltron.tcl."
  exit 1
fi

rm voltron/volt.config.tcl.sample
wget -nc -P ./voltron http://github.com/osv/voltron/raw/master/volt.config.tcl.sample
if [ "$?" -ne "0" ]; then
  echo "Cannot download voltron sample config file"
  exit 1
fi

rm -rf Volt_hud2.0_FINAL/*

echo "===>  Extract Volt_hud2.0_FINAL.zip"
sleep 1
unzip Volt_hud2.0_FINAL.zip  > /dev/null
if [ "$?" -ne "0" ]; then
  echo "Cannot extract Volt hud."
  exit 1
fi

echo "===>  Installing for Volt hud"
sleep 1
cp -rv Volt_hud2.0_FINAL/* $HOME_TREM_DIR/

# Create wrapper for config file
echo "
# load config
source $VOLTRON_CONFIG_FILE
set chatmenu_teama chatmenu_alien.cfg
set chatmenu_teamb chatmenu_human.cfg
set chatmenu_spect chatmenu_spec.cfg
set binds_install  chatmenu_install.cfg
set binds_teama_install chatmenu_alien_install.cfg
set binds_teamb_install chatmenu_human_install.cfg
set binds_spect_install chatmenu_spect_install.cfg
" > volt.conf.wrap.tcl

echo "===>  Create chat menu"
sleep 1
$TCLSH voltron/voltron.tcl volt.conf.wrap.tcl
if [ "$?" -ne "0" ]; then
  echo "Cannot create chat menu."
  exit 1
fi

echo "===>  Install created chat menu"
sleep 1
cp -v chatmenu_alien.cfg $HOME_TREM_DIR/ui/hud/common/
cp -v chatmenu_human.cfg $HOME_TREM_DIR/ui/hud/common/
cp -v chatmenu_spec.cfg  $HOME_TREM_DIR/ui/hud/common/
cp -v chatmenu_install.cfg $HOME_TREM_DIR/ui/hud/common/
cp -v chatmenu_alien_install.cfg $HOME_TREM_DIR/ui/hud/common/
cp -v chatmenu_human_install.cfg $HOME_TREM_DIR/ui/hud/common/
cp -v chatmenu_spect_install.cfg $HOME_TREM_DIR/ui/hud/common/

echo "
*****************************************************
Now run tremulous, open console and type
  /exec ui/install.cfg

To join team use chat menu:
  0 1 Alien
  0 2 Human
  0 3 Spect
*****************************************************"
rm -rf Volt_hud2.0_FINAL
cd ..
