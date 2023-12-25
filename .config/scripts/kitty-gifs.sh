#!/bin/bash

# Directory containing your GIFs
gif_directory="~/MR-5OBOT/DotRoboT/.config/kitty/gifs/"

# Check if the directory exists
if [[ ! -d $gif_directory ]]; then
 echo "Directory $gif_directory does not exist."
 exit 1
fi

# Select a random GIF
random_gif=$(ls $gif_directory | sort -R | head -n 1)

# Full path to the random GIF
full_path="$gif_directory$random_gif"

# Display the GIF
kitty +kitten icat --transfer-mode=file --place=top-right $full_path

