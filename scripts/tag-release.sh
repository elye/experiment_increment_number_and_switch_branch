#!/bin/bash
set -eo pipefail

sourceBranch="master"
targetBranch="release"
temporaryBranch="temporaryBranchForReleaseProcess"

echo "**********************************************************"
echo "****** This is to start Android tagging release "
echo "****** Warning: Your $targetBranch will be resync"
echo "****** Make sure you don't have a different commit on them"
echo "**********************************************************"
echo ""

if [[ "$1" != "--noprompt" ]]
then
	read -p "Ready for Tagging Android release (YES/NO)? " CONT
	if [[ $CONT =~ ^([Yy][Ee][Ss])$ ]]
	then
		Echo "Start Tagging Android Release"
	else
		Echo "... Cancel Tagging Android Release ..."
		Echo "(Type YES enter if you want to proceed)"
		exit 1
	fi
fi	

if [ ! -z `git rev-parse --verify --quiet $temporaryBranch` ]; then
	echo "Oops, you have $temporaryBranch. Please remove it"
	exit 1
fi

currentBranchName=`git rev-parse --abbrev-ref HEAD`

if [ -z "$(git status --porcelain)" ]; then 
  	echo "Ok: Your $currentBranchName is commited"
  	echo "    Safe to switch branch for our process"
else 
	echo "Error: You have uncommited change on $currentBranchName"
	echo "       Please commit, stash or reset them before proceeding"
	exit 1
fi

echo "...Fetching latest update..."
git fetch

git checkout -b $temporaryBranch

if [ ! -z `git rev-parse --verify --quiet $targetBranch` ]; then
	git branch -D $targetBranch
fi

git checkout $targetBranch

versionFileName="./version"
if [ ! -f $versionFileName ]; then
    echo "$versionFileName file not found! Please inform team"
	exit 1    
fi

echo "Tagging release with version number"

version=$(head -n 1 $versionFileName)
echo "current version is $version"
newTag="${version}"

if [ ! -z `git rev-parse --verify --quiet ${newTag}` ]; then
  echo "Tag exists: remove ${newTag} it first";
  git tag -d ${newTag}
  git push --delete origin ${newTag}
fi  

git tag ${newTag}
git push origin ${newTag}

git checkout $currentBranchName
git branch -D $targetBranch
git branch -D $temporaryBranch

echo "********************************************"
echo "****** Done tagging $version release branch "
echo "********************************************"

majorVersion=`cut -d'.' -f1 <<<$version`
minorVersion=`cut -d'.' -f2 <<<$version`
oldMinorVersion=$(($minorVersion-1))
oldVersion=$majorVersion.$oldMinorVersion
echo "older version is $oldVersion"

sh ./scripts/release-notes.sh $oldVersion $version | pbcopy

echo "********************************************"
echo "****** Done copy release notes on clipboard "
echo "********************************************"
