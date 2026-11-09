#!/usr/bin/env bash
# Anchor the Super+Space menu and the Super+Alt+Space app list to the screen
# corner beside the Omarchy menu button. Safe to run again: files that already
# carry the change are left alone.
#
#   ./install.sh
#
# Run it after omarchy-dtp-app-list. That installer copies the app list over
# its plugin directory, which removes this change.

set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
PLUGINS="$HOME/.config/omarchy/plugins"

fail() {
  echo "install: $*" >&2
  exit 1
}

if [[ ${1:-} == "-h" || ${1:-} == "--help" ]]; then
  echo "Usage: install.sh"
  echo "Puts the Omarchy menu and the app list in the corner next to the menu button."
  exit 0
fi
[[ $# -eq 0 ]] || fail "unknown argument: $1"
command -v jq >/dev/null || fail "jq is required"
command -v python3 >/dev/null || fail "python3 is required"

menu_clone_id() {
  omarchy plugin list --json | jq -r '[.[] | select(.clonedFrom == "omarchy.menu")][0].id // empty'
}

echo "==> menu"
menu_id="$(menu_clone_id)"
if [[ -z $menu_id ]]; then
  omarchy plugin clone omarchy.menu
  menu_id="$(menu_clone_id)"
  [[ -n $menu_id ]] || fail "cloning omarchy.menu did not produce a clone"
fi
menu_dir="$PLUGINS/$menu_id"
[[ -f $menu_dir/Menu.qml ]] || fail "$menu_dir/Menu.qml is missing"
echo "Menu clone: $menu_id"

applist_dir="$PLUGINS/dtpietrzak.applist"
if [[ ! -f $applist_dir/AppList.qml ]]; then
  echo "App list is not installed. Only the menu will move."
  applist_dir=""
fi

python3 - "$ROOT" "$menu_dir" "$applist_dir" <<'PY'
import shutil
import sys
from pathlib import Path

root, menu_dir, applist_dir = (Path(a) if a else None for a in sys.argv[1:4])

def fail(message):
    raise SystemExit(f"install: {message}")

def patch(path, edits, label):
    text = path.read_text()
    if "StartCorner" in text:
        print(f"{label} is already anchored")
        return
    for old, new in edits:
        if text.count(old) != 1:
            fail(f"{label} no longer matches what this installer expects. Upstream changed: {old.splitlines()[0].strip()}")
        text = text.replace(old, new)
    path.write_text(text)
    print(f"Anchored {label}")

def copy_helper(dest):
    target = dest / "StartCorner.qml"
    source = root / "StartCorner.qml"
    if target.is_file() and target.read_bytes() == source.read_bytes():
        print(f"StartCorner.qml is already in {dest.name}")
        return
    shutil.copyfile(source, target)
    print(f"Copied StartCorner.qml into {dest.name}")

# Menu card: x and y from the corner. The corner sets the top line, so the card
# grows away from the bar instead of jumping as the list changes.
copy_helper(menu_dir)
patch(menu_dir / "Menu.qml", [
    ("  OverlayWindow {\n    id: panel\n    shown: root.opened && root.rowsLoaded\n",
     "  StartCorner { id: corner }\n\n  OverlayWindow {\n    id: panel\n    shown: root.opened && root.rowsLoaded\n"),
    ("readonly property int effectiveCardTop: cardTop >= 0 ? cardTop : centeredTop",
     "readonly property int effectiveCardTop: corner.cardY(height, root.cardHeight)"),
    ("      anchors.horizontalCenter: parent.horizontalCenter\n      y: panel.effectiveCardTop\n",
     "      x: corner.cardX(panel.width, width)\n      y: panel.effectiveCardTop\n"),
], f"{menu_dir.name}/Menu.qml")

if applist_dir:
    copy_helper(applist_dir)
    patch(applist_dir / "AppList.qml", [
        ("  OverlayWindow {\n    id: panel\n    shown: root.opened\n",
         "  StartCorner { id: corner }\n\n  OverlayWindow {\n    id: panel\n    shown: root.opened\n"),
        ("      anchors.centerIn: parent\n      radius: Style.cornerRadius\n",
         "      x: corner.cardX(panel.width, width)\n      y: corner.cardY(panel.height, height)\n      radius: Style.cornerRadius\n"),
    ], "dtpietrzak.applist/AppList.qml")
PY

omarchy-shell shell rescanPlugins >/dev/null 2>&1 || omarchy restart shell
echo "Done. Super+Space and Super+Alt+Space now open beside the menu button."
