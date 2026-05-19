# Imperial Geass Noir prompt profile for fish.

set -gx STARSHIP_CONFIG "$HOME/.config/starship/imperial-geass-noir.toml"

function __ign_fish_git_branch
    command git symbolic-ref --short HEAD 2>/dev/null
    or command git rev-parse --short HEAD 2>/dev/null
end

function fish_prompt
    set -l last_status $status
    set -l branch (__ign_fish_git_branch)

    set_color brblack
    printf ''
    set_color yellow
    printf '♔ '
    set_color normal
    set_color white
    printf '%s' (whoami)
    set_color brblack
    printf '@%s ' (prompt_hostname)
    set_color magenta
    printf '%s' (prompt_pwd)
    if test -n "$branch"
        set_color red
        printf ' %s' "$branch"
    end
    printf '\n'

    if test $last_status -eq 0
        set_color yellow
    else
        set_color red
    end
    printf '❯ '
    set_color normal
end

function fish_right_prompt
    set_color brblack
    date '+%H:%M'
    set_color normal
end
