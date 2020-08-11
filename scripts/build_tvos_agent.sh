#!/usr/bin/env bash -x

# exit script on error
set -e

###########################
#create the script_path var
###########################
pushd `dirname $0` > /dev/null
SCRIPT_PATH=`pwd`
BUILD_PATH="${SCRIPT_PATH}/../build"
popd > /dev/null

echo "SCRIPT_PATH: ${SCRIPT_PATH}"
echo "BUILD_PATH: ${BUILD_PATH}"



# set version from agvtool

VERSION=`agvtool vers -terse`

# move to root dir
pushd ${SCRIPT_PATH}/..

# cleaning up build directory
rm -rf ${BUILD_PATH}/appletvos

# build device version
/usr/bin/xcodebuild -configuration Release -scheme Agent-tvOS -sdk appletvos archive BUILD_LIBRARIES_FOR_DISTRIBUTION=YES > build.out 2>&1

if [ $? -ne 0 ]; then
  print "Xcode build failed."
  cat build.out
  exit 1
fi

# insert xcode build environmental vars
source ${BUILD_PATH}/archive_paths.sh


# Copying EXECUTABLE_NAME to build_path/platform folder
  mkdir -p ${BUILD_PATH}/appletvos
  echo "copying built ${CODESIGNING_FOLDER_PATH} to build/appletvos"
  cp -p -R ${CODESIGNING_FOLDER_PATH} ${BUILD_PATH}/appletvos/${EXECUTABLE_NAME}.framework

#build simulator version
/usr/bin/xcodebuild -configuration Release -scheme Agent-tvOS -sdk appletvsimulator build > build.out 2>&1

if [ $? -ne 0 ]; then
  print "Xcode build failed."
  cat build.out
  exit 1
fi

# insert xcode build environmental vars
source ${BUILD_PATH}/archive_paths.sh

# copy simulator build to local build folder
mkdir -p ${BUILD_PATH}/appletvsimulator
echo "Copying ${EXECUTABLE_NAME} to build/appletvsimulator"
cp -p -R ${CODESIGNING_FOLDER_PATH}/ ${BUILD_PATH}/appletvsimulator/${EXECUTABLE_NAME}.framework/


# combine device & simulator artifacts
echo "Merging appletvsimulator/${EXECUTABLE_NAME} and appletvos/${EXECUTABLE_NAME} into universal"
mkdir -p ${BUILD_PATH}/universal-tvos
cp -p -R $BUILD_PATH/appletvos/${EXECUTABLE_NAME}.framework/ ${BUILD_PATH}/universal-tvos/${EXECUTABLE_NAME}.framework/
/usr/bin/lipo -create ${BUILD_PATH}/appletvsimulator/${EXECUTABLE_NAME}.framework/${EXECUTABLE_NAME} ${BUILD_PATH}/appletvos/${EXECUTABLE_NAME}.framework/${EXECUTABLE_NAME} -o ${BUILD_PATH}/universal-tvos/${EXECUTABLE_NAME}.framework/${EXECUTABLE_NAME}




