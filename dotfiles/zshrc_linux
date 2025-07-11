# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:/usr/local/bin:$PATH
export PATH=/home/nilclass/.cargo/bin:$HOME/.rye/shims:$PATH

eval "$(starship init zsh)"
eval "$(frum init)"

export GOPATH="$HOME/go"
export PATH="$GOPATH/bin:$PATH"

bindkey -e

# Set-up icons for files/directories in terminal using lsd
alias ls='lsd'
alias l='ls -l'
alias la='ls -a'
alias lla='ls -la'
alias lt='ls --tree'

# Set-up FZF key bindings (CTRL R for fuzzy history finder)
source <(fzf --zsh)

HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt appendhistory
