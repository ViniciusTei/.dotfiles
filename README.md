# .dotfiles

Este repositório contém as configurações para o meu ambiente de desenvolvimento, incluindo ajustes para i3, tmux e NeoVim. 
Essas configurações estao sendo otimizadas para fornecer um ambiente de desenvolvimento consistente, e ainda é um trabalho em progresso.

## Estrutura do Repositório

- **/i3**: Configurações do i3 Window Manager.
- **/tmux**: Configurações do tmux.
- **/nvim**: Configurações do NeoVim.
- **/scripts**: Configurações iniciais do sistema.

## Configurações Incluídas

### i3 Window Manager

Dentro da pasta `/i3`, você encontrará:

- `config`: Arquivo de configuração principal do i3.

### tmux

A pasta `/tmux` contém:

- `tmux.conf`: Configurações do tmux.

### NeoVim

Dentro de `/nvim`:

- `init.lua`: Arquivo de configuração principal do NeoVim.
- `plugins`: Lista de plugins do NeoVim.

## Como Usar

1. Clone este repositório em sua máquina local.
   ```bash
     git clone https://github.com/ViniciusTei/.dotfiles.git
     cd .dotfiles
     stow .
   ```
2. Lembre de instalar o stow
3. Rode o arquivo `setup.sh`
4. Verifique a instalacao
