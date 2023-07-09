#!/bin/bash

# this script starts all important user applications,
# and then executes the session manager.

source $HOME/.xsessionrc

# syndaemon -i 1 -t -R -k &

compton -b

# autostart should run all "desktop environment" things like
# power manager, XFCE settings, etc.
dex -av &

exec x-window-manager
