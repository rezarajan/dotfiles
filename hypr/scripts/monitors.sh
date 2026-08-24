#!/usr/bin/env bash
# Monitor management: the bar chip's state, quick layout presets, and
# persistence of whatever is on screen right now.
#
#   monitors.sh status              waybar JSON for the displays chip
#   monitors.sh list                one line per output, for displays-panel.py
#   monitors.sh apply <preset>      extend-right | extend-left | mirror
#                                   | solo:NAME | on:NAME | off:NAME
#   monitors.sh set NAME mode VAL   "highrr", "preferred", "3440x1440@175"
#   monitors.sh set NAME scale VAL
#   monitors.sh save                persist the live layout (lua/monitors-local.lua)
#   monitors.sh forget              drop that persisted layout
#   monitors.sh gui                 full arrangement GUI, persisting on exit
#
# Everything applies through `hyprctl eval 'hl.monitor{...}'`. Hyprland's
# Lua parser refuses the old route outright — `hyprctl keyword monitor`
# answers "keyword can't work with non-legacy parsers" — which is also
# why nwg-displays cannot drive this setup at all. wdisplays speaks
# zwlr_output_manager_v1 to the compositor instead, so it does work; it
# has no idea about our config though, hence `save` afterwards.
#
# Every apply emits the FULL field set. Monitor rules accumulate: leave
# `mirror` out and an earlier mirror stays in force, silently pinning the
# output on top of its source no matter what `position` says.
set -u

here="$(cd -P "$(dirname "$0")" && pwd)"      # ~/.config/hypr is a symlink
LUA_LOCAL="$(dirname "$here")/lua/monitors-local.lua"

# nf-md-monitor_multiple; $'\U...' keeps this file pure ASCII, which
# matters on the Windows host where the repo is edited
GLYPH_MULTI=$'\U000F037A'

mons() { timeout 3 hyprctl -j monitors all 2>/dev/null; }

notify() {
    command -v notify-send >/dev/null 2>&1 &&
        notify-send -a Displays -i video-display-symbolic "$1" "${2:-}"
}

# Poke the bar so the chip redraws immediately rather than on next poll.
poke() { pkill -SIGRTMIN+6 waybar 2>/dev/null || true; }

# ------------------------------------------------------------------ apply
# Reads newline-separated lua statements on stdin and sends them as one
# chunk, so a multi-output rearrangement lands in a single frame.
send() {
    local chunk
    chunk="$(cat)"
    [ -z "$chunk" ] && return 0
    timeout 5 hyprctl eval "$chunk" >/dev/null 2>&1
    poke
}

# rule <name> <mode> <position> <scale> <mirror> <disabled>
rule() {
    printf 'hl.monitor({ output = "%s", mode = "%s", position = "%s", scale = %s, mirror = "%s", disabled = %s })\n' \
        "$1" "$2" "$3" "$4" "$5" "$6"
}

# Current mode of an enabled output, "highrr" for one that is off (a
# monitor coming back on should not come back at the EDID-preferred
# 60 Hz — that is exactly the trap the shared default used to fall into).
mode_of() {
    mons | jq -r --arg n "$1" '
        .[] | select(.name == $n)
        | if .disabled then "highrr"
          else "\(.width)x\(.height)@\(.refreshRate * 100 | round / 100)" end'
}

scale_of() {
    mons | jq -r --arg n "$1" '.[] | select(.name == $n) | .scale' | head -1
}

pos_of() {
    mons | jq -r --arg n "$1" '.[] | select(.name == $n) | "\(.x)x\(.y)"' | head -1
}

focused() {
    mons | jq -r 'map(select(.focused)) | (.[0].name // empty)'
}

names()    { mons | jq -r '.[].name'; }
enabled()  { mons | jq -r '.[] | select(.disabled | not) | .name'; }

# Refuse to black out the session: an "off" that leaves nothing lit is
# a request to lose your only way of undoing it.
guard_last_on() {
    local victim="$1" left
    left="$(enabled | grep -vx "$victim" | wc -l)"
    if [ "$left" -eq 0 ]; then
        notify "Kept $victim on" "It is the only display left."
        return 1
    fi
    return 0
}

apply() {
    # separate statements on purpose: bash expands every word of a
    # `local a=... b="${a}"` line before assigning any of them, so the
    # back-reference would read an unset name and trip `set -u`
    local preset="${1:-}"
    local target="${preset#*:}"
    local primary first name order
    primary="$(focused)"
    [ -z "$primary" ] && primary="$(enabled | head -1)"

    case "$preset" in
        extend-right|extend-left)
            # Chain every output left-to-right with auto-right; for
            # "extend-left" the focused monitor goes last, which puts all
            # the others to its left without needing any width maths.
            if [ "$preset" = extend-right ]; then
                order="$(printf '%s\n' "$primary"; names | grep -vx "$primary")"
            else
                order="$(names | grep -vx "$primary"; printf '%s\n' "$primary")"
            fi
            first=1
            while IFS= read -r name; do
                [ -z "$name" ] && continue
                if [ "$first" = 1 ]; then
                    rule "$name" "$(mode_of "$name")" "0x0" "$(scale_of "$name")" "" "false"
                    first=0
                else
                    rule "$name" "$(mode_of "$name")" "auto-right" "$(scale_of "$name")" "" "false"
                fi
            done <<< "$order" | send
            ;;
        solo:*)
            names | while IFS= read -r name; do
                [ -z "$name" ] && continue
                if [ "$name" = "$target" ]; then
                    rule "$name" "$(mode_of "$name")" "0x0" "$(scale_of "$name")" "" "false"
                else
                    rule "$name" "$(mode_of "$name")" "auto" "$(scale_of "$name")" "" "true"
                fi
            done | send
            ;;
        on:*)
            rule "$target" "$(mode_of "$target")" "auto-right" "$(scale_of "$target")" "" "false" | send
            ;;
        off:*)
            guard_last_on "$target" || return 1
            rule "$target" "$(mode_of "$target")" "auto" "$(scale_of "$target")" "" "true" | send
            ;;
        *)
            echo "unknown preset: $preset" >&2; return 2 ;;
    esac
}

