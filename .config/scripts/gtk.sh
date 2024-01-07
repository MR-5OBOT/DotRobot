#!/bin/sh

gnome_schema="org.gnome.desktop.interface"

gsettings set "$gnome_schema" gtk-theme "paradise"
gsettings set "$gnome_schema" icon-theme "Gruvbox Plus Dark"
gsettings set "$gnome_schema" cursor-theme "Volantes Light Cursors"
gsettings set "$gnome_schema" font-name "operator-caska Bold Italic 11"

gsettings set org.gnome.desktop.interface color-scheme prefer-dark
