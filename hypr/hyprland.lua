-- Hyprland Lua config migration (translated from hyprland.conf)
-- See https://wiki.hypr.land/Configuring/Start/

------------------
---- MONITORS ----
------------------

-- Hyprland was auto-scaling eDP-1 to 1.5x, which made everything look
-- oversized compared to Sway. Force a 1x scale for the built-in display.
hl.monitor({
    output   = "eDP-1",
    mode     = "preferred",
    position = "auto",
    scale    = "1",
})
-- Fall back to auto scale for any other monitor you may plug in.
hl.monitor({
    output   = "",
    mode     = "preferred",
    position = "auto",
    scale    = "auto",
})


---------------------
---- MY PROGRAMS ----
---------------------

local terminal    = "ptyxis"
local fileManager = "dolphin"
local menu        = "fuzzel"


-------------------
---- AUTOSTART ----
-------------------

hl.on("hyprland.start", function ()
    -- Idle + lock are handled by Noctalia's native Idle service and lock screen.
    hl.exec_cmd("noctalia")
end)


-------------------------------
---- ENVIRONMENT VARIABLES ----
-------------------------------

hl.env("XCURSOR_SIZE", "16")
hl.env("HYPRCURSOR_SIZE", "16")
-- Qt app theming via qt6ct (Noctalia themes Qt apps through qt6ct)
hl.env("QT_QPA_PLATFORMTHEME", "qt6ct")


-----------------------
---- LOOK AND FEEL ----
-----------------------

-- Gruvbox
hl.config({
    general = {
        gaps_in  = 0,
        gaps_out = 0,

        border_size = 0,

        col = {
            active_border   = { colors = { "rgba(fe8019ee)", "rgba(fabd2fee)" }, angle = 45 },
            inactive_border = "rgba(3c3836aa)",
        },

        resize_on_border = false,
        allow_tearing    = false,

        layout = "dwindle",
    },

    decoration = {
        rounding       = 10,
        rounding_power = 1,

        active_opacity   = 1.0,
        inactive_opacity = 1.0,

        shadow = {
            enabled      = true,
            range        = 4,
            render_power = 3,
            color        = 0xee1a1a1a,
        },

        blur = {
            enabled  = true,
            size     = 3,
            passes   = 1,
            vibrancy = 0.1696,
        },
    },
})

-- Curves and animations (speeds preserved from hyprland.conf; unit is deciseconds)
hl.curve("easeOutQuint",   { type = "bezier", points = { {0.23, 1}, {0.32, 1} } })
hl.curve("easeInOutCubic", { type = "bezier", points = { {0.65, 0.05}, {0.36, 1} } })
hl.curve("linear",         { type = "bezier", points = { {0, 0}, {1, 1} } })
hl.curve("almostLinear",   { type = "bezier", points = { {0.5, 0.5}, {0.75, 1} } })
hl.curve("quick",          { type = "bezier", points = { {0.15, 0}, {0.1, 1} } })

hl.animation({ leaf = "global",         enabled = true, speed = 5,      bezier = "default" })
hl.animation({ leaf = "border",         enabled = true, speed = 2.7,    bezier = "easeOutQuint" })
hl.animation({ leaf = "windows",        enabled = true, speed = 2.4,    bezier = "easeOutQuint" })
hl.animation({ leaf = "windowsIn",      enabled = true, speed = 1.2,    bezier = "easeOutQuint", style = "popin 87%" })
hl.animation({ leaf = "windowsOut",     enabled = true, speed = 0.5,    bezier = "almostLinear", style = "popin 87%" })
hl.animation({ leaf = "fadeIn",         enabled = true, speed = 0.85,   bezier = "almostLinear" })
hl.animation({ leaf = "fadeOut",        enabled = true, speed = 0.75,   bezier = "almostLinear" })
hl.animation({ leaf = "fade",           enabled = true, speed = 1.5,    bezier = "quick" })
hl.animation({ leaf = "layers",         enabled = true, speed = 1.9,    bezier = "easeOutQuint" })
hl.animation({ leaf = "layersIn",       enabled = true, speed = 2.0,    bezier = "easeOutQuint", style = "fade" })
hl.animation({ leaf = "layersOut",      enabled = true, speed = 0.75,   bezier = "linear",       style = "fade" })
hl.animation({ leaf = "fadeLayersIn",   enabled = true, speed = 0.9,    bezier = "almostLinear" })
hl.animation({ leaf = "fadeLayersOut",  enabled = true, speed = 0.7,    bezier = "almostLinear" })
hl.animation({ leaf = "workspaces",     enabled = true, speed = 1.6,    bezier = "easeOutQuint", style = "slide" })
hl.animation({ leaf = "workspacesIn",   enabled = true, speed = 1.6,    bezier = "easeOutQuint", style = "slide" })
hl.animation({ leaf = "workspacesOut",  enabled = true, speed = 1.8,    bezier = "easeOutQuint", style = "slide" })
hl.animation({ leaf = "zoomFactor",     enabled = true, speed = 3.5,    bezier = "quick" })

