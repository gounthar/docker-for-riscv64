# Docker development aliases for BananaPi F3 RISC-V
alias dps='docker ps'
alias dpsa='docker ps -a'
alias di='docker images'
alias drmi='docker rmi'
alias dlog='docker logs'
alias dexec='docker exec -it'
alias dbuild='docker build --platform linux/riscv64'
alias dpull='docker pull'
alias drun='docker run --rm -it'
alias driscv='docker run --rm -it riscv64/debian:sid'
alias dclean='docker system prune -f'
alias dmonitor='~/docker-dev/scripts/monitor.sh'
alias dtest='~/docker-dev/scripts/test-docker.sh'
alias denv='source ~/docker-dev/scripts/setup-env.sh'

# Development shortcuts
alias cdmoby='cd ~/docker-dev/moby'
alias cddev='cd ~/docker-dev'
alias logs='cd ~/docker-dev/logs'

# System monitoring
alias temp='cat /sys/class/thermal/thermal_zone0/temp 2>/dev/null | awk "{print \$1/1000\"°C\"}" || echo "N/A"'
alias meminfo='free -h'
alias diskinfo='df -h'
