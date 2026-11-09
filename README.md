# omarchy-dtp-start-menu

Puts the Super+Space menu and the Super+Alt+Space app list in the screen corner next to the Omarchy menu button, like a start menu.

| Bar | Overlays open at |
| --- | --- |
| bottom | bottom left |
| top | top left |
| left | top left |
| right | top right |

A horizontal bar whose menu button sits in the right section uses the right corner. The corner follows `bar.position` in `shell.json`, so moving the bar moves the overlays.

## Install

`omarchy-dtp-install` runs this after `omarchy-dtp-app-list`. From GitHub:

```bash
git clone https://github.com/dtpietrzak/omarchy-dtp-start-menu.git
cd omarchy-dtp-start-menu
./install.sh
```

The script:

- clones `omarchy.menu` when this machine has no clone. The clone is `<username>.menu`, and the bar switches to it
- copies `StartCorner.qml` into the menu clone and into `dtpietrzak.applist`
- edits `Menu.qml` and `AppList.qml` to place their cards with it

Running it again leaves files that already carry the change untouched. If a file no longer matches what the script expects, it stops and says which line.

The app list is patched in place. Running the `omarchy-dtp-app-list` installer afterwards copies a fresh list over it, so run this one after.

## Trade-off

The menu is a clone, so later Omarchy menu updates do not reach it until the clone is removed and this script is run again.

## Undo

```bash
omarchy plugin remove dtpietrzak.menu
```
