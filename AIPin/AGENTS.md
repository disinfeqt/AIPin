# AIPin — instructions for AI assistants

AIPin is a World of Warcraft: Forever addon that:
1. Puts NPC/location **pins** on the in-game world map
2. Keeps a **todo list** with optional zone or coordinate reminders
3. Writes a **character snapshot** you can read after a sync

If the user asked you to **set up AIPin**, do section 0, then read the rest of this file so you know how to use it.
Always prefer **Forever** data (coords, NPC locations, quests). Do not use Classic/Vanilla Wowhead coords unless Forever confirms them.

---

## 0. Install or update AIPin

You need to be able to run commands or write files on the user's computer. If you can't, give the user the manual steps at the end of this section instead.

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

**After setup**, tell the user in a sentence or two what you can now do for them: pin NPCs/places on their map,
add todos that remind them when they reach a zone, read their character after they right-click the AIPin button to sync,
and suggest what to craft from their learned recipes.

---

## 1. Push pins (Inbox.lua)

The game cannot receive messages from outside, but it re-reads addon files on `/reload`.
Edit `Interface/AddOns/AIPin/Inbox.lua` inside the Forever install folder:

- macOS: `/Applications/World of Warcraft/_forever_/Interface/AddOns/AIPin/Inbox.lua`
- Windows: `C:\Program Files (x86)\World of Warcraft\_forever_\Interface\AddOns\AIPin\Inbox.lua`

```lua
AIPinInbox = {
  version = 3,   -- MUST be higher than last time, or nothing is imported
  pins = {
    { zone = "丹莫罗", x = 44.1, y = 57.1, title = "巡山人格雷琴" },
    { map = 1455, x = 60.0, y = 45.4, title = "附魔训练师" },  -- map = uiMapID
  },
}
```

Rules:
- Read the current file first; set `version` to (old + 1). Each version is imported once (`AIPinDB.inboxVersion`).
- If `Inbox.lua` was reset (for example after a reinstall), read `inboxVersion` and `todoInboxVersion` from `AIPinDB`
  in `WTF/Account/*/SavedVariables/AIPin.lua` and use a number higher than both.
