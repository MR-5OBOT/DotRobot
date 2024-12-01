#!/usr/bin/env bash

# Function to extract YouTube video ID from a URL
extract_video_id() {
  local url="$1"
  local video_id

  # Extract video ID from different YouTube URL formats
  if [[ "$url" =~ ^https://www\.youtube\.com/watch\?v=([^&]+) ]]; then
    video_id="${BASH_REMATCH[1]}"
  elif [[ "$url" =~ ^https://youtu\.be/([^?]+) ]]; then
    video_id="${BASH_REMATCH[1]}"
  else
    echo "Invalid YouTube URL."
    exit 1
  fi

  echo "$video_id"
}

# Function to generate thumbnail URL from the video ID
get_thumbnail_url() {
  local video_id="$1"
  local thumbnail_url="https://img.youtube.com/vi/$video_id/maxresdefault.jpg"
  echo "$thumbnail_url"
}

# Main script logic with user input
read -p "Enter the YouTube URL: " youtube_url

video_id=$(extract_video_id "$youtube_url")

if [[ -n "$video_id" ]]; then
  thumbnail_url=$(get_thumbnail_url "$video_id")
  echo "Thumbnail URL: $thumbnail_url"
else
  echo "Failed to extract video ID."
fi

wl-copy $thumbnail_url
