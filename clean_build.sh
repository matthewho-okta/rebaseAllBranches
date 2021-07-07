#!/bin/bash

set -e
HOME='/Users/matthewho'
source $HOME/.zshenv && source $HOME/.zshrc
cd ~/okta/okta-core
ok vpn start
ok mono build -m
ant smoke.tomcat