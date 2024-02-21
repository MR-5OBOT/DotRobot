#!/usr//bin/env bash

FILE_NAME="Screenshots-$(date +%F-%T).png"
FILE_PATH="${HOME}/Pictures/Screenshots/${FILE_NAME}"

grimblast --notify save area "$FILE_PATH"
# notify-send 'Screenshot' -i "${FILE_PATH}" "${FILE_NAME}"
