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
        echo -e "${RED} ${branch_name} ${ENDCOLOR} "
      elif git status | grep -q "Changes to be committed"; then
        echo -e "${YELLOW} ${branch_name} ${ENDCOLOR} "
      elif git status | grep -q "Your branch is ahead of"; then
        echo -e " ${branch_name}  "
      elif git status | grep -q "Your branch is behind"; then
        echo -e " ${branch_name}  "
      else
          echo " $branch_name 󱋌 "
      fi
    fi
}

# Função para atualizar o prompt (PS1)
better_prompt() {

    local current_dir="\e[1;40;m\w "  # Blue color for the current directory
    local git_branch="\[\e[1;36m\]\$(get_branch_name)\e\[\e[m\]"        # Get the Git branch name
    local prompt="$current_dir$git_branch \n"  # current_dir(branch)$
    PS1="$prompt "
}

# Funcao para adicionar suggestoes para o comando cd
better_cd() {
  cd $1
  if [ -z $1 ] 
  then 
    select="$(ls -a $pwd | fzf --height 40% --reverse)"
    if [[ -d "$select" ]] 
    then
      cd "$select"
    elif [[ -f "$select" ]] 
    then
      nvim "$select"
    fi
  fi
}

# Execute a função update_prompt sempre que você mudar de diretório
cd() {
    builtin cd "$@"
    better_prompt
}


# Execute ao iniciar o shell
alias cd="better_cd"
better_prompt
