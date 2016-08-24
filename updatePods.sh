#!/bin/bash
#用于更新组件
mainDir=$(cd `dirname $0`; pwd)
cd $mainDir

podfile="Podfile"
podfile_lock="Podfile.lock"

if [ ! -f "$podfile" ]; then
    echo "No Podfile file, Please check it again."
#   touch "$podfile"
    exit 1
fi

if [ ! -f "$podfile_lock" ]; then
    echo "No Podfile.lock file, will pod install --no-repo-update."
    pod install --no-repo-update
else
    echo "Found Podfile.lock file, will pod update --no-repo-update."
    pod update --no-repo-update
fi

#pod update --verbose --no-repo-update
#pod install --no-repo-update
#pod update --no-repo-update
#pod update
