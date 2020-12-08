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

# --------------------------------------------------------------------------
# This script hands back two environment variables telling which build
# and deployment should be performed. The decision is made on a set of given
# GitHub environment variables.
# --------------------------------------------------------------------------

# fail the script if a call fails
set -e

# Store the name of the command calling from commandline to be properly
# displayed in case of usage issues
COMMAND=$0

printHeader() {
	echo "Virtual Satellite - GitHub Build Decision Action"
	echo ""
	echo "Output Variables:"
	echo " BUILD_TYPE_DECISION  Tells if the build is either one of (development|integration|release)"
	echo " DEPLOY_TYPE_DECISION Tells if the build is to be released or kept (deploy|keep)"
	echo ""
	echo "Current environment for making decision:"
	echo "GITHUB_REF:        $GITHUB_REF"
	echo "GITHUB_BASE_REF:   $GITHUB_BASE_REF"
	echo "GITHUB_EVENT_NAME: $GITHUB_EVENT_NAME"
	echo ""
	echo "Copyright by DLR (German Aerospace Center)"
}

makeBuildDecision() {
	if	[[ $GITHUB_REF != *"integration"* ]] || \
		[[ $GITHUB_BASE_REF != *"integration"* ]] || \
		[[ $GITHUB_REF != *"integration_snapshot"* ]] || \
		[[ $GITHUB_REF != *"development_snapshot"* ]] || \
		[[ $GITHUB_REF != *"master"* ]] || \
		[[ $GITHUB_BASE_REF != *"master"* ]] || \
		[[ $GITHUB_REF != *"refs/tags/Release"* ]];
	then
		BUILD_TYPE_DECISION=development
		
	elif	[[ $GITHUB_REF == "refs/heads/integration" ]] || \
			[[ $GITHUB_BASE_REF != *"integration"* ]] && [[ $GITHUB_EVENT_NAME == "pull_request" ]];
	then
		BUILD_TYPE_DECISION=integration
		
	elif	[[ $GITHUB_REF == *"refs/heads/master"* ]] || \
			[[ $GITHUB_REF == *"refs/tags/Release"*]] || \
			[[ $GITHUB_BASE_REF != *"master"* ]] && [[ $GITHUB_EVENT_NAME == "pull_request" ]];
	then
		BUILD_TYPE_DECISION=release
		
	else
		BUILD_TYPE_DECISION=unknown
		
	fi
}

makeDeployDecision() {
	if	[[ $GITHUB_REF == "refs/heads/development" ]] || \
		[[ $GITHUB_REF == "refs/heads/development" ]] || \
		[[ $GITHUB_REF == "refs/tags/Release"* ]];
	then
		DEPLOY_TYPE_DECISION=deploy
	else
		DEPLOY_TYPE_DECISION=keep
	fi
}

printHeader
makeBuildDecision
makeDeployDecision

echo ""
echo "Made a decision:"
echo "  Build Type:  $BUILD_TYPE_DECISION"
echo "  Deploy Type: $DEPLOY_TYPE_DECISION"
echo ""

export BUILD_TYPE_DECISION
export DEPLOY_TYPE_DECISION
