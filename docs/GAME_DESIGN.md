# Game Design Document — RPG Barbare

## Concept
Jeu de survie et construction de royaume en top-down pixel art. Le joueur incarne un barbare qui part de rien et doit construire un royaume à partir d'une cahute isolée, en recrutant ou capturant des PNJ rencontrés dans la forêt.

---

## Ressources

| Ressource | Icône | Source principale | Consommation |
|---|---|---|---|
| `food` | 🌾 | Agriculteurs, cueillette | Habitants (-1/hab/min) |
| `wood` | 🪵 | Bûcherons, coupe manuelle | Construction |
| `stone` | 🪨 | Mineurs, ramassage | Construction avancée |
| `gold` | 💰 | Forgerons, échanges | Déblocage, commerce |
| `faith` | 🕯️ | Prêtres, temples | Événements religieux |

**Règle de survie** : Si `food = 0`, moral des habitants baisse de -5%/min → à 0% moral, les habitants fuient.

---

## Métiers

| Métier | Bâtiment requis | Ressource produite | Production/min | Max travailleurs |
|---|---|---|---|---|
| Agriculteur | Ferme | food | 2 | 4 |
| Bûcheron | Scierie | wood | 1.5 | 3 |
| Forgeron | Forge | gold | 0.5 | 2 |
| Garde | Caserne | (protection) | — | 6 |
| Prêtre | Temple | faith | 1 | 2 |
| Mineur | Mine | stone | 1 | 3 |

---

## Bâtiments

| Bâtiment | Coût | Débloque | Bonus |
|---|---|---|---|
| Cahute (départ) | Gratuit | — | Stockage x1 |
| Ferme | 15 wood, 5 stone | Agriculteur | +20% food |
| Scierie | 10 wood, 8 stone | Bûcheron | +20% wood |
| Forge | 20 wood, 15 stone, 5 gold | Forgeron | +25% gold |
| Caserne | 25 wood, 20 stone | Garde | +1 pop max |
| Temple | 30 wood, 20 stone, 10 gold | Prêtre | +foi globale |
| Mine | 20 wood, 10 stone | Mineur | +30% stone |
| Donjon | 40 wood, 35 stone, 20 gold | Esclavage | Pop max x2 |
| Grande Halle | 50 wood, 40 stone, 30 gold | Roi | Niveau Royaume |

---

## Progression du Royaume

| Niveau | Nom | Condition | Bonus |
|---|---|---|---|
| 1 | Campement | Départ | — |
| 2 | Village | 5 habitants + Ferme | +10% toutes productions |
| 3 | Bourgade | 10 habitants + Forge | +15% + événements positifs |
| 4 | Forteresse | 20 habitants + Caserne | +20% + protection raids |
| 5 | Royaume | 35 habitants + Grande Halle | +30% + diplomatie |

---

## Système de Religion

| Religion | Bonus | Malus | Événement spécial |
|---|---|---|---|
| Panthéon Guerrier | +30% force combat | -10% food | Raid béni (butin x2) |
| Culte de la Nature | +25% food/wood | -15% gold | Récolte miraculeuse |
| Ordre du Forgeron | +30% gold/stone | -10% faith growth | Métal sacré (équip.) |
| Culte des Ancêtres | +20% moral | -5% toutes prod. | Vision (révèle map) |

---

## Rencontres aléatoires

| Type PNJ | Probabilité | Métier potentiel | Difficulté combat |
|---|---|---|---|
| Vagabond | 35% | Agriculteur, Bûcheron | Facile |
| Guerrier errant | 25% | Garde, Forgeron | Moyen |
| Moine | 15% | Prêtre | Facile |
| Marchand | 15% | Forgeron | Faible (fuit) |
| Bandit | 10% | Garde | Difficile |
