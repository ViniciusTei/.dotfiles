# Função para recuperar o nome da branch atual
get_branch_name() {
    # Verifica se o diretório atual é um repositório Git
    if [ -d .git ]; then
        branch_name=$(git rev-parse --abbrev-ref HEAD)
        echo "($branch_name) "
    fi
}

# Função para atualizar o prompt (PS1)
update_prompt() {
    local current_dir="\[\e[1;34m\]\w\[\e[m\] "  # Blue color for the current directory
    local git_branch="\[\e[1;36m\]\$(get_branch_name)\[\e[m\]"        # Get the Git branch name
    local prompt="$current_dir$git_branch$"  # current_dir(branch)$
    PS1=" $prompt "
}

# Execute a função update_prompt sempre que você mudar de diretório
cd() {
    builtin cd "$@"
    update_prompt
}

# Execute a função update_prompt ao iniciar o shell
update_prompt
