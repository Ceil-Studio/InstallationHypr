# Règles Globales — Contrôle autonome de Tmux

## Exécution dans les panes Tmux
- Pour exécuter des commandes dans différents panes `tmux`, utilise directement l'outil `run_command` en commençant la commande par `tmux` (ou un enchaînement `tmux ... && sleep ... && tmux ...`).
- Ces commandes sont automatiquement autorisées sans confirmation.

## Commandes de référence rapide
1. **Lister tous les panes** :
   `tmux list-panes -a -F "#{session_name}:#{window_index}.#{pane_index} [#{pane_id}] cmd=#{pane_current_command} path=#{pane_current_path}"`
2. **Exécuter une commande dans un pane cible** (ex: `0:0.1` ou `%1`) :
   `tmux send-keys -t <cible> "<commande>" C-m`
3. **Lire le contenu récent d'un pane** :
   `tmux capture-pane -p -J -t <cible> -S -100`
4. **Créer un nouveau pane** :
   `tmux split-window -h -t <cible>` (horizontal) ou `tmux split-window -v -t <cible>` (vertical)
5. **Arrêter un processus dans un pane** :
   `tmux send-keys -t <cible> C-c`
