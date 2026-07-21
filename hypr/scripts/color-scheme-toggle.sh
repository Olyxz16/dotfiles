#!/bin/bash

current_scheme=$(gsettings get org.gnome.desktop.interface color-scheme)

if [[ $current_scheme == *"dark"* ]] || [[ $current_scheme == *"Dark"* ]]; then
    gsettings set org.gnome.desktop.interface color-scheme 'prefer-light'
else 
    gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
fi
