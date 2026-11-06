# AIPin — for AI assistants

AIPin is a World of Warcraft: Forever addon. You can pin places on the player's map, add todo reminders and read their character, so your help fits where they are and what they're doing.
Not installed yet? Follow INSTALL.md (https://wow.duxi.ao/INSTALL.md) first.
Use Forever sources for coordinates and NPCs, not Classic/Vanilla ones.

## Files

`<Forever>` is `/Applications/World of Warcraft/_forever_` (macOS) or `C:\Program Files (x86)\World of Warcraft\_forever_` (Windows).

| File | What for |
|---|---|
| `<Forever>/Interface/AddOns/AIPin/Inbox.lua` | You write pins and todos here |
| `<Forever>/WTF/Account/*/SavedVariables/AIPin.lua` | Read `AIPinChars` (character snapshot) |
| `<Forever>/WTF/Account/*/<Realm>/<Character>/SavedVariables/AIPin.lua` | Read `AIPinRecipes` only when asked what to craft or how to upgrade gear |

Never edit SavedVariables; the game overwrites them.

## Use the player's data

Read the newest `AIPinChars` entry before answering anything about the player's character. Don't ask for what it already tells you (level, class, zone, quests, gold, professions, gear).

- **Check it's fresh.** `updatedText` is when it was last saved, in the player's local time. If it's older than this session or contradicts what they say, ask them to right-click the AIPin minimap button to sync, then read it again.
- **Fit advice to the character:** `level`, `class` and `talents` for what to do next; `zone`, `x`, `y` to start with the nearest option; `money` (copper, 10000 = 1 gold) before suggesting training or purchases; `bagFree` before long farming runs; `hearth` when planning travel.
- **Quests:** `objectives` (`have` / `need`) show what's left; quests with `isComplete` only need turning in.
- **Professions:** `rank` at or near `max` means they need the next trainer; for gathering, suggest zones that match their `rank`.
- **Turn advice into actions:** pin each stop, and add todos with a `zone` for things to do on arrival (train, sell, turn in). Write titles and todos in the player's language.
- Several characters can be saved; use the newest `updated` unless the player names another.

## Push pins and todos

Edit `Inbox.lua`, then ask the player to right-click the AIPin minimap button to sync.

```lua
AIPinInbox = {
  version = 4,  -- higher than any version imported before, or nothing is imported
  pins  = { { zone = "暴风城", x = 63.9, y = 69.1, title = "法杖训练师" } },
  todos = { { text = "学法杖", zone = "暴风城" } },
}
```

- Set `version` above the file's current `version` and above `inboxVersion` and `todoInboxVersion` in `AIPinDB` (updating the addon resets the file to 0).
- Only list new entries. `zone` is an English or Chinese zone name (table at the top of `AIPin.lua`), or use `map = <uiMapID>`;
  the snapshot's `uiMapID` works for the player's current zone. `x`/`y` are map percent (0–100), as on Wowhead.
- At most 20 pins are kept (oldest dropped). The last pin in `pins` gets the waypoint arrow, so list the next destination last.
- A todo with `zone` reminds on entering the zone; add `x`/`y` to remind within ~3% of a spot; no `zone` = plain todo.
- Keep valid Lua: quote strings, escape `"` and `\`.

## Slash commands

For the player to paste when you can't write files:

- `/aipin <zone> <x> <y> <title>` adds a pin.
- `/aipin todo <text> @ <zone> [<x> <y>]` adds a todo (leave out `@ …` for a plain one).
- `/aipin sync` saves the snapshot and imports `Inbox.lua` (same as right-clicking the minimap button).

`/aipin help` lists the rest.

## Character snapshot (`AIPinChars`)

Written to disk on sync, `/reload` and logout. Keyed `"Name-Realm"` (realm without spaces or hyphens); use the entry with the newest `updated`. Any field can be missing.

```
name, realm, race, class, sex, level, xp, xpMax, restXP, money (copper), guild, hearth,
timePlayed (only after the player runs /played), zone, subzone, mapName, uiMapID, x, y (map percent),
bagFree, bagTotal, updated (unix time), updatedText (player's local time),
talents = { tabs = { {name, points} }, spec },
professions = { {name, rank, max, kind = "crafting"|"gathering", recipeCount, recipesUpdated} },
quests = { {questID, title, level, isComplete, objectives = { {text, have, need, done} }} },
equipment = { HeadSlot = {itemID, name, itemLevel}, ... },
```

## Recipes (`AIPinRecipes`, per character)

Only read this when the player asks what to craft or how to upgrade gear. The `<Realm>` folder uses the realm name as shown in game (it may contain spaces).
`AIPinRecipes.professions["<profession name>"].recipes` lists learned recipes:
`{recipeID, name, difficulty, itemID, quality, itemLevel, reqLevel, slot, itemType, itemSubType}`.

- `quality` 0 poor … 4 epic; `reqLevel` = level needed to use; `slot` e.g. `INVTYPE_CHEST`;
  `difficulty` optimal / medium / easy / trivial (skill-up chance).
- Suggest items that beat `equipment` in that slot, that the class can wear, with `reqLevel` ≤ `level`.
- Recipes are saved only after the player opens that profession's window. No `recipeCount`? Ask them to open it, then sync.
