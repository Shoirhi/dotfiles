# eza
EZA_COMMON=(--icons --git --group-directories-first)
alias ls="eza -l ${EZA_COMMON[*]}"
alias la="eza -la ${EZA_COMMON[*]}"
lt() { eza -la "${EZA_COMMON[@]}" --tree -L "${1:-2}"; }
alias lm="eza -la ${EZA_COMMON[*]} --sort=modified --reverse"
alias lk="eza -la ${EZA_COMMON[*]} --sort=size --reverse"

# bat
alias cat="bat --paging=never"
alias catp="bat --plain --paging=never"

# ripgrep
alias rga="rg --no-ignore --hidden"

# git
alias g="git"
alias gs="git status"
alias ga="git add"
alias gc="git commit"
alias gd="git diff"
alias gds="git diff --staged"
alias gl="git log --oneline --graph -20"
alias gla="git log --oneline --graph --all -30"
alias gp="git push"
alias gpf="git push --force-with-lease"
alias gpl="git pull"
alias gsw="git switch"
alias gsc="git switch -c"
alias grb="git rebase"
alias gst="git stash"
alias gstp="git stash pop"

# zoxide
alias cd="z"

# general
alias reload="source ~/.zshrc"
alias path='echo "$PATH" | tr ":" "\n"'
