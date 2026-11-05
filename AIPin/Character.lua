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

local function Recipes(list, old)
  local ok, open = pcall(ReadTradeSkillUI)
  if not (ok and open) then ok, open = pcall(ReadClassicTradeSkill) end
  if ok and open then
    local hit
    for _, p in ipairs(list) do if SameProfession(p, open) then hit = p; break end end
    if not hit then
      hit = { name = open.parentName or open.name, rank = open.rank, max = open.max, skillLine = open.parentSkillLine or open.skillLine }
      list[#list + 1] = hit
    end
    hit.recipes, hit.recipesUpdated = open.recipes, time()
  end
  local before = type(old) == "table" and old.professions
  if type(before) ~= "table" then return end
  for _, p in ipairs(list) do
    for _, q in ipairs(before) do
      if type(q) == "table" and type(q.recipes) == "table" and SameProfession(p, q) then
        p.recipes = p.recipes and MergeRecipes(p.recipes, q.recipes) or q.recipes
        p.recipesUpdated = p.recipesUpdated or q.recipesUpdated
        break
      end
    end
  end
end

local function Professions(s, old)
  local list = {}
  local got = false
  if GetProfessions then
    local ids = { try(GetProfessions) }
    for i = 1, 6 do
      local idx = ids[i]
      if idx then
        local name, _, rank, maxRank, _, _, skillLine = try(GetProfessionInfo, idx)
        if name then got = true; list[#list+1] = { name = safe(name), rank = safe(rank), max = safe(maxRank), skillLine = safe(skillLine) } end
      end
    end
  end
  if not got and GetNumSkillLines then
    local n = safe(try(GetNumSkillLines)) or 0
    for i = 1, n do
      local name, isHeader, _, rank, _, _, maxRank = try(GetSkillLineInfo, i)
      if name and not isHeader then list[#list+1] = { name = safe(name), rank = safe(rank), max = safe(maxRank) } end
    end
  end
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
        local e = { link = link, name = safe(link:match("%[(.-)%]")) }
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

local function Snapshot()
  if type(AIPinChars) ~= "table" then AIPinChars = {} end
  local name = safe(try(UnitName, "player"))
  if not name then return end
  local realm = safe(try(GetNormalizedRealmName)) or safe(try(GetRealmName)) or "?"
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
  if old then s.timePlayed, s.timePlayedLevel = old.timePlayed, old.timePlayedLevel end
  for _, f in ipairs({ Location, Talents, Professions, Quests, Gear, Bags }) do pcall(f, s, old) end
  s.updated = time()
  s.updatedText = date("%Y-%m-%d %H:%M:%S")
  AIPinChars[key] = s
  AIPin_LastChar = s
end

local pending, lastRun, scheduled = false, 0, false
local function Request(force)
  if InCombatLockdown and InCombatLockdown() then pending = true; return end
  local now = GetTime()
  if force or now - lastRun >= 5 then lastRun = now; pcall(Snapshot); return end
  if not scheduled and C_Timer then
    scheduled = true
    C_Timer.After(5 - (now - lastRun) + 0.1, function() scheduled = false; Request() end)
  end
end
AIPin_SnapshotNow = function() Request(true) end

local f = CreateFrame("Frame")
for _, e in ipairs({ "PLAYER_LOGIN","PLAYER_ENTERING_WORLD","PLAYER_LEVEL_UP","QUEST_LOG_UPDATE","ZONE_CHANGED_NEW_AREA",
  "PLAYER_MONEY","SKILL_LINES_CHANGED","PLAYER_EQUIPMENT_CHANGED","PLAYER_LOGOUT","PLAYER_REGEN_ENABLED","TIME_PLAYED_MSG",
  -- Profession window open/updated: the only time recipes can be read. Not every
  -- client has every event; unknown ones are skipped by the pcall.
  "TRADE_SKILL_SHOW","TRADE_SKILL_LIST_UPDATE","TRADE_SKILL_DATA_SOURCE_CHANGED","TRADE_SKILL_UPDATE" }) do
  pcall(f.RegisterEvent, f, e)
end
f:SetScript("OnEvent", function(_, ev, a1, a2)
  if ev == "PLAYER_LOGIN" or ev == "PLAYER_ENTERING_WORLD" then
    if C_Timer then C_Timer.After(3, function() Request(true) end) else Request(true) end
  elseif ev == "PLAYER_LOGOUT" then
    pcall(Snapshot)  -- final, even if in combat; fields guarded
  elseif ev == "PLAYER_REGEN_ENABLED" then
    if pending then pending = false; Request(true) end
  elseif ev == "TIME_PLAYED_MSG" then
    local key = (safe(try(UnitName, "player")) or "?") .. "-" .. (safe(try(GetNormalizedRealmName)) or safe(try(GetRealmName)) or "?")
    if type(AIPinChars) == "table" and AIPinChars[key] then
      AIPinChars[key].timePlayed, AIPinChars[key].timePlayedLevel = safe(a1), safe(a2)
    end
  else
    Request(ev == "PLAYER_LEVEL_UP")
  end
end)