hl.config({
    master = {
        new_status = "master",
    },
})

hl.config({
    misc = {
        force_default_wallpaper = 0,
        disable_hyprland_logo   = true,
        disable_splash_rendering = true,
    },
})


---------------
---- INPUT ----
---------------

hl.config({
    input = {
        kb_layout  = "fr",
        kb_variant = "",
        kb_model   = "",
        kb_options = "",
        kb_rules   = "",

        follow_mouse = 1,

        sensitivity = 0,

        touchpad = {
            natural_scroll = true,
        },
    },
})

hl.gesture({
    fingers = 3,
    direction = "horizontal",
    action = "workspace",
})

-- Example per-device config
hl.device({
    name        = "epic-mouse-v1",
    sensitivity = -0.5,
})


---------------------
---- KEYBINDINGS ----
---------------------

local mainMod = "SUPER"

-- Noctalia IPC (control-center is on SUPER+comma so SUPER+S stays on scratchpad)
local noct = "noctalia msg "

-- Core binds
hl.bind(mainMod .. " + Return",  hl.dsp.exec_cmd(terminal))
hl.bind(mainMod .. " + SHIFT + Q", hl.dsp.window.close())
hl.bind(mainMod .. " + SHIFT + E",
    hl.dsp.exec_cmd("command -v hyprshutdown >/dev/null 2>&1 && hyprshutdown || hyprctl dispatch exit"))
