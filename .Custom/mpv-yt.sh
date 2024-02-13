#!/bin/bash

# Get the YouTube link
youtube_link=$(wl-paste)

# Start the video with MPV
mpv --fs "$youtube_link"

