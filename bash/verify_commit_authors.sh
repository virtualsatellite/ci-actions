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

echo "[Info] ------------------------------------"
echo "[Info] Verify commit authors"
echo "[Info] ------------------------------------"
echo "[Info] "

echo "[Info] ------------------------------------"
echo "[Info] Get the full history"
echo "[Info] and prepare local git repo"
echo "[Info] ------------------------------------"
echo "[Info] "

# Test if it is a shallow repository as usually checked out
# on travis ci build nodes

if [ -f $(git rev-parse --git-dir)/shallow ]; then
	echo "[Info] Current repository is shallow"
	echo "[Info] Need to unshallow"
	git fetch --unshallow
else
  echo "[Info] Current repository is not shallow"
fi

echo "[Info] ------------------------------------"
echo "[Info] Fetch dev branch as reference"
echo "[Info] ------------------------------------"

git fetch origin development:development
	
echo "[Info] ------------------------------------"
echo "[Info] Show current branches"
echo "[Info] ------------------------------------"

git branch -a

echo "[Info] ------------------------------------"
echo "[Info] Analyse authors integrity"
echo "[Info] ------------------------------------"

echo "[Info] Checking .mailmap"

# here we need to use the ... to actually see the diff of a file for just the branch
# using .. would compare the head of development with head of the current branch. Thus
# showing both differences.
git diff --quiet development... .mailmap
CHANGED_MAILMAP=$?

echo "[Info] Checking known_authors.txt"

git diff --quiet development... known_authors.txt
CHANGED_KNOWN_AUTHORS=$?

echo "[Info] ------------------------------------"
echo "[Info] Fork detection"
echo "[Info] ------------------------------------"

# Now checking if we are on normal PR or on a forked PR
# we usually assume we are on a fork
STRICT_RULES="true"
if [ ! -v $CI ]; then 
	echo "[Info] Running on Github Actions"
	echo "[Info] ENV Local Repo: $GITHUB_REPOSITORY"
	echo "[Info] ENV Build Source Repo: $BUILD_REPOSITORY"
	echo "[Info] ENV Github Event Name: $GITHUB_EVENT_NAME"
	
	if [ "$GITHUB_EVENT_NAME" != "pull_request" ]; then
		echo "[Info] Building a local branch, RELAXED rules apply!"
		STRICT_RULES="false"	
	else
		if [ "$BUILD_REPOSITORY" == "$GITHUB_REPOSITORY" ]; then
			echo "[Info] Building a local PR, RELAXED rules apply!"
			STRICT_RULES="false"
		else
			echo "[Info] Building a fork PR, STRICT rules apply!"
		fi
	fi
else
	echo "[Info] Not running on Github Actions"
fi

echo "[Info] ------------------------------------"
echo "[Info] Create commit authors file"
echo "[Info] ------------------------------------"
echo "[Info] "

# here we have to use .. and not ... . Only .. shows the log of the particular branch
# and negates the ones from the first one, which is development. Be aware this is opposite behavior 
# compared to the git diff
git log development.. --pretty=format:"%aN" | sort | uniq > ./commit_authors.txt

echo "[Info] ------------------------------------"
echo "[Info] List of Commits and Authors"
echo "[Info] ------------------------------------"
echo "[Info] "

git --no-pager log development.. --pretty=format:"%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%aN>%Creset" --abbrev-commit --reverse

echo ""
echo "[Info] ------------------------------------"
echo "[Info] List of Commit Authors"
echo "[Info] ------------------------------------"
echo "[Info] "

cat ./commit_authors.txt

echo "[Info] ------------------------------------"
echo "[Info] List of Known Authors"
echo "[Info] ------------------------------------"
echo "[Info] "

# The next statement first removes all windows style line feeds, then the result is piped to the next
# sed to remove empty lines.
sed 's/\r$//' known_authors.txt | sed '/^$/d' > known_authors_cleaned.txt
cat ./known_authors_cleaned.txt

echo "[Info] ------------------------------------"
echo "[Info] List of unknown Authors"
echo "[Info] ------------------------------------"
echo "[Info] "

UNKNOWN_AUTHORS=$(grep -v -F -f ./known_authors_cleaned.txt ./commit_authors.txt)

CR='\033[0;31m' # Red Color
CY='\033[1;33m' # Yellow Color
CG='\033[1;32m' # Green Color
CN='\033[0m'    # Reset Color

echo -e "${CR}${UNKNOWN_AUTHORS}${CN}"

echo "[Info] "
echo "[Info] ------------------------------------"
echo "[Info] generate Analysis Report"
echo "[Info] ------------------------------------"
echo "[Info] "

# Set the Review Status to APPROVE
# in case of one test failing, set it to REQUEST_CHANGES
REVIEW_STATUS="APPROVE"

REPORT=$'[Info] Author Verification Report \n'
REPORT+=$'[Info] ---------------------------\n'

REVIEW_STATUS_WARNINGS="REQUEST_CHANGES"
if [ $STRICT_RULES != "true" ]; then
	REVIEW_STATUS_WARNINGS="APPROVE"
	REPORT+=$"[Info] Using RELAXED fail rules \n"
else
	REPORT+=$"[Info] Using STRICT fail rules \n"
fi

if [ "$UNKNOWN_AUTHORS" != "" ]; then
	REVIEW_STATUS="REQUEST_CHANGES"
	REPORT+=$"[Warn] SERIOUS: Some Authors in commit History without CLA!...(REQUEST_CHANGES) \n"
else
	REPORT+=$"[Info] OK:      All Authors in commit history with CLA........(APPROVE) \n"
fi

if [ $CHANGED_MAILMAP -ne 0 ]; then
	REVIEW_STATUS="${REVIEW_STATUS_WARNINGS}"
	REPORT+=$"[Warn] WARNING: <.mailmap> file has been changed!.............(${REVIEW_STATUS_WARNINGS}) \n"
else
	REPORT+=$"[Info] OK:      <.mailmap> file is not modified...............(APPROVE) \n"	
fi

if [ $CHANGED_KNOWN_AUTHORS -ne 0 ]; then
	REVIEW_STATUS="${REVIEW_STATUS_WARNINGS}"
	REPORT+=$"[Warn] WARNING: <known_authors.txt> file has been changed!....(${REVIEW_STATUS_WARNINGS}) \n"
else
	REPORT+=$"[Info] OK:      <known_authors.txt> file is not modified......(APPROVE) \n"	
fi

COLORED_REPORT=$(echo "${REPORT}" | sed -e "s/SERIOUS/\\${CR}SERIOUS\\${CN}/g" | sed -e "s/WARNING/\\${CY}WARNING\\${CN}/g" | sed -e "s/OK/\\${CG}OK\\${CN}/g")
COLORED_REPORT=$(echo "${COLORED_REPORT}" | sed -e "s/REQUEST_CHANGES/\\${CR}REQUEST_CHANGES\\${CN}/g" | sed -e "s/APPROVE/\\${CG}APPROVE\\${CN}/g")

echo -e "${COLORED_REPORT}"
if [ "$REVIEW_STATUS" == "APPROVE" ] ; then
  echo    "[Info] ------------------------------------"
  echo -e "[Info] ${CG}Report does not show anomalies!${CN}"
  echo    "[Info] ------------------------------------"
else
  echo    "[Warn] ------------------------------------"
  echo -e "[Warn] ${CR}Report shows anomalies!${CN}"
  echo    "[Warn] ------------------------------------"
  exit 1
fi
