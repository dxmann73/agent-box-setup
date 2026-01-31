# Project navigation aliases
alias pr="cd /home/dave/dev/mhb/prima"
alias bl="cd /home/dave/dev/blocks"
alias be="cd /home/dave/dev/blocks/blocks-be"
alias fe="cd /home/dave/dev/blocks/blocks-fe"
alias docs="cd /home/dave/dev/blocks/blocks-docs" 

# General aliases
alias e="explorer.exe ."
alias ll="ls -l"
alias la="ls -al"
alias lt="ls -tlr"

# Navigation aliases
alias ..='cd ..'
alias ...='cd ../..'

# Git aliases (shell level)
alias gs='git status'
alias gd='git diff'
alias gl='git log --oneline -20'
alias gp='git pull'
alias pf="git push --force"
alias gc="git clone"

# Claude aliases
alias c='claude'
alias cc='claude --continue'

# Maven build
alias mci="mvn clean install $@"
alias mcit="mvn clean install -DskipITs=false $@"
alias mcd="mvn clean install -DskipTests $@"
export MAVEN_OPTS=-Xmx1024m

# Node/npm/pnpm
alias npm=pnpm
alias ns="pnpm start"
alias ni="pnpm install"
alias nrs="pnpm run start"
alias nrb="pnpm run build"
alias nrt="pnpm run test"

alias prs="pnpm run start"
alias prb="pnpm run build"

# Custom run scripts
alias init="bash env-init.sh"
alias re="bash env-recreate.sh"
alias up="bash env-start.sh"
alias down="bash env-stop.sh"

# Docker
alias dc="docker-compose"
alias dcup="docker-compose up -d"
alias dcstop="docker-compose stop"

# Kubernetes
alias k=kubectl

