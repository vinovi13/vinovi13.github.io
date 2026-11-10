#!/usr/bin/env bash
# Hook Stop — empêche l'agent de s'arrêter avec des changements qui cassent les checkers.
# Sortie 2 = l'agent reprend la main avec la sortie du checker sur stderr.
# Anti-boucle : si stop_hook_active=true (déjà relancé une fois par ce hook), on laisse s'arrêter.
set -u
input="$(cat)"
active="$(printf '%s' "$input" | python3 -c 'import sys,json
try: print(str(json.load(sys.stdin).get("stop_hook_active",False)).lower())
except Exception: print("false")' 2>/dev/null)"
[ "$active" = "true" ] && exit 0

root="${CLAUDE_PROJECT_DIR:-$(git rev-parse --show-toplevel 2>/dev/null)}"
[ -n "$root" ] && cd "$root" || exit 0
[ -x scripts/agent-check.sh ] || exit 0

# Rien à vérifier si l'arbre est propre
[ -z "$(git status --porcelain 2>/dev/null)" ] && exit 0

out="$(timeout 300 scripts/agent-check.sh --quick 2>&1)"
code=$?
if [ $code -ne 0 ]; then
  printf "stop-check : scripts/agent-check.sh --quick a échoué (code %s). Corrige avant de terminer, ou explique pourquoi l'échec est hors périmètre.\n%s\n" "$code" "$(printf '%s' "$out" | tail -n 60)" >&2
  exit 2
fi
exit 0
