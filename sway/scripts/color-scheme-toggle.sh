#!/bin/bash

current_scheme=$(gsettings get org.gnome.desktop.interface color-scheme)

if [[ $current_scheme == *"dark"* ]] || [[ $current_scheme == *"Dark"* ]]; then
    gsettings set org.gnome.desktop.interface color-scheme 'prefer-light'
fi

if [[ $current_scheme == *"light"* ]] || [[ $current_scheme == *"Light"* ]]; then
    gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
fi
