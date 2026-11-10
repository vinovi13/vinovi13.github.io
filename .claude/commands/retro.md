---
description: Rétrospective de boucle de pilotage en fin de mission
---

Relis la session en cours et la mission (`specs/` si présent, `git log` de la
branche `work/*`).

1. Liste les corrections que Vincent a dû donner, et celles données deux fois.
2. Pour chacune, propose le mécanisme durable le plus déterministe :
   test > hook > checker > règle `CLAUDE.md`/`AGENTS.md` > skill.
   Donne le diff exact proposé.
3. Ajoute les lignes correspondantes dans `docs/agentic/PILOT_LOG.md` avec le
   statut `proposé`.
4. N'applique aucun changement de règle, hook ou skill sans validation.
