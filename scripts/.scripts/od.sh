#!/usr/bin/env bash

#
# Diretórios que não devem aparecer na busca
#
OD_IGNORE=(
    node_modules
    .git
    dist
    build
    coverage
    .next
    .output
    .cache
    .parcel-cache
    .vite
    target
    vendor
    .idea
    .vscode
    __python__
)

#
# Navega para um projeto usando fzf
#
od() {
    local dir
    local find_cmd

    find_cmd=(
        find
        "$HOME/Documents"
        "$HOME/Documentos"
        -maxdepth 4
    )

    # Ignora os diretórios da lista acima
    find_cmd+=( \( )

    local first=true
    for d in "${OD_IGNORE[@]}"; do
        if [ "$first" = true ]; then
            first=false
        else
            find_cmd+=( -o )
        fi
        find_cmd+=( -name "$d" )
    done

    find_cmd+=( \) -prune -o -type d -print )

    dir=$(
        "${find_cmd[@]}" 2>/dev/null |
        sed "s|^$HOME/||" |
        sort |
        fzf \
            --height=40% \
            --layout=reverse \
            --border \
            --prompt="Projetos > "
    )

    [[ -n "$dir" ]] && cd "$HOME/$dir"
}

od
