#!/bin/bash

#/*******************************************************************************
# * Copyright (c) 2020 German Aerospace Center (DLR), Simulation and Software Technology, Germany.
# *
# * This program and the accompanying materials are made available under the
# * terms of the Eclipse Public License 2.0 which is available at
# * http://www.eclipse.org/legal/epl-2.0.
# *
# * SPDX-License-Identifier: EPL-2.0
# *******************************************************************************/

# --------------------------------------------------------------------------------------------
# This script tries to setup the environment variables for native librarie sucha s vtk and zmq
# --------------------------------------------------------------------------------------------
set +e


# Store the name of the command calling from commandline to be properly
# displayed in case of usage issues
COMMAND=$0

# this method gives some little usage info
printUsage() {
	echo "usage: ${COMMAND} -v version"
	echo ""
	echo "Options:"
	echo " -m, --maven <version>	the maven version to be used e.g. 3.9.6."
	echo " -h, --help             	prints this help."
	echo ""
	echo "Copyright by DLR (German Aerospace Center)"
}

# process all command line arguments
while [ "$1" != "" ]; do
    case $1 in
        -m | --maven )        shift
                                MAVEN_VERSION=$1
                                ;;
        -h | --help )           printUsage
                                exit
                                ;;
        * )                     printUsage
                                exit 1
    esac
    shift
done


callSetupMaven() {
	if [[ ! -z "$MAVEN_VERSION" ]]; then
		echo "Maven - Check if instalation file exists"
		if [[ ! -f ./maven.tar.gz ]]; then
			echo "Maven - Downloading Maven ${MAVEN_VERSION}"
	    	curl -o maven.tar.gz https://dlcdn.apache.org/maven/maven-3/${MAVEN_VERSION}/binaries/apache-maven-${MAVEN_VERSION}-bin.tar.gz
	    fi
		echo "Maven - Unpacking Maven"
		tar -xvf maven.tar.gz
		echo "Maven - Setup Environment Variables"
		M2_HOME="./apache-maven-${MAVEN_VERSION}"
		PATH="$M2_HOME/bin:$PATH"
		export PATH
		export M2_HOME
		echo "Maven - Print Version"
		mvn --version
	fi
}

callSetupMaven

