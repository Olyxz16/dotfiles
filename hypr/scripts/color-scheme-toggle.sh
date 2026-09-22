#!/bin/bash

# Toggle GNOME/GTK color-scheme AND Noctalia's dark/light theme mode.
# (Replaced the old wayle-based toggle; Noctalia owns the shell theme now.)

current_scheme=$(gsettings get org.gnome.desktop.interface color-scheme)

if [[ $current_scheme == *"dark"* ]] || [[ $current_scheme == *"Dark"* ]]; then
    gsettings set org.gnome.desktop.interface color-scheme 'prefer-light'
    noctalia msg theme-mode-set light
else
    gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
    noctalia msg theme-mode-set dark
fi