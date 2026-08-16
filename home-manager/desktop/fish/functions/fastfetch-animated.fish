function fastfetch-animated --description 'fastfetch greeting: size-adaptive logo with a continual gruvbox color wave'
    # Anything unusual -> plain fastfetch. The animation rewrites the logo
    # in place with cursor movement, which needs a real tty.
    if not isatty stdout; or not isatty stdin; or test "$TERM" = dumb
        fastfetch
        return
    end

    set -l sz (stty size 2>/dev/null | string split ' ')
    if test (count $sz) -ne 2
        fastfetch
        return
    end

    # image logo: kitty graphics can't be color-waved or safely piped
    # through the capture/redraw machinery — render straight to the tty
    # (fastfetch does its own width truncation there) and stay static
    if test "$fastfetch_logo_type" = kitty; and test -f "$fastfetch_logo"
        set -l w 36
        set -q fastfetch_logo_width; and set w $fastfetch_logo_width
        set -l avail (math $sz[2] - 24)
        test $w -gt $avail; and set w $avail
        if test $w -ge 12; and test $sz[1] -ge 22
            fastfetch --logo-type kitty-direct --logo $fastfetch_logo --logo-width $w
            return
        end
        # window too narrow for the image: fall through to the ascii chain
    end

    # animated image logo (kittyframes): reserve the logo box with a
    # blank spacer file so fastfetch lays the info out beside it, then
    # flip pre-rendered png frames into the box via kitty placements
    __fastfetch_img_setup $sz[1] $sz[2]

    if not __fastfetch_greeting_render $sz[1] $sz[2]
        __fastfetch_greeting_cleanup
        return
    end

    __fastfetch_img_place_initial

    # nothing animatable at this size: leave the static greeting and give
    # the prompt back immediately
    if test $__ff_H -lt 4; and test "$__ff_img" != 1
        __fastfetch_greeting_cleanup
        return
    end

    # gruvbox green -> aqua -> yellow-green ramp, palindromic for a
    # seamless cycle (18 steps); a custom ramp (universal var, list of
    # 'r;g;b' entries) overrides it — e.g. ivory-gold for the keyblade
    set -l ramp '66;123;88' '79;134;94' '91;146;100' '104;157;106' \
        '117;169;112' '129;180;118' '142;192;124' '156;190;95' \
        '170;189;67' '184;187;38' '170;189;67' '156;190;95' \
        '142;192;124' '129;180;118' '117;169;112' '104;157;106' \
        '91;146;100' '79;134;94'
    if set -q fastfetch_logo_ramp; and test (count $fastfetch_logo_ramp) -ge 2
        set ramp $fastfetch_logo_ramp
    end
    set -l nramp (count $ramp)

    __fastfetch_load_frames

    # Wave forever while the shell is idle; the first keypress (checked
    # with bash's zero-timeout read) stops the wave and stays buffered,
    # so it lands in the prompt as normal typing. Each frame is wrapped
    # in synchronized output (?2026) so redraws never flicker.
    # Non-canonical mode makes a lone keypress readable immediately
    # (canonical ttys only report input on Enter); no-echo keeps the
    # keypress from printing outside the prompt. Restored right after.
    set -l saved_stty (stty -g)
    stty -icanon -echo
    set -l t 0
    set -l cursz "$sz"

    while not bash -c 'read -t 0'
        # live resize: reflow breaks in-place cursor math, so re-render
        # the whole greeting at whatever variant now fits
        set -l now (stty size | string split ' ')
        if test "$now" != "$cursz"
            set cursz "$now"
            __fastfetch_img_setup $now[1] $now[2]
            printf '\e[2J\e[H'
            # the clear discards kitty image data in ghostty, not just
            # placements — force a full retransmit
            set -g __ff_imgsent ''
            __fastfetch_greeting_render $now[1] $now[2]
            __fastfetch_load_frames
            __fastfetch_img_place_initial
        end

        # image mode: flip kitty frames at half the tick rate
        if test "$__ff_img" = 1; and test "$__ff_imgn" -ge 2
            set -l k (math "(($t - $t % 2) / 2) % $__ff_imgn")
            if test $k -ne $__ff_imgk
                printf '\e[?2026h\e[%dA\r' $__ff_T
                printf '\e_Ga=p,i=%d,p=1,c=%d,r=%d,C=1,q=2\e\\' (math 4200 + $k) $__ff_imgc $__ff_imgr
                printf '\e[%dB\r\e[?2026l' $__ff_T
                set -g __ff_imgk $k
            end
        else if test $__ff_H -ge 4
            # glyph animation: cycle art frames at half the wave tick
            set -l cur $__ff_raw
            if test $__ff_nf -ge 2
                set -l k (math "($t - $t % 2) / 2 % $__ff_nf")
                set cur $__ff_frames[(math "$k * $__ff_H + 1")..(math "($k + 1) * $__ff_H")]
            end
            set -l f (math "$t % $nramp")
            printf '\e[?2026h\e[%dA\r' $__ff_T
            set -l i 0
            for l in $cur
                set -l idx (math "($i + 2 * $nramp - $f) % $nramp + 1")
                printf '\e[38;2;%sm%s\e[0m\n' $ramp[$idx] $l
                set i (math $i + 1)
            end
            if test $__ff_T -gt $__ff_H
                printf '\e[%dB' (math $__ff_T - $__ff_H)
            end
            printf '\r\e[?2026l'
        end
        set t (math $t + 1)
        sleep 0.07
    end

    stty $saved_stty

    # hand the logo back to fastfetch's own colors (text modes only; in
    # image mode the last-placed frame simply stays visible)
    if test $__ff_H -ge 4; and test "$__ff_img" != 1
        printf '\e[?2026h\e[%dA\r' $__ff_T
        printf '%s\n' $__ff_logo
        if test $__ff_T -gt $__ff_H
            printf '\e[%dB' (math $__ff_T - $__ff_H)
        end
        printf '\r\e[?2026l'
    end
    __fastfetch_greeting_cleanup
