#!/bin/bash

set -e

cd "$(dirname "$0")"

echo "========================================"
echo " TB-Planner UT – GitHub Update"
echo "========================================"

echo
echo ">>> Git Status"
git status --short

if git diff --quiet && git diff --cached --quiet && [ -z "$(git ls-files --others --exclude-standard)" ]; then
    echo
    echo "Keine Änderungen vorhanden."
    exit 0
fi

echo
echo ">>> Änderungen:"
git diff --stat

echo
echo ">>> Dateien zum Commit hinzufügen"
git add -A

echo
echo ">>> Commit erstellen"

TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

git commit -m "Update TB-Planner UT - $TIMESTAMP"

echo
echo ">>> Nach GitHub pushen"

git push

echo
echo "========================================"
echo " GitHub erfolgreich aktualisiert."
echo "========================================"
