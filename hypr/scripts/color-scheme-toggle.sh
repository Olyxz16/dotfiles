#!/bin/bash

current_scheme=$(gsettings get org.gnome.desktop.interface color-scheme)
wayle_dir=$HOME/.config/wayle/themes

if [[ $current_scheme == *"dark"* ]] || [[ $current_scheme == *"Dark"* ]]; then
    gsettings set org.gnome.desktop.interface color-scheme 'prefer-light'
    cp $wayle_dir/gruvbox-light.toml $wayle_dir/current.toml
    wayle panel restart
else 
    gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
    cp $wayle_dir/gruvbox-dark.toml $wayle_dir/current.toml
    wayle panel restart
fi
