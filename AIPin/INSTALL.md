# Install or update AIPin

For AI assistants setting up AIPin, a World of Warcraft: Forever addon, on the user's computer.

You need to be able to run commands or write files on the user's computer. If you can't, give the user the manual steps at the end of this file instead.

1. **Find the Forever folder**, the one that contains `Interface/` and `WTF/`:
   - macOS: `/Applications/World of Warcraft/_forever_/`
   - Windows: `C:\Program Files (x86)\World of Warcraft\_forever_\`
   - Not there? Ask the user. In the Battle.net app, the gear menu next to Forever opens the game folder.
2. **Ask the user to quit the game completely.** WoW only loads new addon files on a full start, not on `/reload`.
3. **Download** the latest release: `https://github.com/disinfeqt/AIPin/releases/latest/download/AIPin.zip`.
   It unpacks to a single `AIPin/` folder.
4. **Install** into `<Forever>/Interface/AddOns/` (create `AddOns` if it doesn't exist). If an old `AIPin/` folder is there,
   keep its `Inbox.lua` (it holds the inbox `version` counter) and put it back after replacing the folder.
   Pins, todos and character data live in `WTF/` and are not touched.
5. **Check** that `<Forever>/Interface/AddOns/AIPin/AIPin.toc` exists (not `AIPin/AIPin/AIPin.toc`). Its `## Version:` line is the installed version.
6. **Tell the user** to start the game, click **AddOns** on the character select screen, make sure **AIPin** is ticked
   (also tick "Load out of date AddOns" if AIPin shows as out of date), then log in.
   The AIPin button appears on the edge of the minimap: left-click opens the panel, right-click syncs.

macOS:

```sh
set -e
WOW="/Applications/World of Warcraft/_forever_"   # change if the game is elsewhere
ADDONS="$WOW/Interface/AddOns"
TMP="$(mktemp -d)"
curl -fsSL -o "$TMP/AIPin.zip" https://github.com/disinfeqt/AIPin/releases/latest/download/AIPin.zip
unzip -q "$TMP/AIPin.zip" -d "$TMP/new"
test -f "$TMP/new/AIPin/AIPin.toc"
mkdir -p "$ADDONS"
if [ -f "$ADDONS/AIPin/Inbox.lua" ]; then cp "$ADDONS/AIPin/Inbox.lua" "$TMP/new/AIPin/Inbox.lua"; fi
if [ -d "$ADDONS/AIPin" ]; then mv "$ADDONS/AIPin" "$TMP/AIPin.old"; fi
mv "$TMP/new/AIPin" "$ADDONS/AIPin"
grep '^## Version' "$ADDONS/AIPin/AIPin.toc"
```

Windows (PowerShell):

```powershell
$ErrorActionPreference = "Stop"
$Wow    = "C:\Program Files (x86)\World of Warcraft\_forever_"   # change if the game is elsewhere
$AddOns = Join-Path $Wow "Interface\AddOns"
$Dest   = Join-Path $AddOns "AIPin"
$Tmp    = Join-Path $env:TEMP ("AIPin-" + [guid]::NewGuid())
New-Item -ItemType Directory -Force $Tmp, $AddOns | Out-Null
Invoke-WebRequest "https://github.com/disinfeqt/AIPin/releases/latest/download/AIPin.zip" -OutFile "$Tmp\AIPin.zip"
Expand-Archive "$Tmp\AIPin.zip" -DestinationPath "$Tmp\new"
if (-not (Test-Path "$Tmp\new\AIPin\AIPin.toc")) { throw "Unexpected zip layout" }
if (Test-Path "$Dest\Inbox.lua") { Copy-Item "$Dest\Inbox.lua" "$Tmp\new\AIPin\Inbox.lua" -Force }
if (Test-Path $Dest) { Remove-Item $Dest -Recurse -Force }
Copy-Item "$Tmp\new\AIPin" $AddOns -Recurse
Select-String '^## Version' "$Dest\AIPin.toc"
```

Writing under `Program Files` can need an elevated shell. If access is denied, ask the user to run it as administrator or to copy the folder themselves.

Manual steps for the user: quit the game → download the zip above → unzip → put the `AIPin` folder in
`_forever_/Interface/AddOns/` → start the game and enable AIPin under AddOns.

**After setup**, read AGENTS.md (in the addon folder, or https://wow.duxi.ao/AGENTS.md) to learn how to use AIPin,
then tell the user in a sentence or two what you can do: pin NPCs and places on their map, add todos that remind them
when they reach a zone, read their character after they right-click the AIPin button to sync, and suggest what to craft.
