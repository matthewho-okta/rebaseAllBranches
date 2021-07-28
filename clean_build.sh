#!/bin/bash

set -Eeuo pipefail

errorhandler() {
	osascript -e 'tell app "System Events" to display dialog "Clean build failed. Check build.log for more information."'
	ant smoke.tomcat
}

trap errorhandler ERR

HOME='/Users/matthewho'
source $HOME/.zshenv && source $HOME/.zshrc
cd $HOME/okta/okta-core
ok vpn start
ant smoke.tomcat
stopData
startData
ok mono build -m
ant smoke.tomcat

parent_path=$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )
cd "$parent_path"
printf "\tBuild completed successfully!!! \n" >> cron.log
printf "=================================================================================\n" >> cron.log
osascript -e 'tell app "System Events" to display dialog "Build process completed with exit code 0"'