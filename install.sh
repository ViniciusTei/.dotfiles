#!/bin/bash

# Define uma função para exibir mensagens de erro e sair
function error_exit {
    echo "[ERRO] $1"
    exit 1
}

echo "Clonando o repositório .dotfiles..."
git clone https://github.com/ViniciusTei/.dotfiles.git || error_exit "Falha ao clonar o repositório. Verifique a URL e sua conexão com a internet."

# Verifica se o diretório foi clonado com sucesso
if [ ! -d ".dotfiles" ]; then
    error_exit "O diretório '.dotfiles' não foi encontrado após o clone."
fi

cd .dotfiles/scripts/.scripts || error_exit "Falha ao acessar o diretório '.dotfiles/scripts/.scripts'. Verifique a estrutura do repositório."

echo "Executando o script setup.sh..."
if ! ./setup.sh; then
    error_exit "O script setup.sh encontrou um erro durante a execução."
fi

echo "Setup concluído com sucesso!"

