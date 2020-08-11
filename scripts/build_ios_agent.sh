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
rm -rf ${BUILD_PATH}/iphoneos

# build device version
/usr/bin/xcodebuild -configuration Release -scheme Agent-iOS -sdk iphoneos archive BUILD_LIBRARIES_FOR_DISTRIBUTION=YES > build.out 2>&1

if [ $? -ne 0 ]; then
  print "Xcode build failed."
  cat build.out
  exit 1
fi

# insert xcode build environmental vars
source ${BUILD_PATH}/archive_paths.sh


# Copying EXECUTABLE_NAME to build_path/platform folder
  mkdir -p ${BUILD_PATH}/iphoneos
  echo "copying built ${CODESIGNING_FOLDER_PATH} to build/iphoneos"
  cp -p -R ${CODESIGNING_FOLDER_PATH} ${BUILD_PATH}/iphoneos/${EXECUTABLE_NAME}.framework

#build simulator version
/usr/bin/xcodebuild -configuration Release -scheme Agent-iOS -sdk iphonesimulator build > build.out 2>&1

if [ $? -ne 0 ]; then
  print "Xcode build failed."
  cat build.out
  exit 1
fi

# insert xcode build environmental vars
source ${BUILD_PATH}/archive_paths.sh

# copy simulator build to local build folder
mkdir -p ${BUILD_PATH}/iphonesimulator
echo "Copying ${EXECUTABLE_NAME} to build/iphonesimulator"
cp -p -R ${CODESIGNING_FOLDER_PATH}/ ${BUILD_PATH}/iphonesimulator/${EXECUTABLE_NAME}.framework/


# combine device & simulator artifacts
echo "Merging iphonesimulator/${EXECUTABLE_NAME} and iphoneos/${EXECUTABLE_NAME} into universal"
mkdir -p ${BUILD_PATH}/universal
cp -p -R $BUILD_PATH/iphoneos/${EXECUTABLE_NAME}.framework/ ${BUILD_PATH}/universal/${EXECUTABLE_NAME}.framework/
/usr/bin/lipo -create ${BUILD_PATH}/iphonesimulator/${EXECUTABLE_NAME}.framework/${EXECUTABLE_NAME} ${BUILD_PATH}/iphoneos/${EXECUTABLE_NAME}.framework/${EXECUTABLE_NAME} -o ${BUILD_PATH}/universal/${EXECUTABLE_NAME}.framework/${EXECUTABLE_NAME}




