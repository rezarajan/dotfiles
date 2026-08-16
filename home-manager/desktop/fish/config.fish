source /usr/share/cachyos-fish-config/cachyos-config.fish

# overwrite greeting: fastfetch with a gruvbox color wave over the logo
# (must come after the cachyos source above, which defines its own).
# Only in ghostty — IDE/embedded terminals get a bare, instant prompt.
function fish_greeting
    if set -q GHOSTTY_RESOURCES_DIR; or test "$TERM_PROGRAM" = ghostty
        fastfetch-animated
    end
end

zoxide init fish | source

export EDITOR=nvim

# Added by LM Studio CLI (lms)
set -gx PATH $PATH /home/cascadura/.lmstudio/bin
# End of LM Studio CLI section

set -gx PATH $PATH /home/cascadura/.local/bin
