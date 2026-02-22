# Project navigation aliases
alias be="cd ~/projects/nomap/apps/backend"
alias fe="cd ~/projects/nomap/apps/frontend"
alias docs="cd ~/projects/nomap/docs"

# General aliases
# Note: This may be needed later on, do not delete
alias e="explorer.exe ."
alias ll="ls -alF"
alias la="ls -al"
alias lt="ls -tlr"
alias l="ls -CF"

# Navigation aliases
alias ..='cd ..'
alias ...='cd ../..'

# Passwordless apt (requires sudoers NOPASSWD rule for apt)
alias apt='sudo apt'
alias apt-get='sudo apt-get'

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

# Node/pnpm
alias ns="pnpm start"
alias ni="pnpm install"
alias nd="pnpm run dev"
alias nrs="pnpm run start"
alias nrd="pnpm run dev"
alias nrb="pnpm run build"
alias nrt="pnpm run test"

alias prs="pnpm run start"
alias prd="pnpm run dev"
alias prb="pnpm run build"
alias prt="pnpm run test"

# Custom run scripts
alias init="bash env-init.sh"
alias re="pnpm dev:restart"
alias up='pnpm dev:up && tail -f .dev/fullstack.log'
alias down="pnpm dev:down"

# Docker
alias dc="docker-compose"
alias dcup="docker-compose up -d"
alias dcstop="docker-compose stop"

# Kubernetes
alias k=kubectl
