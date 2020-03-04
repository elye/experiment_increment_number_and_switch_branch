#!/usr/bin/env bash
set -euo pipefail

sourceBranch="master"
targetBranch="release"

read -p "Ready for Android release process (YES/NO)? " CONT
if [[ $CONT =~ ^([Yy][Ee][Ss])$ ]]
then
	Echo "Start Release Android Process"
else
	Echo "Type YES enter if you want to proceed"
	exit 1
fi

branchName=`git rev-parse --abbrev-ref HEAD`
if [ "$branchName" != "$sourceBranch" ]
then
	echo "Error: You are currently on $branchName branch"
	echo "       Please checkout $sourceBranch branch"
	exit 1
else
	echo "Ok: You are on $sourceBranch branch"
fi

echo "...Now pulling latest change on $sourceBranch branch.. wait..."
git pull

if [ -z "$(git status --porcelain)" ]; then 
  	echo "Ok: Your $sourceBranch is clean"
else 
	echo "Error: You have uncommited change on $sourceBranch"
	echo "       Please stash them or reset them"
	exit 1
fi

if [ -z "$(git status -sb | grep ahead)" ]; then
	echo "Ok: Your $sourceBranch is sync with remote"
else
	echo "Error: Your local $sourceBranch is ahead of remote"
	echo "       Please sync with remote $sourceBranch"
	exit 1
fi

if [ ! -f ./version ]; then
    echo "Version file not found!"
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
git checkout $sourceBranch

echo "*************************************"
echo "****** Done updating from $version to $newVersion "
echo "****** Merged $sourceBranch to $targetBranch build"
echo "*************************************"
