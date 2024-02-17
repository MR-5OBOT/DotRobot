#!/usr/bin/bash

# Your Imgur client ID
CLIENT_ID="3c70469d93d12fc"

# Get the image path from the clipboard
IMAGE_PATH=$(wl-paste --no-newline)

# Check if the image path exists
if [[ ! -f "$IMAGE_PATH" ]]; then
    echo "File not found: $IMAGE_PATH"
    exit 1
fi

# Get the image data
IMAGE_DATA=$(base64 -w 0 $IMAGE_PATH)

# Use curl to upload the image to Imgur
RESPONSE=$(curl -X POST -H "Authorization: Client-ID $CLIENT_ID" \
     -F "image=$IMAGE_DATA" https://api.imgur.com/3/image)

# Extract the image URL from the response
IMAGE_URL=$(echo "$RESPONSE" | jq -r '.data.link')

# Print the image URL
echo $IMAGE_URL

# Copy the image URL to the clipboard
echo $IMAGE_URL | wl-copy

