#!/usr/bin/env bash
# Boucle Ralph bornée — exécution longue d'une mission spec-driven.
# Usage : scripts/ralph.sh <mission> [max_iterations=20] [budget_usd_par_iteration=3]
#         RALPH_DRY_RUN=1 scripts/ralph.sh <mission>   # vérifie les garde-fous sans lancer l'agent
# Chaque itération : agent sans mémoire → lit specs/<mission>/ → fait UNE tâche → checkers → commit.
# Ne pousse, ne merge et ne déploie JAMAIS.
set -euo pipefail

mission="${1:?usage: scripts/ralph.sh <mission> [max_iter] [budget_usd]}"
max_iter="${2:-20}"
budget="${3:-3}"
root="$(git rev-parse --show-toplevel)"
cd "$root"
spec="specs/$mission"
tasks="$spec/tasks.md"
log="$spec/ralph.log"

die() { echo "ralph: $*" >&2; exit 1; }

branch="$(git rev-parse --abbrev-ref HEAD)"
case "$branch" in
  work/*) ;;
  *) die "branche '$branch' refusée : lancer uniquement sur work/<mission>." ;;
esac
[ -f "$tasks" ] || die "$tasks introuvable (copier specs/_template/)."
grep -qE '^Statut : validé CP1 le [0-9]{4}-[0-9]{2}-[0-9]{2}' "$spec/proposal.md" 2>/dev/null \
  || die "$spec/proposal.md sans ligne 'Statut : validé CP1 le AAAA-MM-JJ' : spec non validée par Vincent."
[ -z "$(git status --porcelain)" ] || die "arbre de travail non propre : commit ou stash d'abord."
[ -x scripts/agent-check.sh ] || die "scripts/agent-check.sh manquant."
command -v claude >/dev/null || die "CLI claude introuvable."

remaining() { grep -cE '^\s*- \[ \]' "$tasks" || true; }

if [ "${RALPH_DRY_RUN:-0}" = "1" ]; then
  echo "ralph: dry-run OK — branche=$branch, tâches restantes=$(remaining), max_iter=$max_iter, budget=$budget USD/itération"
  exit 0
fi

read -r -d '' PROMPT <<EOF || true
Tu exécutes UNE itération de la boucle Ralph pour la mission '$mission'.
Tu n'as aucune mémoire des itérations précédentes : l'état est dans les fichiers.
1. Lis CLAUDE.md, docs/agentic/PROCESS.md, $spec/proposal.md, $spec/design.md (si présent), $tasks, puis 'git log --oneline -15'.
2. Prends la PREMIÈRE tâche non cochée de $tasks. Une seule.
3. TDD : écris le test, constate l'échec, implémente, constate le succès.
4. Lance scripts/agent-check.sh ; il doit être vert.
5. Coche la tâche dans $tasks, puis : git add -A && git commit -m "feat($mission): <tâche>".
6. Si la tâche est bloquée (info manquante, prod, secret, décision), n'écris pas de code :
   ajoute '  - BLOQUÉ: <raison>' sous la tâche, commit, et termine.
Interdits : git push, merge, déploiement, migration de prod, modification de tests existants pour les faire passer.
EOF

fails=0
echo "=== ralph start $(date -Iseconds) mission=$mission max_iter=$max_iter" >> "$log"
for i in $(seq 1 "$max_iter"); do
  left="$(remaining)"
  [ "$left" -eq 0 ] && { echo "ralph: toutes les tâches sont cochées." | tee -a "$log"; break; }
  if grep -q 'BLOQUÉ:' "$tasks"; then echo "ralph: tâche bloquée, arrêt." | tee -a "$log"; break; fi
  echo "--- itération $i/$max_iter, tâches restantes=$left, $(date -Iseconds)" | tee -a "$log"
  printf '%s' "$PROMPT" | timeout 3600 claude -p --permission-mode acceptEdits \
    --max-budget-usd "$budget" --output-format text >> "$log" 2>&1 || echo "ralph: l'itération $i a renvoyé une erreur" | tee -a "$log"
  if scripts/agent-check.sh >> "$log" 2>&1; then
    fails=0
  else
    fails=$((fails+1)); echo "ralph: checkers rouges ($fails/3)" | tee -a "$log"
    [ "$fails" -ge 3 ] && { echo "ralph: 3 échecs consécutifs, arrêt pour revue humaine." | tee -a "$log"; break; }
  fi
done
echo "=== ralph end $(date -Iseconds) restantes=$(remaining)" | tee -a "$log"
echo "Revue : git log --oneline $(git merge-base HEAD origin/main 2>/dev/null || echo HEAD~1)..HEAD ; puis sous-agent verifier ; puis PR."