hl.bind(mainMod .. " + M", hl.dsp.exec_cmd("$HOME/.config/hypr/scripts/toggle-thunderbird.sh"))
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd(fileManager))
hl.bind(mainMod .. " + SHIFT + space", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + D", hl.dsp.exec_cmd(menu))

-- Noctalia shell / panels
hl.bind(mainMod .. " + space", hl.dsp.exec_cmd(noct .. "panel-toggle launcher"))
hl.bind(mainMod .. " + comma", hl.dsp.exec_cmd(noct .. "panel-toggle control-center"))
hl.bind(mainMod .. " + period", hl.dsp.exec_cmd(noct .. "settings-toggle"))
hl.bind("ALT + Tab", hl.dsp.exec_cmd(noct .. "window-switcher"))

-- Move focus with mainMod + arrow keys
hl.bind(mainMod .. " + left",  hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + right", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + up",    hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + down",  hl.dsp.focus({ direction = "down" }))

-- Move windows with mainMod + SHIFT + hjkl
hl.bind(mainMod .. " + SHIFT + h", hl.dsp.exec_cmd("hyprctl dispatch movewindow l"))
hl.bind(mainMod .. " + SHIFT + j", hl.dsp.exec_cmd("hyprctl dispatch movewindow d"))
hl.bind(mainMod .. " + SHIFT + k", hl.dsp.exec_cmd("hyprctl dispatch movewindow u"))
hl.bind(mainMod .. " + SHIFT + l", hl.dsp.exec_cmd("hyprctl dispatch movewindow r"))

-- Switch workspaces with mainMod + [1-0] and move windows with mainMod + SHIFT + [1-0]
-- AZERTY top-row key names (preserved from hyprland.conf)
local wsKeys = { "ampersand", "eacute", "quotedbl", "apostrophe", "parenleft", "minus", "egrave", "underscore", "ccedilla", "agrave" }
for i, key in ipairs(wsKeys) do
    hl.bind(mainMod .. " + " .. key,         hl.dsp.focus({ workspace = i }))
    hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
end

-- Example special workspace (scratchpad) -- SUPER+S stays here
hl.bind(mainMod .. " + S",         hl.dsp.workspace.toggle_special("magic"))
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.window.move({ workspace = "special:magic" }))

-- Lock with Noctalia's native lock screen (SUPER+L)
hl.bind(mainMod .. " + L", hl.dsp.exec_cmd("noctalia msg session lock"), { locked = true })

-- Fullscreen
hl.bind(mainMod .. " + F", hl.dsp.exec_cmd("hyprctl dispatch fullscreen 0"))

-- Move/resize windows with mainMod + LMB/RMB and dragging
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- Laptop multimedia keys for volume and LCD brightness
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),      { locked = true, repeating = true })
hl.bind("XF86AudioMute",        hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),     { locked = true, repeating = true })
hl.bind("XF86AudioMicMute",     hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),   { locked = true, repeating = true })
hl.bind("XF86MonBrightnessUp",  hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%+"),                  { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown",hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%-"),                  { locked = true, repeating = true })

-- Screenshot
hl.bind("Print", hl.dsp.exec_cmd("grimshot copy anything"), { locked = true, repeating = true })

-- Color scheme toggle: syncs GNOME color-scheme + Noctalia dark/light theme
hl.bind(mainMod .. " + F3", hl.dsp.exec_cmd("$HOME/.config/hypr/scripts/color-scheme-toggle.sh"))

-- Requires playerctl
hl.bind("XF86AudioNext",  hl.dsp.exec_cmd("playerctl next"),       { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPlay",  hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPrev",  hl.dsp.exec_cmd("playerctl previous"),   { locked = true })

-- Lock on lid close, wake display on lid open
hl.bind("switch:on:Lid Switch",  hl.dsp.exec_cmd("loginctl lock-session"), { locked = true })
hl.bind("switch:off:Lid Switch", hl.dsp.exec_cmd("hyprctl dispatch dpms on"), { locked = true })


--------------------------------
---- WINDOWS AND WORKSPACES ----
--------------------------------

hl.window_rule({
    name  = "suppress-maximize-events",
    match = { class = ".*" },
    suppress_event = "maximize",
})

hl.window_rule({
    name  = "fix-xwayland-drags",
    match = {
        class      = "^$",
        title      = "^$",
        xwayland   = true,
        float      = true,
        fullscreen = false,
        pin        = false,
    },
    no_focus = true,
})

hl.window_rule({
    name  = "move-hyprland-run",
    match = { class = "hyprland-run" },
    move  = "20 monitor_h-120",
    float = true,
})

-- Float these apps by default
hl.window_rule({ name = "float-proton-authenticator", match = { class = "^proton-authenticator$" }, float = true, center = true })
hl.window_rule({ name = "float-proton-pass",          match = { class = "^me\\.proton\\.Pass$" },    float = true, center = true })
hl.window_rule({ name = "float-bitwarden",            match = { class = "^Bitwarden$" },            float = true, center = true })
hl.window_rule({ name = "float-zapzap",               match = { class = "^com\\.rtosta\\.zapzap$" }, float = true, center = true })
hl.window_rule({ name = "float-thunderbird",          match = { class = "^org\\.mozilla\\.thunderbird$" },
                 float = true, center = true, size = { "monitor_w*0.5", "monitor_h*0.9" } })

-- Assign apps to specific workspaces
hl.window_rule({ name = "assign-discord-to-ws2", match = { class = "^discord$" },   workspace = 2 })
hl.window_rule({ name = "assign-notesnook-to-ws3", match = { class = "^Notesnook$" }, workspace = 3 })

-- Noctalia settings window should float
hl.window_rule({
    name  = "float-noctalia-settings",
    match = { class = "dev.noctalia.Noctalia" },
    float = true,
    size  = { 1080, 920 },
})

-- Noctalia: show only occupied workspaces in the workspace indicator,
-- so empty workspaces are not permanently pinned (removed persistent rules).
-- Blur for Noctalia surfaces, disable Hyprland layer animations for them
hl.layer_rule({
    name  = "noctalia",
    match = { namespace = "^noctalia-(bar-.+|notification|dock|panel|attached-panel|osd|window-switcher)$" },
    no_anim  = true,
    ignore_alpha = 0.5,
    blur       = true,
    blur_popups = true,
})
