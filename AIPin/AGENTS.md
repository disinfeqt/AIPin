# AIPin — instructions for AI assistants

AIPin is a World of Warcraft: Forever addon that puts NPC/location markers on the in-game world map
(plus a native waypoint arrow and AIPin map pins).
If your user asks where an NPC, quest giver, trainer or place is, you can mark it for them in two ways.

## 1. Give a slash command (always works)
Reply with one line the user pastes into the game chat:

    /aipin <zone> <x> <y> <title>

- `<zone>`: zone name in English or Simplified Chinese, e.g. `Dun Morogh` / `丹莫罗`, `Ironforge` / `铁炉堡`.
  Supported names are in the zone table near the top of `AIPin.lua`. If omitted, the player's current map is used.
- `<x> <y>`: map coordinates as percentages 0-100, same as Wowhead / ForG (e.g. `44.1 57.1`).
- `<title>`: free text shown on the marker tooltip (spaces allowed).
- Example: `/aipin 丹莫罗 44.1 57.1 巡山人格雷琴`
- Other commands: `/aipin list`, `/aipin clear`, `/aipin help`. Alias: `/ap`.

## 2. Push markers by editing Inbox.lua (if you can write files on the user's computer)
The game cannot receive messages from outside, but it re-reads addon files on `/reload`.
Edit `Interface/AddOns/AIPin/Inbox.lua` inside the Forever install folder:

- macOS default: `/Applications/World of Warcraft/_forever_/Interface/AddOns/AIPin/Inbox.lua`
- Windows default: `C:\Program Files (x86)\World of Warcraft\_forever_\Interface\AddOns\AIPin\Inbox.lua`

Format:

```lua
AIPinInbox = {
  version = 3,   -- MUST be higher than last time, or nothing is imported
  pins = {
    { zone = "丹莫罗", x = 44.1, y = 57.1, title = "巡山人格雷琴" },
    { map = 1455, x = 60.0, y = 45.4, title = "附魔训练师" },  -- map = uiMapID, optional instead of zone
  },
}
```

Rules:
- Read the current file first and set `version` to (old version + 1). Each version is imported once.
- `pins` only needs the NEW markers; old ones are already saved in the game.
- Keep it valid Lua: quote strings, escape `"` and `\` inside titles, commas between entries.
- Then tell the user to type `/reload` in game. They will see "已从助手导入 N 个新标记。" in chat.
- The very first time after installing, the user must fully restart the game (not just /reload).
- Do NOT edit `WTF/.../SavedVariables/AIPin.lua`; the game overwrites it on reload/logout.
- It's good practice to also include the `/aipin` command in your reply as a fallback.

Useful Forever uiMapIDs: Dun Morogh 1426, Ironforge 1455, Elwynn Forest 1429, Loch Modan 1432,
Duskwood 1431, Hillsbrad 1424, Eastern Plaguelands 1423, Blasted Lands 1419, Burning Steppes 1428.

## Reading the player's character state (v1.1)

AIPin writes a snapshot to the SavedVariable `AIPinChars` in:
- macOS: `/Applications/World of Warcraft/_forever_/WTF/Account/*/SavedVariables/AIPin.lua`
- Windows: `C:\Program Files (x86)\World of Warcraft\_forever_\WTF\Account\*\SavedVariables\AIPin.lua` (or wherever the game is installed)

Rules:
- The game only writes this file on `/reload`, logout, or character switch. Ask the player to `/reload` for fresh data.
- Treat it as **read-only**; the game overwrites it and edits made while the game runs are lost.
- `AIPinChars` is keyed by `"Name-Realm"`. Several characters (and several account folders) may exist; pick the entry with the newest `updated`.
- Any field can be missing (the API may not exist in Forever or was restricted).

Schema (Lua table):
```
AIPinChars["Name-Realm"] = {
  name, realm, race, class, sex = "male"|"female"|"unknown", level,
  xp, xpMax, restXP, money (copper), guild, hearth (bind location),
  timePlayed, timePlayedLevel (seconds; only if the player ran /played),
  zone, subzone, mapName, uiMapID, x, y (percent, 1 decimal),
  talents = { tabs = { {name, points}, ... }, spec, loadout },
  professions = { {name, rank, max, skillLine}, ... },
  quests = { {questID, title, level, isComplete, objectives = { {text, have, need, done}, ... }}, ... },
  equipment = { HeadSlot = {link, name, itemLevel}, ... },
  bagFree, bagTotal,
  updated (unix time), updatedText ("YYYY-MM-DD HH:MM:SS", player's local time),
}
```
The player can run `/aipin me` to see a short summary in-game.

## Minimap button / sync (v1.1)

Instead of asking the player to type `/reload`, you can say: "点小地图旁的 AIPin 按钮" (right-click = sync). Sync takes a snapshot, sets `AIPinDB.lastSync = time()`, then reloads the UI — which writes SavedVariables (character data) and imports Inbox.lua. Equivalent command: `/aipin sync`. Blocked in combat. Left-click opens the pin list. `/aipin minimap` toggles the button (`AIPinDB.minimapHidden`); its position is `AIPinDB.minimapAngle`.

## Todos and geo-reminders (v1.3)

Inbox.lua also accepts a `todos` list (bump `version` as usual; todos are deduped by `text`, tracked by `AIPinDB.todoInboxVersion`):

```lua
AIPinInbox = {
  version = N,
  pins = { ... },
  todos = {
    { text = "学法杖", map = 1453, x = 63.9, y = 69.1 }, -- geo-reminder (zone = "暴风城" also works)
    { text = "买背包" },                                  -- plain todo
  },
}
```

Todos live in `AIPinDB.todos` as `{ text, done, created, map, x, y }`. A geo-reminder fires (chat + screen + sound) when the player is on that uiMapID within ~3% of the map of the spot; it re-arms after moving >5% away. Slash equivalents: `/aipin todo <text> [@ <zone> <x> <y>]`, `/aipin todos`, `/aipin done N`, `/aipin undone N`, `/aipin deltodo N`, `/aipin cleartodos`. The player mainly manages todos in the panel (left-click minimap button).
