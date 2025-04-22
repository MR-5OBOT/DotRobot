#!/usr/bin/bash

# Text colors for better user interface
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored text
print_color() {
    printf "${1}%s${NC}\n" "$2"
}

# Function to validate URL
validate_url() {
    if [[ ! $1 =~ ^https?:// ]]; then
        print_color "$RED" "Error: Please enter a valid URL starting with http:// or https://"
        return 1
    fi
    return 0
}

# Print banner
clear
print_color "$BLUE" "================================"
print_color "$BLUE" "       Video Downloader"
print_color "$BLUE" "================================"

# Choose download type
while true; do
    print_color "$GREEN" "Choose download type:"
    print_color "$GREEN" "1. Single video"
    print_color "$GREEN" "2. Playlist"
    read -p "Enter your choice (1/2): " download_type
    
    case $download_type in
        1) playlist="single"; break;;
        2) playlist="playlist"; break;;
        *) print_color "$RED" "Invalid choice. Please enter 1 or 2.";;
    esac
done

# Choose format
while true; do
    print_color "$GREEN" "Choose format:"
    print_color "$GREEN" "1. MP4 (video)"
    print_color "$GREEN" "2. MP3 (audio only)"
    read -p "Enter your choice (1/2): " format_choice
    
    case $format_choice in
        1) 
            format="mp4"
            # Quality options for MP4
            print_color "$GREEN" "Choose video quality:"
            print_color "$GREEN" "1. Best quality (up to 4K)"
            print_color "$GREEN" "2. 1080p"
            print_color "$GREEN" "3. 720p"
            print_color "$GREEN" "4. 480p"
            read -p "Enter your choice (1-4): " quality_choice
            
            case $quality_choice in
                1) quality="bv*+ba/b";;
                2) quality="bv*[height<=1080]+ba/b";;
                3) quality="bv*[height<=720]+ba/b";;
                4) quality="bv*[height<=480]+ba/b";;
                *) 
                    print_color "$RED" "Invalid choice. Defaulting to 1080p."
                    quality="bv*[height<=1080]+ba/b"
                    ;;
            esac
            break
            ;;
        2) 
            format="mp3"
            quality="ba/b"
            break
            ;;
        *) print_color "$RED" "Invalid choice. Please enter 1 or 2.";;
    esac
done

# Get video URL
while true; do
    read -p "Enter video URL: " url
    if validate_url "$url"; then
        break
    fi
done

# Create output directory if it doesn't exist
# output_dir="downloads"
# mkdir -p "$output_dir"

# Set output template based on format
if [ "$format" = "mp3" ]; then
    output_template="%(title)s.%(ext)s"
    # Additional options for MP3 conversion
    additional_opts="-x --audio-format mp3 --audio-quality 0"
else
    output_template="/%(title)s.%(ext)s"
    additional_opts=""
fi

# Download the video(s)
print_color "$BLUE" "Starting download..."
if [ "$playlist" = "single" ]; then
    yt-dlp --no-playlist \
           -o "$output_template" \
           -f "$quality" \
           $additional_opts \
           --embed-thumbnail \
           --embed-metadata \
           "$url"
else
    yt-dlp --yes-playlist \
           -o "$output_template" \
           -f "$quality" \
           $additional_opts \
           --embed-thumbnail \
           --embed-metadata \
           "$url"
fi

# Check if download was successful
if [ $? -eq 0 ]; then
    print_color "$GREEN" "Download completed successfully!"
else
    print_color "$RED" "An error occurred during download"
fi
