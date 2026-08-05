#!/usr/bin/env python3
"""
gdlint_check.py
---------------
Lance gdlint sur tout le projet GDScript, puis poste le résultat
en commentaire sur le dernier commit GitHub.

Usage :
    python tools/gdlint_check.py
    python tools/gdlint_check.py --branch feature/npc-system
    python tools/gdlint_check.py --path game/characters/npcs

Pré-requis :
    pip install "gdtoolkit==4.*" requests
    Variable d'environnement GITHUB_TOKEN avec un token ayant le scope repo.
"""

import argparse
import json
import os
import subprocess
import sys
from pathlib import Path

import requests

# ── Config ────────────────────────────────────────────────────────────────────
REPO_OWNER = "MelonMaster-txt"
REPO_NAME  = "rpg_2"
GH_API     = "https://api.github.com"
# ─────────────────────────────────────────────────────────────────────────────


def get_token() -> str:
    token = os.environ.get("GITHUB_TOKEN", "")
    if not token:
        sys.exit("❌  GITHUB_TOKEN non défini. Exporte-le avant de lancer le script.")
    return token


def get_latest_commit_sha(token: str, branch: str) -> str:
    url = f"{GH_API}/repos/{REPO_OWNER}/{REPO_NAME}/branches/{branch}"
    r = requests.get(url, headers={"Authorization": f"Bearer {token}"})
    r.raise_for_status()
    return r.json()["commit"]["sha"]


def run_gdlint(scan_path: str) -> tuple[int, str]:
    """Retourne (returncode, output_texte)."""
    result = subprocess.run(
        ["gdlint", scan_path],
        capture_output=True,
        text=True,
    )
    output = (result.stdout + result.stderr).strip()
    return result.returncode, output


def run_gdformat_check(scan_path: str) -> tuple[int, str]:
    """Vérifie le formatage sans modifier les fichiers."""
    result = subprocess.run(
        ["gdformat", "--check", scan_path],
        capture_output=True,
        text=True,
    )
    output = (result.stdout + result.stderr).strip()
    return result.returncode, output


def build_comment(lint_code: int, lint_out: str, fmt_code: int, fmt_out: str, scan_path: str) -> str:
    lines = []
    lines.append("## 🔍 gdlint auto-check")
    lines.append(f"**Dossier scanné :** `{scan_path}`\n")

    # ── Lint ──
    if lint_code == 0:
        lines.append("### ✅ gdlint — aucune erreur")
    else:
        lines.append("### ❌ gdlint — erreurs détectées")
        lines.append("```")
        lines.append(lint_out or "(pas de sortie)")
        lines.append("```")

    lines.append("")

    # ── Format ──
    if fmt_code == 0:
        lines.append("### ✅ gdformat — formatage OK")
    else:
        lines.append("### ⚠️ gdformat — fichiers à reformater")
        lines.append("```")
        lines.append(fmt_out or "(pas de sortie)")
        lines.append("```")
        lines.append("> Lance `gdformat <fichier>` pour corriger automatiquement.")

    return "\n".join(lines)


def post_commit_comment(token: str, sha: str, body: str) -> None:
    url = f"{GH_API}/repos/{REPO_OWNER}/{REPO_NAME}/commits/{sha}/comments"
    r = requests.post(
        url,
        headers={"Authorization": f"Bearer {token}", "Content-Type": "application/json"},
        data=json.dumps({"body": body}),
    )
    r.raise_for_status()
    comment_url = r.json().get("html_url", "")
    print(f"✅  Commentaire posté : {comment_url}")


def main() -> None:
    parser = argparse.ArgumentParser(description="gdlint checker + GitHub commit comment")
    parser.add_argument("--branch", default="main", help="Branche à cibler (default: main)")
    parser.add_argument("--path", default="game", help="Dossier GDScript à scanner (default: game)")
    args = parser.parse_args()

    scan_path = args.path
    branch    = args.branch
    token     = get_token()

    print(f"🔎  Scan gdlint sur '{scan_path}'...")
    lint_code, lint_out = run_gdlint(scan_path)

    print(f"🔎  Vérification gdformat sur '{scan_path}'...")
    fmt_code, fmt_out = run_gdformat_check(scan_path)

    # Affichage local
    status = "OK" if lint_code == 0 and fmt_code == 0 else "ERREURS"
    print(f"\n{'='*50}")
    print(f"Résultat : {status}")
    if lint_out: print("\n[gdlint]\n" + lint_out)
    if fmt_out:  print("\n[gdformat]\n" + fmt_out)
    print("="*50)

    # Récupère le SHA du dernier commit sur la branche
    print(f"\n📡  Récupération du SHA (branche '{branch}')...")
    sha = get_latest_commit_sha(token, branch)
    print(f"    SHA : {sha[:12]}...")

    # Poste le commentaire
    comment = build_comment(lint_code, lint_out, fmt_code, fmt_out, scan_path)
    print("📝  Publication du commentaire sur GitHub...")
    post_commit_comment(token, sha, comment)

    sys.exit(0 if lint_code == 0 and fmt_code == 0 else 1)


if __name__ == "__main__":
    main()
