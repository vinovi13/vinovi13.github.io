# Bibliothèque commune de scripts/agent-check.sh (sourcée, pas exécutée).
# Fournit : MODE (quick|full), CHANGED (fichiers modifiés), step, secret_scan, json_check, finish.
set -u
MODE="full"
[ "${1:-}" = "--quick" ] && MODE="quick"
ROOT="$(git rev-parse --show-toplevel)"
cd "$ROOT"
FAILED=0
SKIPPED=""

base_ref() { git rev-parse --verify -q origin/main >/dev/null && echo origin/main || echo HEAD; }
if [ "$MODE" = "quick" ]; then
  CHANGED="$( { git diff --name-only HEAD; git diff --name-only --cached; git ls-files --others --exclude-standard; } 2>/dev/null | sort -u)"
else
  CHANGED="$( { git diff --name-only "$(base_ref)"...HEAD 2>/dev/null; git diff --name-only HEAD; git ls-files --others --exclude-standard; } | sort -u)"
fi
EXISTING=""
for f in $CHANGED; do [ -f "$f" ] && EXISTING+="$f"$'\n'; done
CHANGED="$EXISTING"

step() { # step "<libellé>" <commande...>
  local label="$1"; shift
  echo "▶ $label"
  if "$@"; then echo "  ✔ $label"; else echo "  ✘ $label"; FAILED=1; fi
}
skip() { echo "  ⏭  $1"; SKIPPED+="$1; "; }
changed_match() { printf '%s' "$CHANGED" | grep -E "$1" || true; }

SECRET_RE='(sk_live_[0-9A-Za-z]{10,}|rk_live_[0-9A-Za-z]{10,}|whsec_[0-9A-Za-z]{16,}|AKIA[0-9A-Z]{16}|gh[pousr]_[0-9A-Za-z]{30,}|xox[baprs]-[0-9A-Za-z-]{10,}|-----BEGIN [A-Z ]*PRIVATE KEY-----|[0-9]{8,10}:AA[0-9A-Za-z_-]{30,}|eyJ[0-9A-Za-z_-]{10,}\.eyJ[0-9A-Za-z_-]{10,}\.[0-9A-Za-z_-]{10,})'
secret_scan() { # fichiers modifiés uniquement ; binaires ignorés
  local hits=""
  for f in $CHANGED; do
    case "$f" in *.png|*.jpg|*.jpeg|*.webp|*.gif|*.pdf|*.mp4|*.webm|*.woff*|*.ico|*.ods|*.zip) continue;; esac
    grep -IlE "$SECRET_RE" "$f" >/dev/null 2>&1 && hits+="$f "
  done
  for f in $CHANGED; do
    case "$f" in .env|.env.*|*.pem|*.key) hits+="$f(fichier-sensible) ";; esac
  done
  [ -z "$hits" ] || { echo "    secrets/fichiers sensibles : $hits"; return 1; }
}
json_check() {
  local bad=""
  for f in $(changed_match '\.json$'); do
    python3 -c 'import json,sys; json.load(open(sys.argv[1]))' "$f" 2>/dev/null || bad+="$f "
  done
  [ -z "$bad" ] || { echo "    JSON invalide : $bad"; return 1; }
}
shell_check() {
  local bad=""
  for f in $(changed_match '\.sh$'); do bash -n "$f" 2>/dev/null || bad+="$f "; done
  [ -z "$bad" ] || { echo "    shell invalide : $bad"; return 1; }
}
finish() {
  echo
  [ -n "$SKIPPED" ] && echo "Étapes sautées : $SKIPPED"
  if [ "$FAILED" -ne 0 ]; then echo "agent-check ($MODE) : ÉCHEC"; exit 1; fi
  echo "agent-check ($MODE) : OK"; exit 0
}
