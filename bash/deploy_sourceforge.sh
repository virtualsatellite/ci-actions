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

# --------------------------------------------------------------------------
# This script handles all upload activities of the project Virtual Satellite
# --------------------------------------------------------------------------

set -e

# Store the name of the command calling from commandline to be properly
# displayed in case of usage issues
COMMAND=$0
__DIR=$(dirname "$0")

# this method gives some little usage info
printUsage() {
	echo "usage: ${COMMAND} -s <openssl_pass> <sshpass> -u [development|integration|release] -d <localdir> -r <remotedir>"
	echo ""
	echo "This command is calling apt to set up the OS."
	echo ""
	echo "Options:"
	echo " -s, --setup <openssl_pass> <sshpass> This options decrypt and sets up the ssh secret first."
	echo " -u, --upload <profile>               The name of of a file which contains the names for additional packages to be installed."
	echo " -d, --localdir <localdir>            The local directory to be synchronized and uploaded"
	echo " -r, --remotedir <remotdir>           The remote directory to be synchronized and uploaded"
	echo ""
	echo "Copyright by DLR (German Aerospace Center)"
}

setupSourceforgeSecrets() {
	# Start the ssh agent
	echo ""
	echo "------------------"
	echo "Starting ssh-agent"
	echo "------------------"
	eval "$(ssh-agent -s)"

	# Decrypt the key for accessign the 
	# deployment store and add it to ssh-agent
	echo "Adding sourceforge as known SSH host"
	SSH_DIR="$HOME/.ssh"
	mkdir -p "${SSH_DIR}"
	touch "${SSH_DIR}/known_hosts"
	chmod 600 "${SSH_DIR}/known_hosts"
	ssh-keyscan "frs.sourceforge.net" >> "${SSH_DIR}/known_hosts"

	# Prepare sourceforge secrets
	echo "Connecting to sourceforge"
	mkdir -p -m 700 tmp/.sourceforge_ssh
	echo "OpenSSL is version"
	openssl version
	echo "Executing openssl to decrypt key"
	openssl aes-256-cbc -d -a -pbkdf2 -in id_ed25519.enc -out tmp/.sourceforge_ssh/id_ed25519_dec -pass "pass:${OPENSSL_PASS}"
	echo "Adjusting rights on file system"
	chmod 600 tmp/.sourceforge_ssh/id_ed25519_dec
	echo "Adding ssh key to known ones using correct password"
	"${__DIR}/ssh-add-password.sh" -k tmp/.sourceforge_ssh/id_ed25519_dec -p "${SSH_KEY_PASS}" 2>/dev/null
}

upload() {
	echo ""
	echo "------------------"
	echo "Uploading"
	echo "------------------"
	echo "Rsync Options:        $RSYNC_OPTIONS"
	echo "Local Directory P2:   $LOCAL_DIR_P2" 
	echo "Local Directory BIN:  $LOCAL_DIR_BIN" 
	echo "Remote Directory P2:  $REMOTE_DIR_P2" 
	echo "Remote Directory BIN: $REMOTE_DIR_BIN" 
	echo ""
	echo "Starting uploads..."
	echo ""
	echo "Starting P2 uploads..."
	if [[ -d $LOCAL_DIR_P2 ]] ; then
		echo "Uploading p2 directory..."
		rsync $RSYNC_OPTIONS "$LOCAL_DIR_P2" "dlrscmns@frs.sourceforge.net:/home/frs/project/$REMOTE_DIR_P2"
	else
		echo "P2 directory was not found. Nothing was uploaded."
	fi
	
	echo ""
	echo "Starting BIN uploads..."
	
	if [[ -d $LOCAL_DIR_BIN ]] ; then
		echo "Uploading bin directory..."
		rsync $RSYNC_OPTIONS "$LOCAL_DIR_BIN" "dlrscmns@frs.sourceforge.net:/home/frs/project/$REMOTE_DIR_BIN"
	else
		echo "Bin directory was not found. Nothing was uploaded."
	fi
	
	echo "Upload done."
}

uploadDevelopment() {
	LOCAL_DIR_P2=deploy/unsecured/p2/$LOCAL_DIR/development/
	LOCAL_DIR_BIN=deploy/unsecured/bin/$LOCAL_DIR/development/
	REMOTE_DIR_P2=$REMOTE_DIR/development/
	REMOTE_DIR_BIN=$REMOTE_DIR/bin/development/
	RSYNC_OPTIONS="-e ssh -avP --delete"

	upload
}

uploadIntegration() {
	LOCAL_DIR_P2=deploy/unsecured/p2/$LOCAL_DIR/integration/
	LOCAL_DIR_BIN=deploy/unsecured/bin/$LOCAL_DIR/integration/
	REMOTE_DIR_P2=$REMOTE_DIR/integration/
	REMOTE_DIR_BIN=$REMOTE_DIR/bin/integration/
	RSYNC_OPTIONS="-e ssh -avP"

	upload
}

uploadRelease() {
	LOCAL_DIR_P2=deploy/secured/p2/$LOCAL_DIR/release/
	LOCAL_DIR_BIN=deploy/secured/bin/$LOCAL_DIR/release/
	REMOTE_DIR_P2=$REMOTE_DIR/release/
	REMOTE_DIR_BIN=$REMOTE_DIR/bin/release/
	RSYNC_OPTIONS="-e ssh -avP"

	upload
}

# process all command line arguments
while [ "$1" != "" ]; do
    case $1 in
        -u | --upload )         shift
                                UPLOAD=$1
                                ;;
        -h | --help )           printUsage
                                exit
                                ;;
        -s | --setup )          shift
                                OPENSSL_PASS=$1
                                shift
                                SSH_KEY_PASS=$1
                                setupSourceforgeSecrets
                                ;;
        -d | --localdir )       shift
                                LOCAL_DIR=$1
                                ;;
        -r | --remotedir )      shift
                                REMOTE_DIR=$1
                                ;;
        * )                     printUsage
                                exit 1
    esac
    shift
done

# Decide what to upload
case $UPLOAD in
    development )       uploadDevelopment
                        exit
                        ;;
    integration )       uploadIntegration
                        exit
                        ;;
    release )           uploadRelease
                        exit
                        ;;
    * )                 printUsage
                        exit 1
esac
