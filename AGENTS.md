# AGENTS.md — Portfolio vinovi13.github.io

Règles pour Codex et tout agent autre que Claude Code. Lire aussi `CLAUDE.md`.

## Contexte du dépôt

- Portfolio **public** de Vincent (GitHub Pages) : `index.html`, CV PDF FR/EN,
  `media/`. Merger sur `main` = publication immédiate.
- Rien de privé : aucun secret, aucune donnée client, aucune URL d'admin.
- Ne jamais employer le titre « ingénieur » (pas de diplôme d'ingénieur).
- Aucun chiffre non mesuré ni témoignage inventé.
- Contrôle : `scripts/agent-check.sh` (HTML bien formé, liens locaux, secrets).

## Git — obligatoire

Chaque mission :
1. `git fetch --all --prune`, `git status` propre, `main` = `origin/main`
   (sinon STOP et signaler).
2. `backup/stable` créée ou avancée **uniquement en début de mission** sur le
   SHA validé de `main` ; jamais modifiée ensuite, jamais supprimée.
3. `work/<mission>` créée depuis ce même SHA ; tout le travail y va.
4. Un changement validé = un commit (`feat|fix|chore|sec|docs|test: …`).
5. Jamais de `git push --force`, jamais de travail direct sur `main`.
6. **Aucun merge vers `main` ni déploiement sans validation explicite de
   Vincent.**
7. Ne jamais commiter `.env`, `*.pem`, clés, tokens, credentials.

## Méthode agentique (obligatoire, v1.0)

Avant toute mission : lire et appliquer `docs/agentic/PROCESS.md` (calibrage,
spec et points de contrôle, TDD, vérification, livraison, boucle de pilotage).
Définitions des notions : `docs/agentic/NOTIONS.md`, à la demande.

Codex n'exécute pas les hooks Claude Code. Il applique donc à la main ce
qu'ils automatisent :
- après chaque modification et avant de rendre la main :
  `scripts/agent-check.sh --quick` ; avant une PR : `scripts/agent-check.sh` ;
- vérification inférentielle : relire le diff contre `specs/<mission>/` en
  suivant `.claude/agents/verifier.md` et joindre le verdict à la PR ;
- aucune tâche déclarée terminée sans la sortie du checker à l'appui.

Spec-driven : modèle dans `specs/_template/`. Exécution longue :
`scripts/ralph.sh` (branche `work/*` et spec validée CP1 obligatoires,
jamais de push, merge ou déploiement).

Tout nouveau projet applique ce process dès sa création : kit canonique et
bootstrap dans `vinovi13/aperfectjobforme` → `agent-library/agentic-kit/`
(README). Une évolution du process se fait dans le kit, puis est redéployée
dans chaque dépôt.
