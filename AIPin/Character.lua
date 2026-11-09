-- AIPin character snapshot -> SavedVariables AIPinChars (read by an AI assistant from disk)
local function pass(ok, ...) if ok then return ... end return nil end
local function try(f, ...)
  if type(f) ~= "function" then return nil end
  return pass(pcall(f, ...))
end
local function safe(v)  -- drop secret/non-plain values
  local t = type(v)
  if t == "string" or t == "number" or t == "boolean" then
    if issecretvalue and try(issecretvalue, v) then return nil end
    return v
  end
  return nil
end
local function r1(n) n = tonumber(n); if not n then return nil end return math.floor(n * 10 + 0.5) / 10 end

local SLOTS = { "HeadSlot","NeckSlot","ShoulderSlot","ShirtSlot","ChestSlot","WaistSlot","LegsSlot","FeetSlot",
  "WristSlot","HandsSlot","Finger0Slot","Finger1Slot","Trinket0Slot","Trinket1Slot","BackSlot",
  "MainHandSlot","SecondaryHandSlot","RangedSlot","TabardSlot" }

local function Location(s)
  s.zone = safe(try(GetRealZoneText)) or safe(try(GetZoneText))
  s.subzone = safe(try(GetSubZoneText))
  if C_Map then
    local id = safe(try(C_Map.GetBestMapForUnit, "player"))
    s.uiMapID = id
    if id then
      local pos = try(C_Map.GetPlayerMapPosition, id, "player")
      if pos then
        local x, y = try(pos.GetXY, pos)
        s.x, s.y = r1(safe(x) and x * 100), r1(safe(y) and y * 100)
      end
      local info = try(C_Map.GetMapInfo, id)
      if info then s.mapName = safe(info.name) end
    end
  end
end

