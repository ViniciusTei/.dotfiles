btctl - wrapper para bluetoothctl

Instalação
- Copiar scripts/.scripts/btctl.sh para ~/.scripts/btctl.sh (ou usar stow)
- Tornar executável: chmod +x ~/.scripts/btctl.sh
- (Opcional) adicionar alias: alias btctl='~/.scripts/btctl.sh' no ~/.bash_aliases

Uso
btctl <comando>

Comandos:
  power on|off     - Ligar/desligar o adaptador Bluetooth
  list             - Listar dispositivos conhecidos (nome apenas)
  scan [secs]      - Scannear por dispositivos por N segundos e listar
  connected        - Listar dispositivos atualmente conectados
  pair [--scan]    - Parear dispositivo selecionado (opcionalmente faz scan antes)
  remove           - Desparear/remover dispositivo
  help             - Mostrar ajuda

Observações
- O script mostra apenas os nomes para o usuário. O MAC é usado internamente para conectar/parear/remover.
- Em caso de nomes duplicados, selecione pelo índice exibido.
- Recomenda-se ter fzf instalado para seleção interativa aprimorada.