- `pins` only needs NEW markers; old ones are already saved in-game.
- Keep valid Lua: quote strings, escape `"` and `\`, commas between entries.
- Tell the user to **right-click** the AIPin minimap button (or `/reload`). They see "已从助手导入 N 个新标记。"
- First install needs a full game restart (not just `/reload`).
- Do NOT edit `WTF/.../SavedVariables/AIPin.lua`; the game overwrites it.
- Also give a `/aipin` slash command as fallback.

Useful Forever uiMapIDs: Dun Morogh 1426, Ironforge 1455, Stormwind 1453, Elwynn Forest 1429,
Loch Modan 1432, Duskwood 1431, Hillsbrad 1424, Eastern Plaguelands 1423, Blasted Lands 1419,
Burning Steppes 1428.

### Slash fallback for pins

```
/aipin <zone> <x> <y> <title>
```

- `<zone>`: zone name in English or Simplified Chinese, e.g. `Dun Morogh` / `丹莫罗`, `Ironforge` / `铁炉堡`.
  Supported names are in the zone table near the top of `AIPin.lua`. If omitted, the player's current map is used.
- `<x> <y>`: map coordinates as percentages 0–100, same as Wowhead (e.g. `44.1 57.1`).
- `<title>`: free text shown on the pin tooltip (spaces allowed).

Example: `/aipin 暴风城 63.9 69.1 吴平`
Other: `/aipin list`, `/aipin clear`, `/aipin help`. Alias: `/ap`.

---

## 2. Push todos (Inbox.lua)

Same file, same `version` bump. Add a `todos` array (deduped by `text`, tracked by `AIPinDB.todoInboxVersion`):

```lua
AIPinInbox = {
  version = 4,
  pins = { ... },  -- optional
  todos = {
    -- Zone-only: fires when the player ENTERS that zone (no coords needed)
    { text = "学法杖", zone = "暴风城" },
    { text = "找裁缝训练师", map = 1455 },

    -- Coordinate geo-reminder: fires within ~3% of the spot
    { text = "学法杖", map = 1453, x = 63.9, y = 69.1 },
    { text = "交任务", zone = "丹莫罗", x = 31.5, y = 44.6 },

    -- Plain todo (no reminder)
    { text = "买背包" },
  },
}
```

Stored shape in `AIPinDB.todos`: `{ text, done, created, map, x, y }`.
- Zone-only → `map` set, `x = nil`, `y = nil`. Fires once on zone entry; re-arms when the player leaves.
- Coord → `map` + `x` + `y`. Fires within ~3% of map size; re-arms after moving >5% away.
- Reminder = chat line + on-screen popup + sound.

---

## 3. Slash commands for todos

If you can drive game chat (or tell the player what to paste):

| Command | Effect |
|---|---|
| `/aipin todo <text>` | Add a plain todo |
| `/aipin todo <text> @ <zone>` | Zone reminder (enter zone → fire) |
| `/aipin todo <text> @ <zone> <x> <y>` | Coord geo-reminder |
| `/aipin todos` | List todos in chat |
| `/aipin done N` | Mark #N done |
| `/aipin undone N` | Mark #N undone |
| `/aipin deltodo N` | Delete #N |
| `/aipin cleartodos` | Clear all completed |

Examples:
```
/aipin todo 学法杖 @ 暴风城
/aipin todo 学法杖 @ 暴风城 63.9 69.1
/aipin todo 买背包
/aipin todos
/aipin done 1
```

The player can also manage todos in the panel (left-click minimap → **待办** tab).

---

## 4. Read character snapshot

AIPin writes `AIPinChars` to SavedVariables:

- macOS: `/Applications/World of Warcraft/_forever_/WTF/Account/*/SavedVariables/AIPin.lua`
- Windows: `...\World of Warcraft\_forever_\WTF\Account\*\SavedVariables\AIPin.lua`

Rules:
- Written only on `/reload`, logout, or character switch. Ask the player to right-click AIPin (sync) or `/reload` for fresh data.
- **Read-only.** Edits while the game runs are lost.
- Keyed by `"Name-Realm"`. Several characters/accounts may exist — pick the entry with the newest `updated`.
- Any field can be missing (API absent or restricted in Forever).

Schema:
```
AIPinChars["Name-Realm"] = {
  name, realm, race, class, sex = "male"|"female"|"unknown", level,
  xp, xpMax, restXP, money (copper), guild, hearth,
  timePlayed, timePlayedLevel (seconds; only after /played),
  zone, subzone, mapName, uiMapID, x, y (percent, 1 decimal),
  talents = { tabs = { {name, points}, ... }, spec, loadout },
  professions = { {name, rank, max, skillLine, kind = "crafting"|"gathering", recipesUpdated, recipes = {
    {recipeID, name, difficulty, itemID, quality, itemLevel, reqLevel, slot, itemType, itemSubType}, ...
  }}, ... },
  quests = { {questID, title, level, isComplete, objectives = { {text, have, need, done}, ... }}, ... },
  equipment = { HeadSlot = {link, name, itemLevel}, ... },
  bagFree, bagTotal,
  updated (unix), updatedText ("YYYY-MM-DD HH:MM:SS", local time),
}
```

In-game summary: `/aipin me`.

### Learned recipes → what to craft

Each profession can carry a `recipes` list: the recipes the character has **learned**. Use it to recommend gear the player can make,
for example an upgrade for a slot where `equipment` is weak, or something to sell.

- `kind = "crafting"` (Tailoring, Enchanting, Alchemy, Leatherworking, Blacksmithing, Engineering, Jewelcrafting, Inscription,
  Cooking, First Aid): `recipes` is filled once the player has opened that profession's window.
- `kind = "gathering"` (Herbalism, Mining, Skinning, Fishing): only `rank` / `max`, no `recipes`.
- `professions` only lists professions; weapon skills, languages and the like are left out.

- `name`: recipe name. `difficulty`: skill-up colour (`optimal` / `medium` / `easy` / `trivial`; `optimal` = orange, best for leveling the skill).
- Crafted item (missing for enchants and when the game hasn't cached the item yet): `itemID`, `quality` (0 poor, 1 common, 2 uncommon,
  3 rare, 4 epic), `itemLevel`, `reqLevel` (character level needed to use it), `slot` (equip slot such as `INVTYPE_CHEST`),
  `itemType` / `itemSubType` (e.g. `Armor` / `Cloth`).
- Compare `slot`, `itemLevel` and `reqLevel` with `equipment` and `level` to suggest real upgrades. Don't recommend items the
  character can't wear (check `itemSubType` against `class`) or can't use yet (`reqLevel` above `level`).
- The game only exposes recipes while a profession window is open. AIPin reads them whenever the player opens one and keeps them
  afterwards; `recipesUpdated` (unix time) says when that profession was last read.
- No `recipes` for a profession, or it's stale? Ask the player to open that profession's window in game (from the spellbook),
  then right-click the AIPin button to sync, and read the file again.
- Recipes from someone else's linked profession window are never saved.

---

## 5. Minimap button / sync

- **Left-click** → open panel (tabs: 待办 | 标记). Default tab = 待办.
- **Right-click** → sync: snapshot character → set `AIPinDB.lastSync` → `ReloadUI` (writes SavedVariables + imports Inbox). Blocked in combat.
- Equivalent: `/aipin sync`. Toggle button: `/aipin minimap` (`AIPinDB.minimapHidden`). Angle: `AIPinDB.minimapAngle`.
- Undone todo count shows as a gold badge on the button.

---

## 6. Panel UI (for context)

One window (~440×540): header with the AIPin icon, name and version (read from `AIPin.toc`), two tabs:
- **待办**: scrollable list (checkbox, text, zone, ✕), input (`添加待办…（可加 @ 区域，坐标可省略）`), 添加 / 提醒在此处 / 清除已完成.
- **标记**: scrollable pin list (title, zone + coords, ✕), 全部清除.
Footer: last sync time, inbox version and a 同步 button.

---

## Quick checklist for another agent

1. Not installed yet? Do section 0 first.
2. Prefer Forever sources for coords/NPCs.
3. To mark a place: bump `Inbox.lua` version + add pin; tell user to right-click AIPin. Also paste `/aipin ...` as backup.
4. To remind the player later: add a todo — zone-only `@ 暴风城` or coord `@ 暴风城 63.9 69.1`.
5. To know what the player is doing: read `SavedVariables/AIPin.lua` → `AIPinChars` after a sync.
6. To suggest what to craft: use `professions[i].recipes` (learned recipes) against `equipment` and `level`.
7. Never write SavedVariables yourself.
