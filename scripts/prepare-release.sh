#!/usr/bin/env bash
set -euo pipefail

sourceBranch="master"
targetBranch="release"
temporaryBranch="temporaryBranchForReleaseProcess"

echo "**********************************************************"
echo "****** This is to start Android release process "
echo "****** Warning: Your $sourceBranch and $targetBranch will be resync"
echo "****** Make sure you don't have a different commit on them"
echo "**********************************************************"
echo ""
read -p "Ready for Android release process (YES/NO)? " CONT
if [[ $CONT =~ ^([Yy][Ee][Ss])$ ]]
then
	Echo "Start Release Android Process"
else
	Echo "... Cancel Release Android Process ..."
	Echo "(Type YES enter if you want to proceed)"
	exit 1
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

if [ ! -z `git rev-parse --verify --quiet $sourceBranch` ]; then
	git branch -D $sourceBranch
fi

if [ ! -z `git rev-parse --verify --quiet $targetBranch` ]; then
	git branch -D $targetBranch
fi

git checkout $sourceBranch

versionFileName="./version"
if [ ! -f $versionFileName ]; then
    echo "$versionFileName file not found! Please inform team"
	exit 1    
fi

echo "Updating version number"

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
git checkout $currentBranchName
git branch -D $targetBranch
git branch -D $temporaryBranch

echo "*************************************"
echo "****** Done updating from $version to $newVersion "
echo "****** Merged $sourceBranch to $targetBranch build"
echo "*************************************"

sh ./scripts/tag-release.sh --noprompt

