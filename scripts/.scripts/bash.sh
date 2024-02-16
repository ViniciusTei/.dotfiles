# Função para verificar se um diretório ou seus pais pertencem a um repositório Git
is_inside_git_repo() {
    local dir="$PWD"

    while [ "$dir" != "/" ]; do
        if [ -d "$dir/.git" ]; then
            return 0 # Dentro de um repositório Git
        fi
        dir=$(dirname "$dir")
    done

    return 1 # Não está dentro de um repositório Git
}

# Função para recuperar o nome da branch atual
get_branch_name() {

    RED="\e[91m"
    YELLOW="\e[93m"
    ENDCOLOR="\e[0m"

    # Verifica se o diretório atual pertence a um repositório Git
    if is_inside_git_repo; then
      branch_name=$(git rev-parse --abbrev-ref HEAD)
      if git status | grep -q "Changes not staged for commit"; then
        echo -e "${RED}󱓊 ${branch_name}${ENDCOLOR} "
      elif git status | grep -q "Changes to be committed"; then
        echo -e "${YELLOW}󱓏 ${branch_name}${ENDCOLOR} "
      else
          echo " $branch_name "
      fi
    fi
}

# Função para atualizar o prompt (PS1)
update_prompt() {

    local current_dir="\e[1;40;1m\w "  # Blue color for the current directory
    local git_branch="\[\e[1;36m\]\$(get_branch_name)\e\[\e[m\]"        # Get the Git branch name
    local prompt="$current_dir$git_branch \n"  # current_dir(branch)$
    PS1="$prompt "
}

# Execute a função update_prompt sempre que você mudar de diretório
cd() {
    builtin cd "$@"
    update_prompt
}

# Execute a função update_prompt ao iniciar o shell
update_prompt
