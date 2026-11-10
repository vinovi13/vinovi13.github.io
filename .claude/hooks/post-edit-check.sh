#!/usr/bin/env bash
# Hook PostToolUse (Edit|Write|MultiEdit) — checker déterministe sur le fichier modifié.
# Sortie 2 = Claude reçoit le message sur stderr et doit corriger.
# Ne bloque jamais sur une erreur interne du hook (sortie 0).
set -u
input="$(cat)"
file="$(printf '%s' "$input" | python3 -c 'import sys,json
try:
  d=json.load(sys.stdin); print((d.get("tool_input") or {}).get("file_path",""))
except Exception: print("")' 2>/dev/null)"
[ -n "$file" ] && [ -f "$file" ] || exit 0

problems=""

# 1. Secrets (motifs à haute confiance)
if grep -nE '(sk_live_[0-9A-Za-z]{10,}|rk_live_[0-9A-Za-z]{10,}|whsec_[0-9A-Za-z]{16,}|AKIA[0-9A-Z]{16}|gh[pousr]_[0-9A-Za-z]{30,}|xox[baprs]-[0-9A-Za-z-]{10,}|-----BEGIN [A-Z ]*PRIVATE KEY-----|[0-9]{8,10}:AA[0-9A-Za-z_-]{30,}|eyJ[0-9A-Za-z_-]{10,}\.eyJ[0-9A-Za-z_-]{10,}\.[0-9A-Za-z_-]{10,})' "$file" >/dev/null 2>&1; then
  problems+="SECRET probable dans $file (clé Stripe/AWS/GitHub/Slack/Telegram/JWT/clé privée). Retire-le et utilise une variable d'environnement ou un credential.\n"
fi

# 2. Syntaxe selon le type
case "$file" in
  *.json)
    python3 -c 'import json,sys; json.load(open(sys.argv[1]))' "$file" 2>/tmp/.agent_json_err.$$ \
      || problems+="JSON invalide : $file — $(head -c 300 /tmp/.agent_json_err.$$)\n"
    rm -f /tmp/.agent_json_err.$$ ;;
  *.sh)
    bash -n "$file" 2>/tmp/.agent_sh_err.$$ || problems+="Shell invalide : $file — $(head -c 300 /tmp/.agent_sh_err.$$)\n"
    rm -f /tmp/.agent_sh_err.$$ ;;
  *.py)
    python3 -m py_compile "$file" 2>/tmp/.agent_py_err.$$ || problems+="Python invalide : $file — $(head -c 300 /tmp/.agent_py_err.$$)\n"
    rm -f /tmp/.agent_py_err.$$ ;;
  *.mjs|*.cjs)
    command -v node >/dev/null && { node --check "$file" 2>/tmp/.agent_js_err.$$ || problems+="JS invalide : $file — $(head -c 300 /tmp/.agent_js_err.$$)\n"; rm -f /tmp/.agent_js_err.$$; } ;;
esac

if [ -n "$problems" ]; then
  printf "post-edit-check :\n%b" "$problems" >&2
  exit 2
fi
exit 0
