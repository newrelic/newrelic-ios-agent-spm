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
rm -rf ${BUILD_PATH}/macosx

# build device version
/usr/bin/xcodebuild -configuration Release -scheme Agent-iOS -sdk macosx archive BUILD_LIBRARIES_FOR_DISTRIBUTION=YES SUPPORTS_MACCATALYST=YES > build.out 2>&1

if [[ $? != 0 ]]; then
  print "Xcode build failed."
  cat build.out
  exit 1
fi

# insert xcode build environmental vars
source ${BUILD_PATH}/archive_paths.sh


# Copying EXECUTABLE_NAME to build_path/platform folder
  mkdir -p ${BUILD_PATH}/macosx
  echo "copying built ${CODESIGNING_FOLDER_PATH} to build/macosx"
  cp -p -R ${CODESIGNING_FOLDER_PATH} ${BUILD_PATH}/macosx/${EXECUTABLE_NAME}.framework






