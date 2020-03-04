#!/usr/bin/env bash
set -euo pipefail

sourceBranch="master"
targetBranch="release"
temporaryBranch="temporaryBranchForReleaseProcess"

echo "**********************************************************"
echo "****** This is to start Android relese process "
echo "****** Warning: Your $sourceBranch and $targetBranch will be rsync"
echo "****** Make sure you don't have a different commit on them"
echo "**********************************************************"
echo ""
read -p "Ready for Android release process (YES/NO)? " CONT
if [[ $CONT =~ ^([Yy][Ee][Ss])$ ]]
then
	Echo "Start Release Android Process"
else
	Echo "Type YES enter if you want to proceed"
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
git branch -D $sourceBranch
git branch -D $targetBranch
git checkout $sourceBranch

if [ ! -f ./version ]; then
    echo "./version file not found! Please inform team"
	exit 1    
fi

echo "Updating version number"

versionFileName="./version"
version=$(head -n 1 $versionFileName)
echo "current version is $version"
majorVersion=`cut -d'.' -f1 <<<$version`
minorVersion=`cut -d'.' -f2 <<<$version`
newMinorVersion=$(($minorVersion+1))
newVersion=$majorVersion.$newMinorVersion
echo "new version is $newVersion"
echo $newVersion > $versionFileName
echo "written new version to version file"

git add -A .

echo "Committing changes"
git commit -m "auto: bump app version"
git push origin

echo "Merge $sourceBranch to $targetBranch"
export GIT_MERGE_AUTOEDIT=no

git checkout $targetBranch
git merge $sourceBranch
git push
git branch -D $targetBranch
git branch -D $temporaryBranch
git checkout $currentBranchName

echo "*************************************"
echo "****** Done updating from $version to $newVersion "
echo "****** Merged $sourceBranch to $targetBranch build"
echo "*************************************"
