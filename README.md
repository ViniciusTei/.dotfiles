# .dotfiles

Este repositório contém as configurações para o meu ambiente de desenvolvimento, incluindo ajustes para i3, tmux e NeoVim. 
Essas configurações estao sendo otimizadas para fornecer um ambiente de desenvolvimento consistente, e ainda é um trabalho em progresso.

## Estrutura do Repositório

Cada diretório de nível superior é um pacote do stow. Os arquivos dentro seguem o caminho onde devem aparecer em relação a `$HOME`:

| Diretorio                  | Alvo                 |
|----------------------------|----------------------|
| `nvim/.config/nvim/`       | `~/.config/nvim/`    |
| `i3/.config/i3/`           | `~/.config/i3/`      |
| `polybar/.config/polybar/` | `~/.config/polybar/` |
| `rofi/.config/rofi/`       | `~/.config/rofi/`    |
| `tmux/.tmux.conf`          | `~/.tmux.conf`       |
| `scripts/.bash_aliases`    | `~/.bash_aliases`    |
| `scripts/.scripts/`        | `~/.scripts/`        |

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

### Polybar (`polybar/.config/polybar/`)

- `config.ini` — todas as definições de barra e módulos
- `launch-polybar.sh` — chamado pelo i3 na inicialização; itera os monitores conectados e inicia uma barra por monitor. Inclui uma solução alternativa para posicionamento inferior com `override-redirect`.

### Scripts (`scripts/.scripts/`)

Scripts relevantes ao fazer alterações:

- `bash.sh` — sourced pelo `.bashrc`; define o prompt com consciência de git e uma substituição de `cd` aprimorada por `fzf`
- `battery-notify.sh` — daemon; executado na inicialização do i3
- `monitor-hotplug.sh` — invocado por regra udev; lida com conexão/desconexão de exibição (executa como root e depois reinvoca como usuário)
- `btctl.sh` — wrapper de bluetooth (veja `scripts/btctl.md` para uso)
- `aireview.sh` / `gitmerge.sh` — ferramentas de fluxo de trabalho git assistidas por IA

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

Você pode utilizar o comando abaixo para fazer o setup automaticamente

```bash
curl -o- https://raw.githubusercontent.com/ViniciusTei/.dotfiles/master/install.sh | bash
```
