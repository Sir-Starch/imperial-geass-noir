# Imperial Geass Noir prompt profile for zsh.
# Source this late in ~/.zshrc so it can override other prompt themes.

autoload -Uz colors && colors
autoload -Uz add-zsh-hook

export STARSHIP_CONFIG="${STARSHIP_CONFIG:-${HOME}/.config/starship/imperial-geass-noir.toml}"

IGN_BG="%F{235}"
IGN_SURFACE="%F{238}"
IGN_PURPLE="%F{98}"
IGN_CRIMSON="%F{124}"
IGN_GOLD="%F{179}"
IGN_TEXT="%F{254}"
IGN_MUTED="%F{246}"
IGN_RESET="%f%k"

setopt prompt_subst
POWERLEVEL9K_DISABLE_CONFIGURATION_WIZARD=true
POWERLEVEL9K_TRANSIENT_PROMPT=off
POWERLEVEL9K_INSTANT_PROMPT=off

git_branch_ign() {
  command -v git >/dev/null 2>&1 || return 0
  command git symbolic-ref --short HEAD 2>/dev/null || command git rev-parse --short HEAD 2>/dev/null
}

imperial_geass_noir_prompt_left() {
  local branch
  branch="$(git_branch_ign)"
  if [[ -n "${branch}" ]]; then
    print -r -- "${IGN_GOLD}♔${IGN_RESET} ${IGN_TEXT}%n${IGN_MUTED}@%m${IGN_RESET} ${IGN_PURPLE}%~${IGN_RESET} ${IGN_CRIMSON}${branch}${IGN_RESET}"
  else
    print -r -- "${IGN_GOLD}♔${IGN_RESET} ${IGN_TEXT}%n${IGN_MUTED}@%m${IGN_RESET} ${IGN_PURPLE}%~${IGN_RESET}"
  fi
}

imperial_geass_noir_disable_foreign_prompt_hooks() {
  local hook
  local -a kept_pre kept_exec kept_periodic

  for hook in "${precmd_functions[@]}"; do
    case "${hook}" in
      *p9k*|*p10k*|*powerlevel*|*starship*|*spaceship*|*pure_prompt*|*prompt_*_precmd*) ;;
      imperial_geass_noir_precmd) ;;
      *) kept_pre+=("${hook}") ;;
    esac
  done

  for hook in "${preexec_functions[@]}"; do
    case "${hook}" in
      *p9k*|*p10k*|*powerlevel*|*starship*|*spaceship*|*pure_prompt*|*prompt_*_preexec*) ;;
      *) kept_exec+=("${hook}") ;;
    esac
  done

  for hook in "${periodic_functions[@]}"; do
    case "${hook}" in
      *p9k*|*p10k*|*powerlevel*|*starship*|*spaceship*|*pure_prompt*) ;;
      *) kept_periodic+=("${hook}") ;;
    esac
  done

  precmd_functions=("${kept_pre[@]}")
  preexec_functions=("${kept_exec[@]}")
  periodic_functions=("${kept_periodic[@]}")
}

imperial_geass_noir_apply_prompt() {
  unset RPROMPT2 RPS2
  unset POWERLEVEL9K_LEFT_PROMPT_ELEMENTS POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS
  PROMPT='$(imperial_geass_noir_prompt_left)
%F{179}❯%f '
  RPROMPT='%F{246}%*%f'
  PS1="${PROMPT}"
  RPS1="${RPROMPT}"
}

imperial_geass_noir_precmd() {
  imperial_geass_noir_disable_foreign_prompt_hooks
  imperial_geass_noir_apply_prompt
}

imperial_geass_noir_disable_foreign_prompt_hooks
imperial_geass_noir_apply_prompt
add-zsh-hook -d precmd imperial_geass_noir_precmd 2>/dev/null || true
add-zsh-hook precmd imperial_geass_noir_precmd

ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=246'

if typeset -p ZSH_HIGHLIGHT_STYLES >/dev/null 2>&1; then
  ZSH_HIGHLIGHT_STYLES[default]='fg=254'
  ZSH_HIGHLIGHT_STYLES[command]='fg=179'
  ZSH_HIGHLIGHT_STYLES[path]='fg=98'
  ZSH_HIGHLIGHT_STYLES[globbing]='fg=124'
fi
