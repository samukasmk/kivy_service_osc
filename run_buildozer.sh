#!/bin/bash
#
# script: deploy_kivy_app_with_kivy_launcher.sh
#
# by: Samuel Maciel Sampaio [20140717]
#
# contact: samukasmk@gmail.com
#
# goal:
#   Develop kivy apps for android and quickly test directly in your
#   android devices with a simple and dynamically way, without to
#   create un apk package (that takes a lot lot time!)
#
#   How can i do this ? Transfering the files of your kivy project
#   directly to sdcard of the android device and start the app (Kivy
#   Launcher)
#
#   Have Fun!
#
#
#   Dependencies:
#   1. Have a usb cable connect in your computer and android device
#
#   2. Have android app (Kivy Launcher) installed in the android device
#   Link: https://play.google.com/store/apps/details?id=org.kivy.pygame
#
#   3. Have the android sdk uncompressed in your computer
#   Link: http://developer.android.com/sdk/index.html
#
#   4. Have buildozer installed:
#   Link: http://buildozer.readthedocs.org/en/latest/installation.html#targeting-android
#
#   Extra: (installation on ubuntu 13.10 or higher)
#       sudo pip install --upgrade cython
#       sudo dpkg --add-architecture i386
#       sudo apt-get update
#       sudo apt-get install build-essential ccache git libncurses5:i386 \
#                            libstdc++6:i386 python2.7 python2.7-dev \
#                            openjdk-7-jdk unzip zlib1g-dev zlib1g:i386
#
#   5. Define the ANDROID_SDK_PATH variable with the folder path of
#   your android sdk, (with you use buildozer your sdk will be here:
#   ~/.buildozer/android/platform/android-sdk..)
#
#   6. Define the KIVY_PROJECT_PATH variable with the folder path of
#   your kivy project
#
#   Thats All Folks!
#
#   Observation:
#   If you never heard about buildozer, research it, because it's really
#   worthwhile! it automates many processes to build the package creation
#   .apk, and just as I open (Kivy Launcher) at the end of the deployment,
#   it installs and opens your app Kivy you just package all in one command.
#   Links:
#   - http://buildozer.readthedocs.org/en/latest/
#   - https://pypi.python.org/pypi/buildozer/0.14
#   - https://github.com/kivy/buildozer
#   - http://kivy.org/docs/guide/packaging-android.html#buildozer
#
#

# SET YOUR VARIABLES HERE
ANDROID_SDK_PATH='/home/samuel/.buildozer/android/platform/android-sdk-21'
KIVY_PROJECT_PATH=$(pwd) # it can be the entire path of your project too

# down here let me define by myself
KIVY_REMOTE_FOLDER='/sdcard/kivy'
KIVY_PROJECT_FOLDER=$(basename $KIVY_PROJECT_PATH)
IGNORE_TERMS=( .apk .git buildozer )

function check_required_tools() {
  echo -n "Defining the adb command path:   "
  if [ -f "$ANDROID_SDK_PATH/platform-tools/adb" ];
  then
    ADB="$ANDROID_SDK_PATH/platform-tools/adb";
    echo -e "[  OK  ]\nadb path: $ADB\n"
  elif [ -f "$ANDROID_SDK_PATH/tools/adb" ];
  then
    ADB="$ANDROID_SDK_PATH/tools/adb";
    echo -e "[  OK  ]\nadb path: $ADB\n"
  else
    echo -e "[FAILED]\nImpossible to find 'adb' command in SDK Path: $ANDROID_SDK_PATH"
    exit 1
  fi
}

function check_connected_devices() {
  echo -n "Checking if there are devices connected:   "
  DEVICES_CONNECTED=$($ADB devices | grep -v List | grep -v '^$' | wc -l)
  if [ "$DEVICES_CONNECTED" -lt "1" ];
  then
    echo -e "[FAILED]\nNot Found Devices Connected with this computer \!"
    exit 2
  else
    echo -e "[  OK  ]\n"
  fi
}

function transfer_project_file_to_phone() {
  cd $(dirname $KIVY_PROJECT_PATH)

  IGNORED_FILES=''
  for TERM in ${IGNORE_TERMS[*]};
  do
    IGNORED_FILES="$IGNORED_FILES | grep -v '$TERM'"
  done

  echo -n "Finding kivy project folders:   "
  KIVY_PROJECT_FOLDERS=($(eval find $KIVY_PROJECT_FOLDER -type d $IGNORED_FILES))
  if [ "$?" -eq "0" ];
  then
    echo -e "[  OK  ]\n"
  else
    echo -e "[FAILED]\n"
  fi

  echo -n "Finding kivy project files:   "
  KIVY_PROJECT_FILES=($(eval find $KIVY_PROJECT_FOLDER -type f $IGNORED_FILES))
  if [ "$?" -eq "0" ];
  then
    echo -e "[  OK  ]\n"
  else
    echo -e "[FAILED]\n"
  fi

  echo -n "Ensuring that Kivy folders exists..."
  $ADB shell mkdir -p $KIVY_REMOTE_FOLDER
  for KIVY_PROJECT_FOLDER in ${KIVY_PROJECT_FOLDERS[*]};
  do
    $ADB shell mkdir -p $KIVY_REMOTE_FOLDER/$KIVY_PROJECT_FOLDER
  done
  echo -e "\n"

  echo "Initilizing file transfer:"
  for KIVY_PROJECT_FILE in ${KIVY_PROJECT_FILES[*]};
  do
    echo "$KIVY_PROJECT_FILE -> $KIVY_REMOTE_FOLDER/$KIVY_PROJECT_FILE "
    $ADB push -p $KIVY_PROJECT_FILE $KIVY_REMOTE_FOLDER/$KIVY_PROJECT_FILE
    echo ""
  done
}

function start_app_in_kivy_launcher() {
  $ADB shell am start -n org.kivy.pygame/org.renpy.android.ProjectChooser
}

case $1 in
  'test_kivy_launcher')
     check_required_tools
     check_connected_devices

     transfer_project_file_to_phone
     start_app_in_kivy_launcher
  ;;
  'deploy')
 		 buildozer android debug deploy run

  ;;
  *) buildozer android debug deploy run
esac
