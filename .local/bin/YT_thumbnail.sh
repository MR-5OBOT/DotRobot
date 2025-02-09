#!/usr/bin/env bash

# Prompt the user for a YouTube video URL
read -p "Enter YouTube video URL: " yt_link

# Function to extract video ID from YouTube URL
get_video_id() {
    local url=$1
    # Regular expression to match YouTube video IDs
    if [[ $url =~ (https?://(www\.)?youtube\.com/(watch\?v=|v/)|https?://(www\.)?youtu\.be/)([a-zA-Z0-9_-]+) ]]; then
        echo "${BASH_REMATCH[5]}"  # Return the matched video ID
    else
        echo "Invalid URL"
        exit 1
    fi
}

# Function to generate the thumbnail URL
get_video_thumbnail() {
    local video_id=$1
    # Standard YouTube thumbnail URL format
    echo "https://img.youtube.com/vi/$video_id/maxresdefault.jpg"
}

# Get the video ID
video_id=$(get_video_id "$yt_link")

# Get the thumbnail URL
thumbnail_url=$(get_video_thumbnail "$video_id")

# Output the thumbnail URL
echo "Thumbnail URL: $thumbnail_url"

wl-copy $thumbnail_url
