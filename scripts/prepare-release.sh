#!/usr/bin/env bash
set -euo pipefail

export MEME=0

branchName=`git rev-parse --abbrev-ref HEAD`
if [ "$branchName" != "master" ]
then
	echo "Error: You are currently on $branchName branch"
	echo "       Please checkout master branch"
	exit 1
else
	echo "Ok: You are on master branch"
fi

echo "...Now pulling latest change on master branch.. wait..."
git pull

if [ -z "$(git status --porcelain)" ]; then 
  	echo "Ok: Your master is clean"
else 
	echo "Error: You have uncommited change on master"
	echo "       Please stash them or reset them"
	exit 1
fi

if [ -z "$(git status -sb | grep ahead)" ]; then
	echo "Ok: Your master is sync with remote"
else
	echo "Error: Your local master is ahead of remote"
	echo "       Please sync with remote master"
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

echo "Merge master to release"
export GIT_MERGE_AUTOEDIT=no

git checkout release
git merge master
git commit -a --allow-empty -m "merge develop for PlayStore release"
git push

