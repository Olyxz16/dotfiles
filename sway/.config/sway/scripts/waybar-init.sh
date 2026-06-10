val=$(gsettings get org.gnome.desktop.interface color-scheme)
[[ "$val" == *"dark"* ]] \
  && cp ~/.config/waybar/themes/rose-pine-moon.css ~/.config/waybar/style.css \
  || cp ~/.config/waybar/themes/rose-pine-dawn.css ~/.config/waybar/style.css
