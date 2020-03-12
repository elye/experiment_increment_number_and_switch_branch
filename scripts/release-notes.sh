#!/bin/bash

set -e

export MERGE_FORMAT='Merge pull request \#([0-9]*) from'
export PR_FORMAT='\#(\d{1,5})'
export DELIMETER='@@@'
export PR_URL='https://git.realestate.com.au/rca-mobile/rca-android-app/pull/'

if [[ "$#" -ne 2 ]]; then
    echo "Illegal number of parameters"
    echo "Usage: ${0} <git-ref> <git-ref>"
    echo "Example: ${0} 5.36.0 5.37.0"
    exit 1
fi

echo "## Generated release notes"
echo "_These release notes were generated by running: \`${0} ${*}\`_"

# 1) Print merge commits between two git refs with subject and body split by DELIMITER
# 2) Filter to include only messages that have PR numbers
# 3) Markdown format PR number and message
git log "${1}".."${2}" --merges --pretty=format:"%s${DELIMETER}%b" \
 | grep -E "${MERGE_FORMAT}" \
 | perl -n -e '/$ENV{PR_FORMAT}.*$ENV{DELIMETER}(.*)/ && print "- [PR #$1]($ENV{PR_URL}$1) $2\n"'