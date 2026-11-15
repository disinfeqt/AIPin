# AIPin — for AI assistants

AIPin is a World of Warcraft: Forever addon: you can pin places on the player's map, add todo reminders and read their character.
Not installed yet? Follow INSTALL.md (https://wow.duxi.ao/INSTALL.md) first. Use Forever sources for coordinates and NPCs, not Classic/Vanilla ones.

## Files

`<Forever>` is `/Applications/World of Warcraft/_forever_` (macOS) or `C:\Program Files (x86)\World of Warcraft\_forever_` (Windows).

- `<Forever>/Interface/AddOns/AIPin/Inbox.lua`: write pins and todos here.
- `<Forever>/WTF/Account/*/SavedVariables/AIPin.lua`: read `AIPinChars` (character snapshots) and `AIPinDB` (import versions).
- `<Forever>/WTF/Account/*/<Realm>/<Character>/SavedVariables/AIPin.lua`: read `AIPinRecipes` only when asked what to craft or how to upgrade gear.

Never edit SavedVariables; the game overwrites them. To sync, the player right-clicks the AIPin minimap button (or types `/aipin sync`).

## The character (`AIPinChars`)

Read it before answering anything about the character, and don't ask for what it already tells you. Use the entry with the newest `updated` unless the player names another.

- If `updatedText` (player's local time) is older than this session or contradicts the player, ask them to sync, then read it again.
- `money` is in copper (10000 = 1 gold); `x`/`y` are map percent. Any field can be missing; missing `xp` means unreadable, not 0.
- Professions: `tier` is the highest one learned, with cap `max` (apprentice 75, journeyman 150, expert 225, artisan 300). Never suggest learning it or a lower one.
  `nextTier` is what a trainer teaches next, worth it once `rank` nears `max`. Chinese tier names vary, so give the cap too, e.g. "下一级（上限 225）".
- Turn advice into actions: pin each stop and add todos for what to do on arrival. Write them in the player's language.

## Pins and todos

Edit `Inbox.lua`, then ask the player to sync.

```lua
AIPinInbox = {
  version = 4,  -- above AIPinDB.inboxVersion and todoInboxVersion, or nothing is imported
  pins  = { { zone = "暴风城", x = 63.9, y = 69.1, title = "法杖训练师" } },
  todos = { { text = "学法杖", zone = "暴风城" } },
}
```

- List only new entries. `zone` is an English or Chinese zone name (table at the top of `AIPin.lua`), or use `map = <uiMapID>`.
- At most 20 pins are kept. The waypoint goes to the last pin on the player's current map, so list the next stop last.
- A todo with `zone` reminds on entering it, adding `x`/`y` reminds near that spot; neither makes a plain todo.

If you can't write files, give the player these to paste:

- `/aipin <zone> <x> <y> <title>`
- `/aipin todo <text> @ <zone> [<x> <y>]` (leave out `@ …` for a plain todo)

## Recipes (`AIPinRecipes`)

`AIPinRecipes.professions["<name>"].recipes` lists learned recipes with `itemID`, `slot`, `reqLevel`, `quality` and `difficulty`.
Suggest items that beat their `equipment` in that slot, that their class can wear, with `reqLevel` ≤ `level`.
Recipes are saved only after the player opens that profession's window; no `recipeCount` means ask them to open it, then sync.
