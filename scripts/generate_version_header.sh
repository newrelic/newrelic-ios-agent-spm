#!/usr/bin/env bash

#!/bin/bash -x

if [ "$#" -eq 0 ]; then
  underline=`tput smul`
  nounderline=`tput rmul`
  bold=`tput bold`
  normal=`tput sgr0`
  echo -e "generates NRMAAgentVersion.h to be used in the NewRelicAgent.framework with the value passed to this script."
  echo -e "usage: ${bold}$0${normal} ${underline}version_string${normal}"
  echo -e "\t${underline}version_string${normal}: the version which will be used set in NRMAAgentVersion.h"
  exit 1
fi

VERSION_HEADER=`find . | grep NRMAAgentVersion.h`

if [ ! -e "$VERSION_HEADER" ]; then
  echo "unable to find NRMAAgentVersion.h"
  exit 1
fi
echo "writing version \"$1\" to $VERSION_HEADER"
echo "static const char* __NRMA_NewRelic_iOS_Agent_Version = \""$1"\";" > $VERSION_HEADER

