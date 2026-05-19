# Imperial Geass Noir prompt profile for bash.
# Source this late in ~/.bashrc.

export STARSHIP_CONFIG="${STARSHIP_CONFIG:-${HOME}/.config/starship/imperial-geass-noir.toml}"

__ign_bash_git_branch() {
  command -v git >/dev/null 2>&1 || return 0
  command git symbolic-ref --short HEAD 2>/dev/null || command git rev-parse --short HEAD 2>/dev/null
}

__ign_bash_prompt() {
  local branch
  branch="$(__ign_bash_git_branch)"
  if [[ -n "${branch}" ]]; then
    PS1='\[\e[38;5;179m\]♔\[\e[0m\] \[\e[38;5;254m\]\u\[\e[38;5;246m\]@\h\[\e[0m\] \[\e[38;5;98m\]\w\[\e[0m\] \[\e[38;5;124m\]'"${branch}"'\[\e[0m\]\n\[\e[38;5;179m\]❯\[\e[0m\] '
  else
    PS1='\[\e[38;5;179m\]♔\[\e[0m\] \[\e[38;5;254m\]\u\[\e[38;5;246m\]@\h\[\e[0m\] \[\e[38;5;98m\]\w\[\e[0m\]\n\[\e[38;5;179m\]❯\[\e[0m\] '
  fi
}

case ";${PROMPT_COMMAND:-};" in
  *";__ign_bash_prompt;"*) ;;
  *) PROMPT_COMMAND="__ign_bash_prompt${PROMPT_COMMAND:+; ${PROMPT_COMMAND}}" ;;
esac

__ign_bash_prompt
