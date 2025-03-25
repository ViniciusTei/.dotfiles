#!/bin/bash

# Definição de cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

USER=$(git config user.name)

# Mostra uma mensagem lendária ao iniciar
echo -e "${CYAN}🔥 Bem-vindo, $USER! 🔥${NC}"

# Lista as branches locais e permite a seleção interativa com fzf
BRANCH_TO_MERGE=$(git branch | fzf --height 40% --layout=reverse --border | tr -d '[:space:]')

# Verifica se o usuário selecionou uma branch
if [[ -z "$BRANCH_TO_MERGE" ]]; then
    echo -e "${RED}❌ Nenhuma branch selecionada. Saindo...${NC}"
    exit 1
fi

# Obtém a branch atual
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)

# Confirma a operação
echo -e "${WHITE}🚀 Você está na branch: ${CYAN}$CURRENT_BRANCH${NC}"
echo -e "${GREEN}🔀 Deseja fazer merge da branch ${YELLOW}$BRANCH_TO_MERGE${GREEN} para ${CYAN}$CURRENT_BRANCH${GREEN}? (s/n)${NC}"
read -r CONFIRMATION

if [[ "$CONFIRMATION" != "s" ]]; then
    echo -e "${RED}❌ Merge cancelado!${NC}"
    exit 0
fi

# Faz o merge
echo -e "${YELLOW}⚡ Fazendo o merge...${NC}"
git merge "$BRANCH_TO_MERGE"

# Verifica se o merge foi bem-sucedido
if [[ $? -eq 0 ]]; then
    echo -e "${GREEN}✅ Merge realizado com sucesso! ${NC}"
else
    echo -e "${RED}⚠️ Erro ao fazer merge! Verifique conflitos e tente novamente.${NC}"
fi