end

function __fastfetch_greeting_render --argument-names rows cols --description 'internal: print the widest fastfetch variant that fits, set __ff_* state'
    # fastfetch truncates info lines to the terminal width itself when it
    # writes to a tty, but our captures go through a pipe and lose that —
    # so info lines are re-truncated ANSI-aware to the window width, and
    # a variant "fits" when its logo leaves the info column a workable
    # minimum. Lines never wrap, keeping the in-place cursor math exact.
    set -l min_info 24

    for kind in imgspacer file default small none
        set -l args
        switch $kind
            case imgspacer
                # blank box for the kitty-frames image (set up beforehand)
                if set -q __ff_spacer; and test -f "$__ff_spacer"
                    set args --logo-type file --logo $__ff_spacer
                else
                    continue
                end
            case file
                # only ascii-art files; image logos are handled (or ruled
                # out for this window size) before the chain runs
                if set -q fastfetch_logo; and test -f "$fastfetch_logo"; and not string match -qr '^kitty' -- "$fastfetch_logo_type"
                    set args --logo-type file --logo $fastfetch_logo
                else
                    continue
                end
            case default
                # distro logo (no extra args)
            case small
                set args -l cachyos_small
            case none
                set args -l none
        end

        set -l logo
        set -l raw
        if test $kind != none
            set logo (fastfetch --pipe false -s none $args)
            while test (count $logo) -gt 0; and test -z (string replace -ra '\e\[[0-9;]*m' '' -- $logo[-1] | string trim)
                set -e logo[-1]
            end
            set -l lw 0
            for l in $logo
                set -a raw (string replace -ra '\e\[[0-9;]*m' '' -- $l)
                set -l w (string length -- $raw[-1])
                test $w -gt $lw; and set lw $w
            end
            if test (math $lw + $min_info) -gt $cols
                continue
            end
        end

        set -l full (fastfetch --pipe false $args | python3 -c "
import sys, re
w = int(sys.argv[1])
esc = re.compile('\x1b\\\\[[0-9;]*m')
for line in sys.stdin:
    line = line.rstrip('\n')
    out = []
    vis = 0
    i = 0
    while i < len(line):
        m = esc.match(line, i)
        if m:
            out.append(m.group())
            i = m.end()
            continue
        if vis < w:
            out.append(line[i])
        vis += 1
        i += 1
    if vis > w:
        out.append('\x1b[m')
    sys.stdout.write(''.join(out) + '\n')
" $cols)
        set -l T (count $full)
        if test (math $T + 2) -gt $rows
            continue
        end

        set -g __ff_full $full
        set -g __ff_T $T
        set -g __ff_logo $logo
        set -g __ff_raw $raw
        set -g __ff_H (count $raw)
        if test $kind = imgspacer
            set -g __ff_img 1
        else
            set -g __ff_img 0
        end
        printf '%s\n' $__ff_full
        return 0
    end

    # nothing fits even without a logo: last resort, let it wrap
    set -g __ff_H 0
    set -g __ff_img 0
    fastfetch
    return 1
end

function __fastfetch_img_setup --argument-names rows cols --description 'internal: prepare spacer + geometry for kitty-frame image logos'
    set -e __ff_spacer
    if test "$fastfetch_logo_type" != kittyframes; or not test -d "$fastfetch_logo_frames"
        return 0
    end
    set -l pngs $fastfetch_logo_frames/*.png
    if test (count $pngs) -lt 2
        return 0
    end

    # box height 20 rows; width follows the frame aspect ratio using the
    # terminal's real cell pixel size (TIOCGWINSZ), so the image isn't
    # squashed regardless of font metrics
    set -l R 20
    set -l C (python3 -c "
import fcntl, math, struct, sys, termios
rows, cols, xp, yp = struct.unpack('HHHH', fcntl.ioctl(0, termios.TIOCGWINSZ, bytes(8)))
R = int(sys.argv[1])
aspect = float(sys.argv[2])
cw = xp / cols if cols and xp else 9.0
ch = yp / rows if rows and yp else 19.0
print(math.ceil(R * ch * aspect / cw))
" $R 0.46875 2>/dev/null)
    if not string match -qr '^[0-9]+$' -- "$C"
        return 0
    end
    if test (math $C + 24) -gt $cols
        return 0
    end

    set -l dir $XDG_RUNTIME_DIR
    test -z "$dir"; and set dir /tmp
    set -l spacer $dir/fastfetch-spacer-$C-$R.txt
    if not test -f $spacer
        set -l line (string repeat -n $C ' ')
        begin
            for i in (seq $R)
                echo $line
            end
        end >$spacer
    end
    set -g __ff_spacer $spacer
    set -g __ff_imgc $C
    set -g __ff_imgr $R
    set -g __ff_imgfiles $pngs
    return 0
end

function __fastfetch_img_place_initial --description 'internal: transmit kitty frames once and place frame 0'
    if test "$__ff_img" != 1
        return 0
    end
    if test "$__ff_imgsent" != "$fastfetch_logo_frames"
        set -l i 0
        for f in $__ff_imgfiles
            python3 ~/.config/fastfetch/kitty_transmit.py (math 4200 + $i) $f
            set i (math $i + 1)
        end
        set -g __ff_imgsent $fastfetch_logo_frames
    end
    set -g __ff_imgn (count $__ff_imgfiles)
    set -g __ff_imgk 0
    printf '\e[?2026h\e[%dA\r' $__ff_T
    printf '\e_Ga=p,i=4200,p=1,c=%d,r=%d,C=1,q=2\e\\' $__ff_imgc $__ff_imgr
    printf '\e[%dB\r\e[?2026l' $__ff_T
    return 0
end

function __fastfetch_load_frames --description 'internal: load equal-sized ascii animation frames into __ff_frames'
    set -g __ff_frames
    set -g __ff_nf 0
    if not set -q fastfetch_logo_frames; or not test -d "$fastfetch_logo_frames"
        return 0
    end
    if test "$fastfetch_logo_type" = kittyframes
        return 0
    end
    # frames only make sense while the custom logo variant is on screen
    if test $__ff_H -lt 4
        return 0
    end

    set -l fw 0
    for l in $__ff_raw
        set -l w (string length -- $l)
        test $w -gt $fw; and set fw $w
    end

    set -l loaded
    set -l n 0
    for file in $fastfetch_logo_frames/*
        set -l lines (cat $file)
        if test (count $lines) -ne $__ff_H
            # mismatched frame: glyph animation off, wave still runs
            return 0
        end
        for l in $lines
            # pad to a common width so shorter frame lines fully
            # overwrite the previous frame's glyphs
            set -a loaded (string pad -r -w $fw -- $l)
        end
        set n (math $n + 1)
    end
    if test $n -ge 2
        set -g __ff_frames $loaded
        set -g __ff_nf $n
    end
    return 0
end

function __fastfetch_greeting_cleanup
    set -e __ff_full
    set -e __ff_logo
    set -e __ff_raw
    set -e __ff_T
    set -e __ff_H
    set -e __ff_frames
    set -e __ff_nf
    set -e __ff_spacer
    set -e __ff_img
    set -e __ff_imgc
    set -e __ff_imgr
    set -e __ff_imgn
    set -e __ff_imgk
    set -e __ff_imgfiles
    set -e __ff_imgsent
    return 0
end