local function Talents(s)
  local t = {}
  local n = safe(try(GetNumTalentTabs))
  if n and n > 0 then
    t.tabs = {}
    for i = 1, n do
      local a, b, c, d, e = try(GetTalentTabInfo, i)
      -- classic returns (name, icon, points, ...) or (id, name, desc, icon, points, ...)
      local name, pts
      if type(a) == "string" then name, pts = a, c else name, pts = b, e end
      t.tabs[#t.tabs + 1] = { name = safe(name), points = safe(pts) }
    end
  end
  local spec = safe(try(GetSpecialization))
  if spec and GetSpecializationInfo then
    local _, specName = try(GetSpecializationInfo, spec)
    t.spec = safe(specName)
  end
  if C_ClassTalents and C_ClassTalents.GetActiveConfigID then
    local cfg = safe(try(C_ClassTalents.GetActiveConfigID))
    if cfg and C_Traits then
      local ci = try(C_Traits.GetConfigInfo, cfg)
      if ci then t.loadout = safe(ci.name) end
    end
  end
  s.talents = t
end

-- Professions: crafting ones have recipes, gathering ones only a skill level.
-- Matched by skill line ID, or by name (enUS / zhCN) when the API gives no ID.
local KIND_BY_ID = {
  [197] = "crafting", [333] = "crafting", [171] = "crafting", [165] = "crafting", [164] = "crafting",
  [202] = "crafting", [755] = "crafting", [773] = "crafting", [185] = "crafting", [129] = "crafting",
  [356] = "gathering", [182] = "gathering", [186] = "gathering", [393] = "gathering",
}
local KIND_BY_NAME = {}
for kind, names in pairs({
  crafting = { "Tailoring", "Enchanting", "Alchemy", "Leatherworking", "Blacksmithing", "Engineering",
    "Jewelcrafting", "Inscription", "Cooking", "First Aid",
    "裁缝", "附魔", "炼金术", "炼金", "制皮", "锻造", "工程学", "工程", "珠宝加工", "珠宝", "铭文", "烹饪", "急救" },
  -- Smelting is Mining's window on classic clients.
  gathering = { "Fishing", "Herbalism", "Mining", "Skinning", "Smelting",
    "钓鱼", "草药学", "草药", "采矿", "剥皮", "熔炼" },
}) do
  for _, n in ipairs(names) do KIND_BY_NAME[n] = kind end
end

local function Kind(p)
  return (p.skillLine and KIND_BY_ID[p.skillLine]) or (p.parentSkillLine and KIND_BY_ID[p.parentSkillLine])
    or (p.name and KIND_BY_NAME[p.name]) or (p.parentName and KIND_BY_NAME[p.parentName])
end

-- Each tier is a trainer spell that raises the skill cap (Journeyman Skinning:
-- "使你获得150点的剥皮技能上限"), so the cap tells which tiers are learned. Blizzard's
-- PROFESSION_RANKS names the rank from the cap the same way. Chinese tier names vary
-- between translations (Journeyman is 中级 or 高级), so agents get the English key.
local TIERS = { { 75, "apprentice" }, { 150, "journeyman" }, { 225, "expert" }, { 300, "artisan" } }

local function Tier(p)
  local max = tonumber(p.max) or 0
  p.tier, p.nextTier = nil, nil
  for i, t in ipairs(TIERS) do
    if max >= t[1] then p.tier, p.nextTier = t[2], TIERS[i + 1] and TIERS[i + 1][2] end
  end
end

-- GetProfessionInfo, the Skills tab (C_SkillInfo) and the profession window
-- (C_TradeSkillUI) each report rank and cap; right after training or a login one can
-- lag behind the others, so keep the highest.
local function Raise(p, rank, max)
  rank, max = tonumber(rank), tonumber(max)
  if max and max > 0 then
    if max > (p.max or 0) then p.max = max end
    if rank and rank > (p.rank or 0) then p.rank = rank end
  end
end

local function SkillLevels(p)
  local id = p.skillLine
  if not id then return end
  if C_SkillInfo and C_SkillInfo.GetSkillLineInfoByID then
    local info = try(C_SkillInfo.GetSkillLineInfoByID, id)
    if type(info) == "table" then
      Raise(p, safe(info.rank), safe(info.maxRank))
      p.name = p.name or safe(info.name)
    end
  end
  if C_TradeSkillUI and C_TradeSkillUI.GetProfessionInfoBySkillLineID then
    local info = try(C_TradeSkillUI.GetProfessionInfoBySkillLineID, id)
    if type(info) == "table" then Raise(p, safe(info.skillLevel), safe(info.maxSkillLevel)) end
  end
end

-- Learned recipes ---------------------------------------------------------------
-- The game only exposes recipes while a profession window is open. Each snapshot
-- tries to read the open window; professions that can't be read keep the recipes
-- saved by an earlier snapshot.

local function ItemDetails(r, link)
  if type(link) ~= "string" then return end
  r.itemID = tonumber(link:match("item:(%d+)"))
  local getInfo = (C_Item and C_Item.GetItemInfo) or GetItemInfo
  local _, _, quality, itemLevel, reqLevel, itemType, itemSubType, _, equipLoc = try(getInfo, link)
  r.quality, r.itemLevel, r.reqLevel = safe(quality), safe(itemLevel), safe(reqLevel)
  r.itemType, r.itemSubType = safe(itemType), safe(itemSubType)
  if safe(equipLoc) and equipLoc ~= "" then r.slot = equipLoc end
end

-- C_TradeSkillUI (the open profession window). nil if nothing usable is open.
local function ReadTradeSkillUI()
  local T = C_TradeSkillUI
  if not (T and T.GetAllRecipeIDs and T.GetRecipeInfo) then return nil end
  -- A linked, guild or NPC window shows someone else's recipes.
  for _, check in ipairs({ "IsTradeSkillLinked", "IsTradeSkillGuild", "IsNPCCrafting" }) do
    if T[check] and try(T[check]) then return nil end
  end
  if T.IsTradeSkillReady and not try(T.IsTradeSkillReady) then return nil end
  local prof = {}
  if T.GetTradeSkillLine then
    local id, name, rank, maxRank, _, parentID, parentName = try(T.GetTradeSkillLine)
    prof.skillLine, prof.name, prof.rank, prof.max = safe(id), safe(name), safe(rank), safe(maxRank)
    prof.parentSkillLine, prof.parentName = safe(parentID), safe(parentName)
  elseif T.GetBaseProfessionInfo then
    local info = try(T.GetBaseProfessionInfo)
    if type(info) == "table" then
      prof.skillLine, prof.name = safe(info.professionID), safe(info.professionName)
      prof.rank, prof.max = safe(info.skillLevel), safe(info.maxSkillLevel)
    end
  end
  if not (prof.name or prof.skillLine) then return nil end
  local ids = try(T.GetAllRecipeIDs)
  if type(ids) ~= "table" or #ids == 0 then return nil end
  local recipes = {}
  for _, rid in ipairs(ids) do
    local info = try(T.GetRecipeInfo, rid)
    if type(info) == "table" and info.learned then
      local r = { recipeID = safe(rid), name = safe(info.name), difficulty = safe(info.difficulty) }
      local link
      if T.GetRecipeOutputItemData then
        local out = try(T.GetRecipeOutputItemData, rid)
        if type(out) == "table" then link = safe(out.hyperlink) or (safe(out.itemID) and ("item:" .. out.itemID)) end
      end
      if not link and T.GetRecipeItemLink then link = safe(try(T.GetRecipeItemLink, rid)) end
      ItemDetails(r, link)
      if r.name then recipes[#recipes + 1] = r end
    end
  end
  prof.recipes = recipes
  return prof
end

-- Classic trade skill API, for clients without C_TradeSkillUI. Only lists known recipes.
local function ReadClassicTradeSkill()
  if not (GetTradeSkillLine and GetNumTradeSkills and GetTradeSkillInfo) then return nil end
  if IsTradeSkillLinked and try(IsTradeSkillLinked) then return nil end
  local name, rank, maxRank = try(GetTradeSkillLine)
  name = safe(name)
  if not name or name == "UNKNOWN" then return nil end
  local n = safe(try(GetNumTradeSkills)) or 0
  if n == 0 then return nil end
  local recipes = {}
  for i = 1, n do
    local rname, kind = try(GetTradeSkillInfo, i)
    if safe(rname) and kind ~= "header" and kind ~= "subheader" then
      local r = { name = rname, difficulty = safe(kind) }
      ItemDetails(r, safe(try(GetTradeSkillItemLink, i)))
      recipes[#recipes + 1] = r
    end
  end
  return { name = name, rank = safe(rank), max = safe(maxRank), recipes = recipes }
end

-- Classic Craft API: Enchanting's window on classic-era clients. Beast Training uses
-- the same window but has no skill line, so it is skipped.
local function ReadClassicCraft()
  if not (GetNumCrafts and GetCraftInfo and GetCraftDisplaySkillLine) then return nil end
  local name, rank, maxRank = try(GetCraftDisplaySkillLine)
  name = safe(name)
  if not name or name == "UNKNOWN" then return nil end
  local n = safe(try(GetNumCrafts)) or 0
  if n == 0 then return nil end
  local recipes = {}
  for i = 1, n do
    local cname, _, kind = try(GetCraftInfo, i)
    if safe(cname) and kind ~= "header" then
      local r = { name = cname, difficulty = safe(kind) }
      ItemDetails(r, safe(try(GetCraftItemLink, i)))
      recipes[#recipes + 1] = r
    end
  end
  return { name = name, rank = safe(rank), max = safe(maxRank), recipes = recipes }
end

local function SameProfession(p, q)
  if p.skillLine and (p.skillLine == q.skillLine or p.skillLine == q.parentSkillLine) then return true end
  return p.name ~= nil and (p.name == q.name or p.name == q.parentName)
end

-- Fresh entries win; fields they lack (e.g. item info not cached yet) come from the
-- saved copy, and saved recipes the window didn't list are kept.
local function MergeRecipes(new, old)
  local saved = {}
  for _, r in ipairs(old) do local k = r.recipeID or r.name; if k then saved[k] = r end end
  local out, seen = {}, {}
  for _, r in ipairs(new) do
    local k = r.recipeID or r.name
    if k and not seen[k] then
      seen[k] = true
      if saved[k] then for f, v in pairs(saved[k]) do if r[f] == nil then r[f] = v end end end
      out[#out + 1] = r
    end
  end
  for _, r in ipairs(old) do
    local k = r.recipeID or r.name
    if k and not seen[k] then seen[k] = true; out[#out + 1] = r end
  end
  return out
end

local function Read(f) local ok, res = pcall(f); if ok then return res end end

-- Recipes live in AIPinRecipes, a per-character SavedVariable (its own file under
-- WTF/Account/<account>/<realm>/<character>/), so reading AIPinChars stays small.
-- AIPinChars only gets a recipeCount / recipesUpdated summary per profession.
local function RecipeStore()
  if type(AIPinRecipes) ~= "table" then AIPinRecipes = {} end
  if type(AIPinRecipes.professions) ~= "table" then AIPinRecipes.professions = {} end
  return AIPinRecipes.professions
end

-- recipeCount / recipesUpdated per profession, from the recipe store.
local function RecipeSummary(list)
  local store = RecipeStore()
  for _, p in ipairs(list) do
    local entry = p.name and store[p.name]
    if entry and p.kind ~= "gathering" and type(entry.recipes) == "table" then
      entry.kind, entry.skillLine, entry.rank, entry.max, entry.tier = p.kind, p.skillLine, p.rank, p.max, p.tier
      p.recipeCount, p.recipesUpdated = #entry.recipes, entry.recipesUpdated
    end
  end
end

local function Recipes(list, old)
  local store = RecipeStore()
  -- 1.4.0 / 1.4.1 kept recipes inside AIPinChars; move them over once.
  local before = type(old) == "table" and old.professions
  if type(before) == "table" then
    for _, q in ipairs(before) do
      if type(q) == "table" and type(q.recipes) == "table" and q.name and not store[q.name] and Kind(q) ~= "gathering" then
        store[q.name] = { recipes = q.recipes, recipesUpdated = q.recipesUpdated }
      end
    end
  end
  -- A trade skill window and (on classic) the Enchanting craft window can be open at once.
  local sources = { Read(ReadTradeSkillUI) or Read(ReadClassicTradeSkill), Read(ReadClassicCraft) }
  for i = 1, 2 do
    local open = sources[i]
    -- Gathering professions only need their skill level (e.g. skip Mining's smelting list).
    if open and Kind(open) ~= "gathering" then
      local hit
      for _, p in ipairs(list) do if SameProfession(p, open) then hit = p; break end end
      if not hit then
        hit = { name = open.parentName or open.name, rank = open.rank, max = open.max, skillLine = open.parentSkillLine or open.skillLine }
        hit.kind = Kind(hit)
        list[#list + 1] = hit
      end
      if hit.name then
        local entry = store[hit.name] or {}
        entry.recipes = type(entry.recipes) == "table" and MergeRecipes(open.recipes, entry.recipes) or open.recipes
        entry.recipesUpdated = time()
        store[hit.name] = entry
      end
    end
  end
end

local function Professions(s, old)
  local list, bySkill = {}, {}
  local function Add(p)
    if not (p.name or p.skillLine) then return end
    if p.skillLine and bySkill[p.skillLine] then return end
    if p.skillLine then bySkill[p.skillLine] = true end
    list[#list + 1] = p
  end
  if GetProfessions then
    -- Forever returns up to seven slots (two primary, then secondary skills); empty ones are nil.
    local ids = { try(GetProfessions) }
    for i = 1, 10 do
      local idx = ids[i]
      if idx then
        local name, _, rank, maxRank, _, _, skillLine = try(GetProfessionInfo, idx)
        if safe(name) then
          local p = { name = safe(name), skillLine = safe(skillLine) }
          Raise(p, safe(rank), safe(maxRank))
          Add(p)
        end
      end
    end
  end
  -- The Skills tab knows every profession by ID, including any GetProfessions left out.
  if C_SkillInfo and C_SkillInfo.GetSkillLineInfoByID then
    for id in pairs(KIND_BY_ID) do
      if not bySkill[id] then
        local info = try(C_SkillInfo.GetSkillLineInfoByID, id)
        if type(info) == "table" and (tonumber(safe(info.maxRank)) or 0) > 0 then
          Add({ name = safe(info.name), skillLine = id })
        end
      end
    end
  end
  if #list == 0 and GetNumSkillLines and GetSkillLineInfo then
    -- Classic skill frame: keep professions, drop weapon skills, languages and the like.
    local n = safe(try(GetNumSkillLines)) or 0
    for i = 1, n do
      local name, isHeader, _, rank, _, _, maxRank, isAbandonable = try(GetSkillLineInfo, i)
      name = safe(name)
      if name and not isHeader and (KIND_BY_NAME[name] or isAbandonable) then
        local p = { name = name }
        Raise(p, safe(rank), safe(maxRank))
        Add(p)
      end
    end
  end
  for _, p in ipairs(list) do SkillLevels(p); p.kind = Kind(p) end
  pcall(Recipes, list, old)
  s.professions = list
end

local function Quests(s)
  local list = {}
  local Q = C_QuestLog
  if Q and Q.GetNumQuestLogEntries then
    local n = safe(try(Q.GetNumQuestLogEntries)) or 0
    for i = 1, n do
      local info = try(Q.GetInfo, i)
      if info and not info.isHeader and not info.isHidden then
        local id = safe(info.questID)
        local q = { questID = id, title = safe(info.title), level = safe(info.level) }
        if id then
          q.isComplete = (safe(try(Q.IsComplete, id)) and true) or false
          local objs = try(Q.GetQuestObjectives, id)
          if type(objs) == "table" then
            q.objectives = {}
            for _, o in ipairs(objs) do
              q.objectives[#q.objectives+1] = { text = safe(o.text), have = safe(o.numFulfilled), need = safe(o.numRequired), done = safe(o.finished) }
            end
          end
        end
        list[#list+1] = q
      end
    end
  elseif GetNumQuestLogEntries then
    local n = safe(try(GetNumQuestLogEntries)) or 0
    for i = 1, n do
      local title, level, _, isHeader, _, isComplete, _, questID = try(GetQuestLogTitle, i)
      if title and not isHeader then list[#list+1] = { questID = safe(questID), title = safe(title), level = safe(level), isComplete = isComplete == 1 or isComplete == true } end
    end
  end
  s.quests = list
end

local function Gear(s)
  local g = {}
  for _, slot in ipairs(SLOTS) do
    local id = try(GetInventorySlotInfo, slot)
    if id then
      local link = safe(try(GetInventoryItemLink, "player", id))
      if link then
        -- itemID + name is all an assistant needs; full item links are long.
        local e = { itemID = tonumber(link:match("item:(%d+)")), name = safe(link:match("%[(.-)%]")) }
        if C_Item and C_Item.GetDetailedItemLevelInfo then e.itemLevel = safe(try(C_Item.GetDetailedItemLevelInfo, link))
        elseif GetDetailedItemLevelInfo then e.itemLevel = safe(try(GetDetailedItemLevelInfo, link)) end
        g[slot] = e
      end
    end
  end
  s.equipment = g
end

local function Bags(s)
  local free, total = 0, 0
  local C = C_Container
  for b = 0, 4 do
    local f = safe(C and try(C.GetContainerNumFreeSlots, b) or try(GetContainerNumFreeSlots, b))
    local t = safe(C and try(C.GetContainerNumSlots, b) or try(GetContainerNumSlots, b))
    free = free + (f or 0); total = total + (t or 0)
  end
  s.bagFree, s.bagTotal = free, total
end

-- Realm without spaces or hyphens, whichever API answers. GetNormalizedRealmName
-- can return nil (e.g. at logout); falling back to the spaced name used to save a
-- second copy of the same character.
local function Realm(r) return type(r) == "string" and (r:gsub("[%s%-]", "")) or nil end
local function RealmKey() return Realm(safe(try(GetNormalizedRealmName))) or Realm(safe(try(GetRealmName))) or "?" end

-- Data readiness ----------------------------------------------------------------
-- Right after login or a reload, XP, money, gear, professions and quest details can
-- read as 0 / empty for a few seconds. The PLAYER_LOGOUT snapshot is the one the game
-- writes to disk, and one has come out with an empty XP bar under the level from
-- before a level-up. A snapshot taken at either time must not wipe a good one.

local function Empty(t) return type(t) ~= "table" or next(t) == nil end

local function AtMaxLevel(s)
  if try(IsPlayerAtEffectiveMaxLevel) then return true end
  local cap = safe(try(GetMaxPlayerLevel)) or safe(MAX_PLAYER_LEVEL)
  return (cap and s.level and s.level >= cap) or false
end

-- An XP read is good once the bar has a max; it has none at the level cap.
local function XPRead(s) return (s.level or 0) > 0 and ((s.xpMax or 0) > 0 or AtMaxLevel(s)) end

-- Whether the APIs had loaded when s was read (checked before merging in old data).
local function Complete(s)
  local rest = not Empty(s.equipment) or not Empty(s.professions) or (s.bagTotal or 0) > 0
  return (XPRead(s) and rest) and true or false
end

-- The best reads of this session. Lua state starts over on every login and reload,
-- so these always belong to the character being played.
local seen = { prof = {} }

-- XP never goes backwards, so a read behind the best one this session is stale.
local function Behind(a, b)
  if (a.level or 0) ~= (b.level or 0) then return (a.level or 0) < (b.level or 0) end
  return (a.xp or 0) < (b.xp or 0)
end

-- level, xp, xpMax and restXP always come from the same good read.
local function SettleXP(s, old)
  local read = { level = s.level, xp = s.xp, xpMax = s.xpMax, restXP = s.restXP }
  if XPRead(read) and not (seen.xp and Behind(read, seen.xp)) then seen.xp = read end
  local g = seen.xp
  -- Nothing good yet this session (just logged in): the saved bar, if it is for this level.
  if not g and old and XPRead(old) and ((s.level or 0) == 0 or s.level == old.level) then g = old end
  -- seen.level is the level PLAYER_LEVEL_UP announced, which UnitLevel can lag behind.
  local level = math.max(s.level or 0, g and g.level or 0, seen.level or 0)
  if g and g.level == level then
    s.level, s.xp, s.xpMax, s.restXP = g.level, g.xp, g.xpMax, g.restXP
  else
    -- A new level whose bar hasn't read yet: leave XP out rather than save 0 or the old bar.
    s.level = level > 0 and level or nil
    s.xp, s.xpMax, s.restXP = nil, nil, nil
  end
end

-- The location fields come from one read that found the player on a map; a read
-- without one (logout, some interiors) keeps the last read that had one.
local LOCATION = { "zone", "subzone", "uiMapID", "mapName", "x", "y" }
local function SettleLocation(s, old)
  if s.uiMapID then
    seen.loc = {}
    for _, k in ipairs(LOCATION) do seen.loc[k] = s[k] end
    return
  end
  local g = seen.loc or (old and old.uiMapID and old)
  if g then for _, k in ipairs(LOCATION) do s[k] = g[k] end end
end

-- The list read now says which professions are learned. A rank or cap that reads 0
-- comes from this session's best read or the saved entry; one that falls behind this
-- session's best is stale (skill and caps only go up while a profession is kept).
local function SettleProfessions(s, old)
  local list = s.professions
  local before = old and type(old.professions) == "table" and old.professions or {}
  if Empty(list) then
    -- Not loaded yet: keep the saved list. Recipes live in AIPinRecipes, not here.
    list = {}
    for _, p in ipairs(before) do
      if type(p) == "table" then
        local c = {}
        for k, v in pairs(p) do if k ~= "recipes" then c[k] = v end end
        list[#list + 1] = c
      end
    end
  else
    local best = {}
    for _, p in ipairs(list) do
      local key = p.skillLine or p.name
      local top = seen.prof[key]
      if (p.max or 0) == 0 then
        local o = top
        if not o then
          for _, q in ipairs(before) do if type(q) == "table" and SameProfession(p, q) then o = q; break end end
        end
        if o then p.rank, p.max = o.rank, o.max end
      elseif top and (p.max < top.max or (p.max == top.max and (p.rank or 0) < (top.rank or 0))) then
        p.rank, p.max = top.rank, top.max
      end
      if (p.max or 0) > 0 then best[key] = { rank = p.rank, max = p.max } end
    end
    -- A profession missing from a list that did load was unlearned; forget its best.
    seen.prof = best
  end
  for _, p in ipairs(list) do Tier(p) end
  pcall(RecipeSummary, list)
  s.professions = list
end

local function TalentPoints(t)
  local n = 0
  if type(t) == "table" and type(t.tabs) == "table" then
    for _, tab in ipairs(t.tabs) do n = n + (tonumber(tab.points) or 0) end
  end
  return n
end

-- Fill the other fields that read empty in s from the previous snapshot.
local function Merge(s, old, complete)
  if old.money and (s.money == nil or (s.money == 0 and not complete)) then s.money = old.money end
  -- GetGuildInfo answers nil until the guild roster loads; IsInGuild knows sooner.
  if not s.guild and old.guild and try(IsInGuild) then s.guild = old.guild end
  if Empty(s.equipment) and not Empty(old.equipment) then
    s.equipment = old.equipment
  elseif type(s.equipment) == "table" and type(old.equipment) == "table" then
    -- An item's name and level can be missing until it is cached.
    for slot, e in pairs(s.equipment) do
      local o = old.equipment[slot]
      if type(o) == "table" and o.itemID == e.itemID then
        if not e.name or e.name == "" then e.name = o.name end
        if e.itemLevel == nil then e.itemLevel = o.itemLevel end
      end
    end
  end
  if (s.bagTotal or 0) == 0 and (tonumber(old.bagTotal) or 0) > 0 then
    s.bagFree, s.bagTotal = old.bagFree, old.bagTotal
  end
  if not Empty(old.talents) and (Empty(s.talents)
      or (not complete and TalentPoints(s.talents) == 0 and TalentPoints(old.talents) > 0)) then
    s.talents = old.talents
  end
  if type(old.quests) == "table" then
    if Empty(s.quests) and not complete then
      s.quests = old.quests
    elseif type(s.quests) == "table" then
      local byID = {}
      for _, q in ipairs(old.quests) do if type(q) == "table" and q.questID then byID[q.questID] = q end end
      for _, q in ipairs(s.quests) do
        local o = q.questID and byID[q.questID]
        if o then
          if Empty(q.objectives) and not Empty(o.objectives) then q.objectives = o.objectives end
          if (q.level or 0) == 0 and (tonumber(o.level) or 0) > 0 then q.level = o.level end
        end
      end
    end
  end
end

-- Returns true when the game's data had loaded (see Complete).
local function Snapshot()
  if type(AIPinChars) ~= "table" then AIPinChars = {} end
  local name = safe(try(UnitName, "player"))
  if not name then return end
  local realm = RealmKey()
  local key = name .. "-" .. realm
  local s = { name = name, realm = realm }
  s.race = safe(try(UnitRace, "player"))
  s.class = safe(try(UnitClass, "player"))
  s.sex = ({ [2] = "male", [3] = "female" })[safe(try(UnitSex, "player"))] or "unknown"
  s.level = safe(try(UnitLevel, "player"))
  s.xp = safe(try(UnitXP, "player")); s.xpMax = safe(try(UnitXPMax, "player"))
  s.restXP = safe(try(GetXPExhaustion)) or 0
  s.money = safe(try(GetMoney))
  s.guild = safe(try(GetGuildInfo, "player"))
  s.hearth = safe(try(GetBindLocation))
  local old = AIPinChars[key]
  -- Fold in copies saved under the spaced realm name; keep the newest as "old".
  for k, v in pairs(AIPinChars) do
    if k ~= key and type(v) == "table" and v.name == name and Realm(v.realm) == realm then
      if not old or (tonumber(v.updated) or 0) > (tonumber(old.updated) or 0) then old = v end
      AIPinChars[k] = nil
    end
  end
  if type(old) ~= "table" then old = nil end
  if old then s.timePlayed, s.timePlayedLevel = old.timePlayed, old.timePlayedLevel end
  for _, f in ipairs({ Location, Talents, Professions, Quests, Gear, Bags }) do pcall(f, s, old) end
  local complete = Complete(s)
  for _, f in ipairs({ SettleXP, SettleLocation, SettleProfessions }) do pcall(f, s, old) end
  if old then pcall(Merge, s, old, complete) end
  s.updated = time()
  s.updatedText = date("%Y-%m-%d %H:%M:%S")
  AIPinChars[key] = s
  AIPin_LastChar = s
  return complete
end

local pending, lastRun, scheduled = false, 0, false
local function Request(force)
  if InCombatLockdown and InCombatLockdown() then pending = true; return end
  local now = GetTime()
  if force or now - lastRun >= 5 then
    lastRun = now
    local ok, complete = pcall(Snapshot)
    return ok and complete or false
  end
  if not scheduled and C_Timer then
    scheduled = true
    C_Timer.After(5 - (now - lastRun) + 0.1, function() scheduled = false; Request() end)
  end
end
-- Returns true when the snapshot found the character's data loaded.
AIPin_SnapshotNow = function() return Request(true) end

-- After a login, reload or loading screen, snapshot every 2s until the data has
-- loaded (or ~20s pass), so the saved copy is a complete one.
local settling = false
local function Settle(tries)
  if Request(true) or tries >= 10 then settling = false; return end
  C_Timer.After(2, function() Settle(tries + 1) end)
end

local f = CreateFrame("Frame")
for _, e in ipairs({ "PLAYER_LOGIN","PLAYER_ENTERING_WORLD","PLAYER_LEVEL_UP","PLAYER_XP_UPDATE","UPDATE_EXHAUSTION",
  "QUEST_LOG_UPDATE","ZONE_CHANGED_NEW_AREA","PLAYER_MONEY","SKILL_LINES_CHANGED","PLAYER_EQUIPMENT_CHANGED",
  "PLAYER_LOGOUT","PLAYER_REGEN_ENABLED","TIME_PLAYED_MSG",
  -- Profession window open/updated: the only time recipes can be read. Not every
  -- client has every event; unknown ones are skipped by the pcall.
  "TRADE_SKILL_SHOW","TRADE_SKILL_LIST_UPDATE","TRADE_SKILL_DATA_SOURCE_CHANGED","TRADE_SKILL_UPDATE",
  "CRAFT_SHOW","CRAFT_UPDATE" }) do
  pcall(f.RegisterEvent, f, e)
end
f:SetScript("OnEvent", function(_, ev, a1, a2)
  if ev == "PLAYER_LOGIN" or ev == "PLAYER_ENTERING_WORLD" then
    if not C_Timer then Request(true)
    elseif not settling then settling = true; C_Timer.After(3, function() Settle(0) end) end
  elseif ev == "PLAYER_LEVEL_UP" then
    -- UnitLevel can still answer the old level during this event; a1 is the new one.
    seen.level = math.max(seen.level or 0, tonumber(safe(a1)) or 0)
    if C_Timer then C_Timer.After(1, function() Request(true) end) else Request(true) end
  elseif ev == "PLAYER_LOGOUT" then
    pcall(Snapshot)  -- final, even if in combat; fields guarded
  elseif ev == "PLAYER_REGEN_ENABLED" then
    if pending then pending = false; Request(true) end
  elseif ev == "TIME_PLAYED_MSG" then
    local key = (safe(try(UnitName, "player")) or "?") .. "-" .. RealmKey()
    if type(AIPinChars) == "table" and AIPinChars[key] then
      AIPinChars[key].timePlayed, AIPinChars[key].timePlayedLevel = safe(a1), safe(a2)
    end
  else
    Request()
  end
end)