# `mirror` builds its statements in two pieces, so collect and send them
# together rather than letting the case arm pipe each half separately.
apply_mirror() {
    local primary name
    primary="$(focused)"; [ -z "$primary" ] && primary="$(enabled | head -1)"
    {
        rule "$primary" "$(mode_of "$primary")" "0x0" "$(scale_of "$primary")" "" "false"
        names | grep -vx "$primary" | while IFS= read -r name; do
            [ -z "$name" ] && continue
            rule "$name" "$(mode_of "$name")" "auto" "$(scale_of "$name")" "$primary" "false"
        done
    } | send
}

set_field() {
    local name="$1" field="$2" value="$3"
    local mode scale
    mode="$(mode_of "$name")"; scale="$(scale_of "$name")"
    case "$field" in
        mode)  mode="$value" ;;
        scale) scale="$value" ;;
        *) echo "unknown field: $field" >&2; return 2 ;;
    esac
    # pin the current position: "auto" would re-place the output at the
    # end of the layout, so changing a refresh rate would silently teleport
    # the monitor to the far right of the arrangement
    rule "$name" "$mode" "$(pos_of "$name")" "$scale" "" "false" | send
}

# ------------------------------------------------------------ persistence
save() {
    local tmp="$LUA_LOCAL.tmp"
    {
        echo "-- Persisted monitor layout — generated by scripts/monitors.sh save."
        echo "-- Overwritten wholesale on every save; put hand-written per-machine"
        echo "-- tweaks in lua/local.lua instead, which loads after this one."
        echo "-- Gitignored: every machine has its own outputs."
        echo
        mons | jq -r '
            .[]
            | if .disabled then
                "hl.monitor({ output = \"\(.name)\", disabled = true })"
              else
                "hl.monitor({ output = \"\(.name)\", mode = \"\(.width)x\(.height)@\(.refreshRate * 100 | round / 100)\""
                + ", position = \"\(.x)x\(.y)\", scale = \(.scale)"
                + (if (.mirrorOf // "none") != "none" then ", mirror = \"\(.mirrorOf)\"" else "" end)
                + " })"
              end'
    } > "$tmp" && mv "$tmp" "$LUA_LOCAL"
    notify "Layout saved" "$(enabled | wc -l) display(s) — restored on next login."
}

forget() {
    rm -f "$LUA_LOCAL"
    notify "Layout forgotten" "Displays fall back to the shared defaults."
}

# ------------------------------------------------------------------- gui
gui() {
    if ! command -v wdisplays >/dev/null 2>&1; then
        notify "wdisplays is not installed" \
            "Enable dotfiles.hyprland.packages, or install wdisplays."
        return 1
    fi
    # wdisplays drives the compositor over zwlr_output_manager_v1, which
    # leaves no monitor *rule* behind — a config reload would undo it all.
    # Capture whatever the user settled on once the window closes.
    wdisplays
    save
}

# ---------------------------------------------------------------- status
status() {
    local json
    json="$(mons)"
    [ -z "$json" ] && { echo '{"text":""}'; return; }
    printf '%s' "$json" | jq -c --arg glyph "$GLYPH_MULTI" '
        (map(select(.disabled | not))) as $on
        | length as $connected
        | if $connected <= 1 then
            # single display: the chip is noise, Super+D still opens the panel
            { text: "" }
          else
            { text: "\($glyph) \($on | length)",
              class: "multi",
              tooltip: ((map(
                  "\(.name)  " +
                  (if .disabled then "off"
                   else "\(.width)×\(.height) @ \(.refreshRate | round) Hz" +
                        (if (.mirrorOf // "none") != "none"
                         then "  (mirrors \(.mirrorOf))" else "" end)
                   end)
                ) | join("\n")) + "\nClick: display settings") }
          end'
}

list() {
    mons | jq -c '[ .[] | {
        name, disabled, focused,
        width, height, x, y, scale,
        refresh: (.refreshRate * 100 | round / 100),
        mirrorOf: (.mirrorOf // "none"),
        description,
        modes: .availableModes } ]'
}

case "${1:-status}" in
    status) status ;;
    list)   list ;;
    apply)
        case "${2:-}" in
            mirror) apply_mirror ;;
            *) apply "${2:-}" ;;
        esac ;;
    set)    set_field "${2:?output}" "${3:?field}" "${4:?value}" ;;
    save)   save ;;
    forget) forget ;;
    gui)    gui ;;
    *) echo "usage: monitors.sh status|list|apply|set|save|forget|gui" >&2; exit 2 ;;
esac
