#!/bin/bash

#/*******************************************************************************
# * Copyright (c) 2008-2019 German Aerospace Center (DLR), Simulation and Software Technology, Germany.
# *
# * This program and the accompanying materials are made available under the
# * terms of the Eclipse Public License 2.0 which is available at
# * http://www.eclipse.org/legal/epl-2.0.
# *
# * SPDX-License-Identifier: EPL-2.0
# *******************************************************************************/

# --------------------------------------------------------------------------------------------
# This script prepares the environment to install necessary packages like vtk or zmq
# --------------------------------------------------------------------------------------------
set +e

COMMAND=$0

printUsage() {
	echo "usage: ${COMMAND} -x -p <pkgfile>"
	echo ""
	echo "This command is calling apt to set up the OS."
	echo ""
	echo "Options:"
	echo " -x, --xvfb            Option to install XVFB and Metacity. Usually needed by surefire UI tests."
	echo " -a, --pkgs <pkgfile>  The name of of a file which contains the names for additional packages to be installed."
	echo ""
	echo "Copyright by DLR (German Aerospace Center)"
}

# process all command line arguments
while [ "$1" != "" ]; do
    case $1 in
        -x | --xvfb )           shift
                                INSTALL_XVFB=true
                                ;;
        -p | --pkgs )           shift
                                INSTALL_PKGS=$1
                                ;;
        -h | --help )           printUsage
                                exit
                                ;;
        * )                     printUsage
                                exit 1
    esac
    shift
done

echo ""
echo "-----------------------------------------------"
echo "apt update"
echo "-----------------------------------------------"
sudo apt-get update

echo ""
echo "-----------------------------------------------"
echo "apt install general packages"
echo "-----------------------------------------------"
sudo apt-get install openjdk-8-jdk ant expect jq


if [[ ! -z "$INSTALL_XVFB" && "$INSTALL_XVFB"==true ]]; then
	echo ""
	echo "-----------------------------------------------"	
	echo "apt install metacity and xvfb"
	echo "-----------------------------------------------"
	echo "Detected the XVFB install option..."
	sudo apt-get install xvfb metacity
fi

if [[ ! -z "$INSTALL_PKGS" && -f "$INSTALL_PKGS" ]]; then
	echo ""
	echo "-----------------------------------------------"	
	echo "apt install additional packages"
	echo "-----------------------------------------------"
	echo "Detected the packages file $INSTALL_PKGS..."
	echo "Current content of file: $(cat $INSTALL_PKGS)"
	sudo apt-get install < $INSTALL_PKGS
fi
