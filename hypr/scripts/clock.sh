#!/usr/bin/env bash
# waybar custom/clock: time in the bar, dual-calendar tooltip.
# CALENDARS controls what the tooltip shows, in order.
set -u
CALENDARS="gregorian hijri"

text="$(date +%H:%M)"
lines=""

for cal_name in $CALENDARS; do
    case "$cal_name" in
        gregorian)
            lines="${lines}<b>$(date +"%A, %B %-d %Y")</b>\n"
            ;;
        hijri)
            # tabular (arithmetic) Islamic calendar — civil epoch; can be
            # ±1 day from the observational Umm al-Qura calendar
            hijri="$(python3 - <<'PYEOF'
import datetime
MONTHS = ["Muharram", "Safar", "Rabi' al-Awwal", "Rabi' al-Thani",
          "Jumada al-Ula", "Jumada al-Akhirah", "Rajab", "Sha'ban",
          "Ramadan", "Shawwal", "Dhu al-Qi'dah", "Dhu al-Hijjah"]
LEAP = {2, 5, 7, 10, 13, 16, 18, 21, 24, 26, 29}
jdn = datetime.date.today().toordinal() + 1721425
days = jdn - 1948440
cyc, d = divmod(days, 10631)
y = 0
while True:
    ylen = 355 if (y % 30) + 1 in LEAP else 354
    if d < ylen:
        break
    d -= ylen
    y += 1
year = cyc * 30 + y + 1
m = 0
while True:
    mlen = 30 if m % 2 == 0 else 29
    if m == 11 and (year - 1) % 30 + 1 in LEAP:
        mlen = 30
    if d < mlen:
        break
    d -= mlen
    m += 1
print(f"{d + 1} {MONTHS[m]} {year} AH")
PYEOF
)" || hijri=""
            [ -n "$hijri" ] && lines="${lines}${hijri}\n"
            ;;
    esac
done

# hover stays brief (dates only) — the click opens the calendar panel
tooltip="$(printf '%b' "$lines")"
tooltip="${tooltip%\\n}"

jq -cn --arg t "$text" --arg tt "$tooltip" '{text: $t, tooltip: ($tt | rtrimstr("\n"))}'
