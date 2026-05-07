# Homebrew path
if [ -x /opt/homebrew/bin/brew ]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif [ -x /usr/local/bin/brew ]; then
  eval "$(/usr/local/bin/brew shellenv)"
fi

# Default editor
export EDITOR="nvim"
export VISUAL="nvim"

# Starship prompt
eval "$(starship init zsh)"

# Aliases
alias n="nvim"
alias ll="ls -lah"
alias gs="git status"
alias ga="git add"
alias gc="git commit"
alias gp="git push"
alias gl="git log --oneline --graph --decorate"
alias lg="lazygit"

# Better tools
alias cat="bat"
alias ls="eza"

# Zoxide
eval "$(zoxide init zsh)"
