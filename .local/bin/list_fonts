#!/usr/bin/env bash

# MR5OBOT script for searching fonts with exact names

read -p "Enter the font name prefix (e.g., IosevkaTerm): " prefix
fc-list | grep -i "$prefix" | awk -F: '{print $2}' | tr ',' '\n' | sed 's/ *//g' | sort -u
