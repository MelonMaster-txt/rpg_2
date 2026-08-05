# Roadmap — RPG Barbare

## Légende
- ✅ Terminé
- 🔧 En cours
- ⬜ À faire
- 🔴 Bloquant

---

## Phase 1 — Fondations (Map + Player)

- ✅ Structure du projet Godot 4
- ✅ Autoloads de base enregistrés
- ✅ Workbench / Item database
- 🔧 Génération procédurale de la map (TileMap + Rule Tiles)
- 🔧 Système de caméra qui suit le joueur
- ⬜ Zone de départ : cahute + terrain autour
- ⬜ Découverte progressive de la map (fog of war)
- ⬜ Transitions entre zones

## Phase 2 — Joueur

- 🔧 Mouvement 8 directions
- 🔧 AnimatedSprite2D (idle/walk/attack)
- ⬜ Inventaire de base (nourriture, bois, pierre)
- ⬜ Stamina / faim (survie)
- ⬜ Interaction avec objets du monde (couper arbre, ramasser pierre)
- ⬜ Sauvegarde de la position et état

## Phase 3 — PNJ & Rencontres

- 🔧 PNJ familiaux (instances uniques avec NPCData)
- 🔧 PNJ aléatoires (spawn dans forêt)
- ⬜ State Machine complète (Idle/Wander/Combat/Work/Follow)
- ⬜ EncounterManager : popup DISCUSS / FIGHT / RECRUIT
- ⬜ Système de dialogue (DialogueManager)
- ⬜ Portraits et noms procéduraux pour les PNJ aléatoires

## Phase 4 — Combat

- ⬜ CombatSystem (tour par tour simple)
- ⬜ Calcul dégâts basé sur strength
- ⬜ Résolution : KILL / CAPTURE
- ⬜ Animations d'attaque
- ⬜ Effets visuels (flash de dégâts, mort)

## Phase 5 — Royaume

- ⬜ PopulationManager complet
- ⬜ JobSystem : assignation de métiers
- ⬜ Ticker de production (ressources générées automatiquement)
- ⬜ Construction de bâtiments
- ⬜ UI de gestion des habitants
- ⬜ KingdomManager : niveau et progression

## Phase 6 — Religion

- ⬜ ReligionManager : foi globale
- ⬜ Effets de la foi sur moral/production
- ⬜ Métier Prêtre : amplificateur de foi
- ⬜ Événements religieux aléatoires
- ⬜ Dialogues influencés par la religion
- ⬜ Plusieurs religions disponibles avec effets différents

## Phase 7 — Polish & Contenu

- ⬜ Audio : musique ambiante + effets sonores
- ⬜ Système de sauvegarde complet
- ⬜ Menu principal
- ⬜ Tutoriel/onboarding
- ⬜ Équilibrage des ressources
- ⬜ Événements spéciaux (raids, fêtes, catastrophes)
