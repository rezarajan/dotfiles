function fastfetch-logo --description 'set the fastfetch greeting logo: text (figlet-rendered) or an ascii-art file'
    switch "$argv[1]"
        case '' --show
            if set -q fastfetch_logo
                echo "logo file: $fastfetch_logo (type: $fastfetch_logo_type)"
                if test "$fastfetch_logo_type" != kitty
                    cat -- $fastfetch_logo 2>/dev/null
                end
            else
                echo "no custom logo set (greeting uses the distro logo)"
            end
        case --clear
            set -eU fastfetch_logo
            set -eU fastfetch_logo_type
            set -eU fastfetch_logo_frames
            set -eU fastfetch_logo_ramp
            echo "custom logo cleared; new shells use the distro logo"
        case '*'
            # a directory = animation frames; png frames flip as kitty
            # graphics, text frames cycle as ascii under the color wave
            if test (count $argv) -eq 1; and test -d "$argv[1]"
                set -l pngs $argv[1]/*.png
                if test (count $pngs) -ge 2
                    set -U fastfetch_logo (path resolve -- $pngs[1])
                    set -U fastfetch_logo_type kittyframes
                    set -U fastfetch_logo_frames (path resolve -- $argv[1])
                    echo "animated image logo set — "(count $pngs)" kitty frames, appears in new shells"
                    return
                end
                set -l files $argv[1]/*
                if test (count $files) -lt 2
                    echo "frames directory needs at least 2 frame files" >&2
                    return 1
                end
                set -U fastfetch_logo (path resolve -- $files[1])
                set -U fastfetch_logo_type file
                set -U fastfetch_logo_frames (path resolve -- $argv[1])
                echo "animated logo set — "(count $files)" frames, appears in new shells"
                return
            end
            set -eU fastfetch_logo_frames
            if test (count $argv) -eq 1; and test -f "$argv[1]"
                # images render via the kitty graphics protocol (static —
                # the color wave only works on ascii glyphs)
                if string match -q 'image/*' -- (file -b --mime-type -- $argv[1])
                    set -U fastfetch_logo (path resolve -- $argv[1])
                    set -U fastfetch_logo_type kitty
                    echo "image logo set — it appears in new shells (kitty graphics, static)"
                    return
                end
                set -U fastfetch_logo (path resolve -- $argv[1])
                set -U fastfetch_logo_type file
            else
                if not command -q figlet
                    echo "figlet is not installed (home-manager: desktop/terminal.nix provides it)" >&2
                    return 1
                end
                mkdir -p ~/.config/fastfetch
                figlet -f small -w 60 -- $argv >~/.config/fastfetch/logo-text.txt
                # keep the logo narrow enough to sit beside the info column;
                # drop to the mini font when the small one runs too wide
                set -l maxw (awk '{ if (length($0) > m) m = length($0) } END { print m + 0 }' <~/.config/fastfetch/logo-text.txt)
                if test $maxw -gt 50
                    figlet -f mini -w 60 -- $argv >~/.config/fastfetch/logo-text.txt
                end
                set -U fastfetch_logo ~/.config/fastfetch/logo-text.txt
                set -U fastfetch_logo_type file
            end
            echo "logo set — it appears in new shells (adaptive: narrower windows fall back automatically)"
    end
end
