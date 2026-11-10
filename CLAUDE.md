# CLAUDE.md — Portfolio vinovi13.github.io

Routeur court : invariants et renvois. Le détail vit dans les skills et `docs/`.

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

@docs/agentic/PROCESS.md

Outils : `scripts/agent-check.sh` (checkers, `--quick` ou complet) · hooks
`PostToolUse` (secrets/syntaxe du fichier édité) et `Stop` (checkers avant de
rendre la main) · sous-agent `verifier` (vérification inférentielle contre la
spec) · `/spec <mission>` · `/retro` · `scripts/ralph.sh <mission>` (exécution
longue bornée, lancée par Vincent uniquement). Définitions :
`docs/agentic/NOTIONS.md`, à lire à la demande.
