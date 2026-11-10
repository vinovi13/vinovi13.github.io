# Process agentique — obligatoire (v1.0)

S'applique à Claude Code et Codex, sur chaque mission. Définitions détaillées :
`docs/agentic/NOTIONS.md` (lire à la demande, pas systématiquement).
En cas de conflit, les règles du `CLAUDE.md` / `AGENTS.md` du dépôt priment
(Git, prod, secrets, déploiement).

## 1. Calibrer la mission

- **Simple** (≤ 1 fichier ou correctif évident) : pas de spec. Étapes 4 à 7.
- **Standard** (plusieurs fichiers, comportement nouveau) : spec courte
  (`proposal.md` + `tasks.md`), CP1 validé, puis étapes 4 à 7.
- **Longue / déléguée** (feature complète, plusieurs sessions) : spec complète
  (`proposal.md`, `design.md`, `tasks.md`), CP1 + CP2 validés, puis exécution
  par tâches ou `scripts/ralph.sh`.

## 2. Contexte

- Lire `CLAUDE.md` / `AGENTS.md`, puis seulement les skills et docs utiles.
- Mission en cours ? Lire `specs/<mission>/tasks.md` et `git log` avant tout.
- Recherche large → sous-agent ; ne ramener que la conclusion.

## 3. Spec (CP1, CP2)

- Copier `specs/_template/` vers `specs/<mission>/`.
- `proposal.md` : problème, résultat attendu, hors périmètre, **critères
  d'acceptation vérifiables**. STOP → validation de Vincent (CP1).
- `design.md` + `tasks.md` (missions non triviales). STOP → validation (CP2).
- Une tâche = un changement vérifiable = un commit.

## 4. Implémenter en TDD

- Rouge : écrire le test, le lancer, **montrer l'échec**.
- Vert : code minimal qui passe. Refactor ensuite.
- Bug : test de régression qui échoue avant le correctif. Toujours.
- Ne jamais affaiblir ou supprimer un test pour passer au vert.
- Non testable unitairement : contrôle réel documenté (curl, SQL, capture).

## 5. Vérifier (CP3)

1. `scripts/agent-check.sh` vert (les hooks le lancent aussi automatiquement).
2. Missions standard et longues : sous-agent `verifier` avec la spec et le
   diff → `PASS` exigé. `FAIL` : corriger et re-soumettre, 3 tours max, puis
   escalader à Vincent.
3. Cocher la tâche dans `tasks.md`, commit sur `work/<mission>` avec les
   lignes `Rouge: …` (échec constaté avant le code) et `Vert: …` dans le message.

## 6. Livrer (CP4, CP5)

- PR vers `main` avec : lien spec, sortie des checkers, verdict `verifier`,
  risques et rollback.
- Merge et déploiement : **uniquement sur validation explicite de Vincent**.

## 7. Boucle de pilotage

- Correction donnée deux fois → entrée dans `docs/agentic/PILOT_LOG.md` et
  proposition de mécanisme durable (test > hook > règle > skill).
- Fin de mission : `/retro`, propositions soumises à validation.

## Interdits

- Déclarer « terminé » sans sortie de checker à l'appui.
- Lancer `ralph.sh` hors d'une branche `work/*` ou sans spec validée.
- Laisser un agent autonome pousser, merger, migrer ou déployer.
