#!/bin/bash

killall mako
pkill mako
sleep 0.1
mako -c ~/.config/hypr/mako/config &
