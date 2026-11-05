# AIPin — for AI assistants

AIPin is a World of Warcraft: Forever addon. You can pin places on the player's map, add todo reminders and read their character.
Not installed yet? Follow INSTALL.md (https://wow.duxi.ao/INSTALL.md) first.
Use Forever sources for coordinates and NPCs, not Classic/Vanilla ones.

## Files

`<Forever>` is `/Applications/World of Warcraft/_forever_` (macOS) or `C:\Program Files (x86)\World of Warcraft\_forever_` (Windows).

| File | What for |
|---|---|
| `<Forever>/Interface/AddOns/AIPin/Inbox.lua` | You write pins and todos here |
| `<Forever>/WTF/Account/*/SavedVariables/AIPin.lua` | Read `AIPinChars` (character snapshot) |
| `<Forever>/WTF/Account/*/<Realm>/<Character>/SavedVariables/AIPin.lua` | Read `AIPinRecipes` only when asked what to craft |

Never edit SavedVariables; the game overwrites them.

## Push pins and todos

Edit `Inbox.lua`, then ask the player to right-click the AIPin minimap button to sync.

```lua
AIPinInbox = {
  version = 4,  -- previous version + 1, or nothing is imported
  pins  = { { zone = "暴风城", x = 63.9, y = 69.1, title = "法杖训练师" } },
  todos = { { text = "学法杖", zone = "暴风城" } },
}
```

- Read the file first and bump `version`. If it was reset, use a number above `inboxVersion` and `todoInboxVersion` in `AIPinDB`.
- Only list new entries. `zone` is an English or Chinese zone name (table at the top of `AIPin.lua`), or use `map = <uiMapID>`.
  `x`/`y` are map percent (0–100), as on Wowhead.
- A todo with `zone` reminds on entering the zone; add `x`/`y` to remind within ~3% of a spot; no `zone` = plain todo.
- Keep valid Lua: quote strings, escape `"` and `\`.

## Slash commands

For the player to paste when you can't write files:

- `/aipin <zone> <x> <y> <title>` adds a pin.
- `/aipin todo <text> @ <zone> [<x> <y>]` adds a todo (leave out `@ …` for a plain one).
- `/aipin sync` saves the snapshot and imports `Inbox.lua` (same as right-clicking the minimap button).

`/aipin help` lists the rest.

## Character snapshot (`AIPinChars`)

Written on sync, `/reload` and logout. Keyed `"Name-Realm"`; use the entry with the newest `updated`. Any field can be missing.

```
name, realm, race, class, sex, level, xp, xpMax, restXP, money (copper), guild, hearth, timePlayed,
zone, subzone, mapName, uiMapID, x, y, bagFree, bagTotal, updated (unix time),
talents = { tabs = { {name, points} }, spec },
professions = { {name, rank, max, kind = "crafting"|"gathering", recipeCount, recipesUpdated} },
quests = { {questID, title, level, isComplete, objectives = { {text, have, need, done} }} },
equipment = { HeadSlot = {itemID, name, itemLevel}, ... },
```

## Recipes (`AIPinRecipes`, per character)

Only read this when the player asks what to craft. `AIPinRecipes.professions["<profession name>"].recipes` lists learned recipes:
`{recipeID, name, difficulty, itemID, quality, itemLevel, reqLevel, slot, itemType, itemSubType}`.

- `quality` 0 poor … 4 epic; `reqLevel` = level needed to use; `slot` e.g. `INVTYPE_CHEST`;
  `difficulty` optimal / medium / easy / trivial (skill-up chance).
- Suggest items that beat `equipment` in that slot, that the class can wear, with `reqLevel` ≤ `level`.
- Recipes are saved only after the player opens that profession's window. No `recipeCount`? Ask them to open it, then sync.
