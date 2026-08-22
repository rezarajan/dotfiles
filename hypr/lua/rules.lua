-- Window, layer and workspace rules.

-- ------------------------------------------------------------- workspaces
-- Three always-present workspaces, like the KDE session's three desktops.
for ws = 1, 3 do
    hl.workspace_rule({ workspace = tostring(ws), persistent = true })
end

-- ---------------------------------------------------------- window rules

-- Ignore maximize requests (apps stay tiled unless the user says otherwise).
hl.window_rule({
    name = "suppress-maximize",
    match = { class = ".*" },
    suppress_event = "maximize",
})

-- Fullscreen video/meetings keep the screen awake.
hl.window_rule({
    name = "fullscreen-inhibits-idle",
    match = { class = ".*" },
    idle_inhibit = "fullscreen",
})

-- XWayland drag-popup fix (empty class/title floaters must not take focus).
hl.window_rule({
    name = "fix-xwayland-drags",
    match = {
        class = "^$", title = "^$",
        xwayland = true, float = true, fullscreen = false, pin = false,
    },
    no_focus = true,
})

-- Chromium/Electron dropdown bubbles: frameless chip, port of the KWin rule
-- in kde-gruvbox.nix (gruvboxKwinRules).
hl.window_rule({
    name = "browser-bubbles",
    match = {
        class = "^(chromium|chrome|thorium|brave|vivaldi|opera|edge|electron).*",
        title = "^(Chromium|Google Chrome|Thorium|Brave|Vivaldi|Opera|Microsoft Edge|Electron)$",
    },
    float = true,
    border_size = 0,
    rounding = 8,
})

-- Utility dialogs float, centered, sized like plasma applet popups.
local floaters = {
    "org.pulseaudio.pavucontrol", "pavucontrol",
    "nm-connection-editor", "blueman-manager",
    "qalculate-gtk", "org.kde.polkit-kde-authentication-agent-1",
    "hyprland-share-picker",
}
for _, class in ipairs(floaters) do
    hl.window_rule({
        match = { class = "^(" .. class .. ")$" },
        float = true,
        center = true,
        size = { 700, 560 },
    })
end

-- The screenshare picker and polkit prompts must keep focus.
hl.window_rule({
    match = { class = "^(hyprland-share-picker)$" },
    stay_focused = true,
    pin = true,
})
hl.window_rule({
    match = { class = "(pinentry-)(.*)" },
    stay_focused = true,
})

-- Picture-in-picture: pinned to the bottom-right corner on every workspace.
hl.window_rule({
    name = "picture-in-picture",
    match = { title = "^(Picture.in.[Pp]icture)$" },
    float = true,
    pin = true,
    keep_aspect_ratio = true,
    size = { "monitor_w*0.24", "monitor_h*0.24" },
    move = { "monitor_w*0.75-14", "monitor_h*0.74" },
})

-- ----------------------------------------------------------- layer rules
-- Acrylic: blur behind every shell surface; ignore_alpha keeps fully
-- transparent margins from smearing.
for _, ns in ipairs({ "waybar", "rofi", "swaync-control-center",
    "swaync-notification-window", "logout_dialog" }) do
    hl.layer_rule({ match = { namespace = "^(" .. ns .. ")$" }, blur = true, ignore_alpha = 0.28 })
end

-- Screenshot region selection must render instantly.
hl.layer_rule({ match = { namespace = "^(selection)$" }, no_anim = true })
