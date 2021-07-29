#!/bin/bash

set -Eeuo pipefail

errorhandler() {
	ant smoke.tomcat
	osascript -e 'tell app "System Events" to display dialog "Clean build failed. Check build.log for more information."' &
	exit 1
}

trap errorhandler ERR

HOME='/Users/matthewho'
source $HOME/.zshenv && source $HOME/.zshrc
cd $HOME/okta/okta-core
ok vpn start
ant smoke.tomcat
ok mono infra stop # stopData
ok mono infra create && ok mono infra start # startData
ok mono build -m
ant smoke.tomcat

parent_path=$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )
cd "$parent_path"
printf "\tBuild completed successfully!!! \n" >> cron.log
printf "=================================================================================\n" >> cron.log
osascript -e 'tell app "System Events" to display dialog "Build process completed with exit code 0"'