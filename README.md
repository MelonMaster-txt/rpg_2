# ⚔️ RPG Barbare — Godot 4

Un RPG de survie et de construction de royaume, développé avec **Godot 4 (GDScript)**.

---

## 🎮 Concept

Tu commences seul dans une **cahute isolée** au milieu de nulle part, accompagné de quelques membres de ta famille (PNJ spéciaux). Ton objectif : survivre, te développer, et bâtir un **royaume** à partir de rien.

La carte est **générée aléatoirement** à chaque partie pour garantir une expérience unique.

---

## 🗺️ Fonctionnalités

### Survie & Ressources
- Ramasser de la nourriture, couper du bois, gérer ses ressources
- Construction et amélioration de la cahute / du village

### Exploration & Rencontres
- Forêt générée procéduralement avec des **PNJ aléatoires**
- Chaque rencontre peut mener à :
  - 💬 Une **discussion**
  - ⚔️ Un **combat**
  - 🤝 Devenir **compagnon**

### Système de Combat & Capture
- Vaincre un ennemi donne le choix entre :
  - Le **tuer**
  - Le **capturer** pour travailler dans ta base

### Gestion du Royaume
- Assigner des **métiers** aux habitants/esclaves : agriculteur, bûcheron, forgeron...
- Compagnons fidèles ou main-d'œuvre forcée : à toi de décider
- Expansion progressive vers un vrai **royaume**

### Religion
- Système de **religion** intégré influençant les PNJ, les événements et la progression

---

## 🛠️ Stack Technique

| Outil | Version |
|-------|---------|
| Moteur | Godot 4.x |
| Langage | GDScript |
| Génération de map | Procédurale (TileMap) |

---

## 📁 Structure du Projet

```
rpg_2/
├── game/          # Scènes et scripts principaux
├── addons/        # Plugins Godot
├── icon.svg       # Icône du projet
└── project.godot  # Fichier de configuration Godot
```

---

## 🚀 Lancer le Projet

1. Télécharge et installe **Godot 4**
2. Clone ce repo :
   ```bash
   git clone https://github.com/MelonMaster-txt/rpg_2.git
   ```
3. Ouvre `project.godot` dans Godot 4
4. Lance la scène principale

---

## 🧭 Roadmap

- [x] Génération de map aléatoire
- [x] Système de PNJ et dialogues
- [x] Combat et capture
- [ ] Système de métiers complet
- [ ] Système de religion
- [ ] Construction avancée du royaume
- [ ] Interface de gestion des habitants

---

*Projet en cours de développement — contributions et idées bienvenues !*
