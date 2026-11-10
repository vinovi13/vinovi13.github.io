# Journal de pilotage

Une ligne par correction donnée **deux fois** à un agent. Objectif : ne plus
jamais la redonner. Mécanisme par ordre de préférence : test > hook > checker >
règle `CLAUDE.md`/`AGENTS.md` > skill.

| Date | Correction répétée | Mécanisme retenu | Fichier modifié | Statut |
|---|---|---|---|---|
| 2026-11-10 | (exemple) L'agent annonce « terminé » sans tests | Hook `Stop` + `agent-check.sh` | `.claude/hooks/stop-check.sh` | en place |
