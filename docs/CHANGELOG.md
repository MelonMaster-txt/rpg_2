# Changelog — RPG Barbare

Tous les changements notables sont documentés ici.
Format : `[DATE] - Description`

---

## [2026-08-05] — Initialisation de la documentation

### Ajouté
- `docs/ARCHITECTURE.md` — schéma complet de l'architecture, autoloads, signaux, flux de jeu
- `docs/ROADMAP.md` — roadmap complète par phases (Map → Player → PNJ → Combat → Royaume → Religion)
- `docs/SYSTEMS.md` — documentation API de chaque système (ResourceManager, PopulationManager, JobSystem, KingdomManager, ReligionManager, EncounterManager)
- `docs/GAME_DESIGN.md` — tableaux d'équilibrage (ressources, métiers, bâtiments, religions, rencontres)
- `docs/CHANGELOG.md` — ce fichier

### Existant (avant documentation)
- Structure Godot 4 initialisée
- Autoloads de base enregistrés dans `project.godot`
- `game/systems/item_database.gd` — base de données d'items
- `game/systems/workbench.gd/.tscn` — établi de craft
- `game/systems/workbench_ui.gd/.tscn` — UI de l'établi
- Dossiers systèmes créés : `combat/`, `dialogue/`, `jobs/`, `kingdom/`, `religion/`, `resources/`
