--[[
  AIPin — paste /aipin commands from your assistant to pin NPCs on the map.
]]

local ADDON = "AIPin"
local MAX_PINS = 20

AIPinDB = AIPinDB or {}

local L = {
  pinned = "|cffffd100AIPin:|r 已标记 %s (%s %.1f, %.1f) — 按 M 打开地图",
  cleared = "|cffffd100AIPin:|r 已清除全部标记",
  listEmpty = "|cffffd100AIPin:|r 当前没有标记",
  listHeader = "|cffffd100AIPin:|r 当前标记:",
  listItem = "  %d) %s — %s (%.1f, %.1f)",
  badArgs = "|cffffd100AIPin:|r 用法: /aipin [区域] <x> <y> [名称]  |  /aipin clear  |  /aipin list",
  noMap = "|cffffd100AIPin:|r 无法解析地图，请带上区域名，例如: /aipin 丹莫罗 44.1 57.1 巡山人格雷琴",
  unknownZone = "|cffffd100AIPin:|r 未知区域: %s（改用当前地图）",
  waypoint = "|cffffd100AIPin:|r 导航点已设为 %s (%s %.1f, %.1f)",
  noWaypoint = "|cffffd100AIPin:|r %s 不能设置导航点",
  help = "|cffffd100AIPin|r 用法:\n  /aipin [区域] <x> <y> [名称]\n  /aipin clear — 清除标记\n  /aipin list — 列出标记\n  /aipin me — 查看角色信息\n  /aipin sync — 同步（保存并重载界面）\n  /aipin minimap — 显示/隐藏小地图按钮\n  /aipin todo <内容> [@ 区域 [x y]] — 添加待办/区域或地理提醒\n  /aipin todos | done N | undone N | deltodo N | cleartodos\n示例: /aipin 丹莫罗 44.1 57.1 巡山人格雷琴",
}

-- Forever uiMapIDs (EN + ZH). Source: forever.azerpug.com/zones
local ZONE = {
  ["dun morogh"] = 1426, ["丹莫罗"] = 1426,
  ["ironforge"] = 1455, ["ironforge city"] = 1455, ["铁炉堡"] = 1455,
  ["elwynn forest"] = 1429, ["elwynn"] = 1429, ["艾尔文森林"] = 1429,
  ["stormwind"] = 1453, ["stormwind city"] = 1453, ["暴风城"] = 1453,
  ["loch modan"] = 1432, ["洛克莫丹"] = 1432,
  ["westfall"] = 1436, ["西部荒野"] = 1436,
  ["redridge mountains"] = 1433, ["redridge"] = 1433, ["赤脊山"] = 1433,
  ["duskwood"] = 1431, ["暮色森林"] = 1431,
  ["wetlands"] = 1437, ["湿地"] = 1437,
  ["darkshore"] = 1439, ["黑海岸"] = 1439,
  ["teldrassil"] = 1438, ["泰达希尔"] = 1438,
  ["darnassus"] = 1457, ["达纳苏斯"] = 1457,
  ["tirisfal glades"] = 1420, ["tirisfal"] = 1420, ["提瑞斯法林地"] = 1420, ["提瑞斯法"] = 1420,
  ["undercity"] = 1458, ["幽暗城"] = 1458,
  ["silverpine forest"] = 1421, ["silverpine"] = 1421, ["银松森林"] = 1421,
  ["hillsbrad foothills"] = 1424, ["hillsbrad"] = 1424, ["希尔斯布莱德丘陵"] = 1424, ["希尔斯布莱德"] = 1424,
  ["arathi highlands"] = 1417, ["arathi"] = 1417, ["阿拉希高地"] = 1417,
  ["hinterlands"] = 1425, ["the hinterlands"] = 1425, ["辛特兰"] = 1425,
  ["badlands"] = 1418, ["荒芜之地"] = 1418,
  ["searing gorge"] = 1427, ["灼热峡谷"] = 1427,
  ["burning steppes"] = 1428, ["燃烧平原"] = 1428,
  ["swamp of sorrows"] = 1435, ["悲伤沼泽"] = 1435,
  ["blasted lands"] = 1419, ["诅咒之地"] = 1419,
  ["deadwind pass"] = 1430, ["逆风小径"] = 1430,
  ["stranglethorn vale"] = 1434, ["stranglethorn"] = 1434, ["荆棘谷"] = 1434,
  ["eastern plaguelands"] = 1423, ["东瘟疫之地"] = 1423,
  ["western plaguelands"] = 1422, ["西瘟疫之地"] = 1422,
  ["alterac mountains"] = 1416, ["奥特兰克山脉"] = 1416,
  ["durotar"] = 1411, ["杜隆塔尔"] = 1411,
  ["mulgore"] = 1412, ["莫高雷"] = 1412,
  ["the barrens"] = 1413, ["barrens"] = 1413, ["贫瘠之地"] = 1413,
  ["orgrimmar"] = 1454, ["奥格瑞玛"] = 1454,
  ["thunder bluff"] = 1456, ["雷霆崖"] = 1456,
  ["ashenvale"] = 1440, ["灰谷"] = 1440,
  ["stonetalon mountains"] = 1442, ["石爪山脉"] = 1442,
  ["desolace"] = 1443, ["凄凉之地"] = 1443,
  ["dustwallow marsh"] = 1445, ["尘泥沼泽"] = 1445,
  ["feralas"] = 1444, ["菲拉斯"] = 1444,
  ["thousand needles"] = 1441, ["千针石林"] = 1441,
  ["tanaris"] = 1446, ["塔纳利斯"] = 1446,
  ["ungoro crater"] = 1449, ["un'goro crater"] = 1449, ["安戈洛环形山"] = 1449,
  ["silithus"] = 1451, ["希利苏斯"] = 1451,
  ["winterspring"] = 1452, ["冬泉谷"] = 1452,
  ["felwood"] = 1448, ["费伍德森林"] = 1448,
  ["azshara"] = 1447, ["艾萨拉"] = 1447,
  ["moonglade"] = 1450, ["月光林地"] = 1450,
}

local function Print(msg)
  DEFAULT_CHAT_FRAME:AddMessage(msg)
end

local function Trim(s)
  return (s or ""):gsub("^%s+", ""):gsub("%s+$", "")
end

local function Normalize(s)
  return Trim(s):lower()
end

local function MapName(uiMapID)
  if C_Map and C_Map.GetMapInfo then
    local info = C_Map.GetMapInfo(uiMapID)
    if info and info.name then return info.name end
  end
  return tostring(uiMapID)
end

local function ResolveZone(name)
  if not name or name == "" then return nil end
  local key = Normalize(name)
  if ZONE[key] then return ZONE[key] end
  for k, id in pairs(ZONE) do
    if key:find(k, 1, true) or k:find(key, 1, true) then
      return id
    end
  end
  if C_Map and C_Map.GetMapInfo then
    local seen = {}
    for _, id in pairs(ZONE) do
      if not seen[id] then
        seen[id] = true
        local info = C_Map.GetMapInfo(id)
        if info and info.name and Normalize(info.name) == key then
          return id
        end
      end
    end
  end
  return nil
end

local function EnsureDB()
  AIPinDB = AIPinDB or {}
  AIPinDB.pins = AIPinDB.pins or {}
end

local function PlayerMapID()
  return C_Map and C_Map.GetBestMapForUnit and C_Map.GetBestMapForUnit("player")
end

local function RefreshPanel()
  if AIPin_RefreshPanel then AIPin_RefreshPanel() end
end

-- Blizzard's own waypoint always says "地图标记分享" (Map Pin). We remember the
-- title of the pin we set and show it on the waypoint's tooltip and under the
-- on-screen navigation marker.
local activeTitle

local function CurrentWaypointTitle()
  if not activeTitle then return nil end
  if C_Map and C_Map.GetUserWaypoint then
    local wp = C_Map.GetUserWaypoint()
    if not wp or not wp.position then return nil end
    local a = activeTitle
    if wp.uiMapID ~= a.uiMapID then return nil end
    if math.abs(wp.position.x - a.x) > 0.002 or math.abs(wp.position.y - a.y) > 0.002 then
      return nil
    end
  end
  return activeTitle.title
end

local function IsWaypointOwner(owner)
  if not owner then return false end
  if owner.pinTemplate == "WaypointLocationPinTemplate" then return true end
  if SuperTrackedFrame and owner == SuperTrackedFrame then return true end
  return false
end

local hudLabel
local function UpdateHudLabel()
  if not SuperTrackedFrame then return end
  if not hudLabel then
    hudLabel = SuperTrackedFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    local anchor = SuperTrackedFrame.Icon or SuperTrackedFrame
    hudLabel:SetPoint("BOTTOM", anchor, "TOP", 0, 4)
    hudLabel:SetTextColor(1, 0.82, 0)
  end
  local t = CurrentWaypointTitle()
  if t and C_SuperTrack and C_SuperTrack.IsSuperTrackingUserWaypoint
     and C_SuperTrack.IsSuperTrackingUserWaypoint() then
    hudLabel:SetText(t)
    hudLabel:Show()
  else
    hudLabel:Hide()
  end
end

local tooltipHooked
local function HookWaypointTooltip()
  if tooltipHooked or not GameTooltip then return end
  tooltipHooked = true
  GameTooltip:HookScript("OnShow", function(tt)
    local ok, owner = pcall(tt.GetOwner, tt)
    if not ok or not IsWaypointOwner(owner) then return end
    local t = CurrentWaypointTitle()
    if t then
      local first = _G[tt:GetName() .. "TextLeft1"]
      if first then first:SetText(t) end
      tt:AddLine("AIPin", 0.5, 0.8, 1)
      tt:Show()
    end
  end)
  local ev = CreateFrame("Frame")
  ev:RegisterEvent("USER_WAYPOINT_UPDATED")
  ev:RegisterEvent("SUPER_TRACKING_CHANGED")
  ev:SetScript("OnEvent", function()
    UpdateHudLabel()
    RefreshPanel() -- the pin list marks which pin has the waypoint
  end)
end

-- x, y are 0-1. manual = the player chose this pin, so a /reload keeps it.
local function SetNativeWaypoint(uiMapID, x, y, title, manual)
  if not (C_Map and UiMapPoint and C_Map.CanSetUserWaypointOnMap and C_Map.SetUserWaypoint) then
    return false
  end
  local ok, can = pcall(C_Map.CanSetUserWaypointOnMap, uiMapID)
  if not ok or not can then return false end
  local point = UiMapPoint.CreateFromCoordinates(uiMapID, x, y)
  if not point then return false end
  -- Title first: USER_WAYPOINT_UPDATED can fire inside SetUserWaypoint.
  local prev = activeTitle
  activeTitle = { uiMapID = uiMapID, x = x, y = y, title = title, manual = manual or nil }
  HookWaypointTooltip()
  local set, wasSet = pcall(C_Map.SetUserWaypoint, point)
  if not set or wasSet == false then
    activeTitle = prev
    return false
  end
  EnsureDB()
  AIPinDB.activeWaypoint = activeTitle
  -- Track it, so the on-screen marker and distance follow this pin.
  if C_SuperTrack and C_SuperTrack.SetSuperTrackedUserWaypoint then
    pcall(C_SuperTrack.SetSuperTrackedUserWaypoint, true)
  end
  UpdateHudLabel()
  return true
end

-- Does the Blizzard waypoint sit on this saved pin (x, y in map percent)?
local function IsWaypointPin(p)
  if not (p and p.x and p.y and C_Map and C_Map.GetUserWaypoint) then return false end
  local wp = C_Map.GetUserWaypoint()
  if not wp or not wp.position or wp.uiMapID ~= p.uiMapID then return false end
  return math.abs(wp.position.x - p.x / 100) <= 0.002 and math.abs(wp.position.y - p.y / 100) <= 0.002
end

-- Point the waypoint at a saved pin because the player asked to (panel row or map icon).
local function WaypointTo(p)
  if not (p and p.uiMapID and p.x and p.y) then return false end
  if SetNativeWaypoint(p.uiMapID, p.x / 100, p.y / 100, p.title, true) then
    Print(string.format(L.waypoint, p.title or "AIPin", MapName(p.uiMapID), p.x, p.y))
    -- If the world map is open on another map, go to the pin's so its waypoint marker shows.
    local wm = WorldMapFrame
    if wm and wm:IsShown() and wm.GetMapID and wm.SetMapID and wm:GetMapID() ~= p.uiMapID
       and not (InCombatLockdown and InCombatLockdown()) then
      pcall(wm.SetMapID, wm, p.uiMapID)
    end
    RefreshPanel()
    return true
  end
  Print(string.format(L.noWaypoint, MapName(p.uiMapID)))
  return false
end

-- The waypoint marks one place only. Use the newest pin on the map the player is
-- on, so it points somewhere they can walk to; if none is here, the newest pin.
local function PickWaypoint()
  EnsureDB()
  local pins, here, order = AIPinDB.pins, PlayerMapID(), {}
  for i = #pins, 1, -1 do
    if pins[i].uiMapID == here then order[#order + 1] = pins[i] end
  end
  for i = #pins, 1, -1 do
    if pins[i].uiMapID ~= here then order[#order + 1] = pins[i] end
  end
  -- Some maps refuse a waypoint; move on to the next pin.
  for _, p in ipairs(order) do
    if p.x and p.y and SetNativeWaypoint(p.uiMapID, p.x / 100, p.y / 100, p.title) then return p end
  end
end

-- After login/reload: keep a waypoint the player picked themselves (unless new
-- pins just came in), otherwise pick one for where they are now.
local function RestoreWaypoint(imported)
  EnsureDB()
  if #AIPinDB.pins == 0 then return end
  local a = AIPinDB.activeWaypoint
  if not imported and a and a.manual and a.x and a.y then
    for _, p in ipairs(AIPinDB.pins) do
      if p.uiMapID == a.uiMapID and math.abs(p.x / 100 - a.x) <= 0.002 and math.abs(p.y / 100 - a.y) <= 0.002
         and SetNativeWaypoint(p.uiMapID, p.x / 100, p.y / 100, p.title, true) then
        return
      end
    end
  end
  PickWaypoint()
end

-- Own map pins ---------------------------------------------------------
-- One AIPin icon per saved pin on the map being viewed. The map redraws them on
-- open and on every map change; frames are pooled because WoW never frees them.
local ICON = "Interface\\AddOns\\AIPin\\media\\icon"
local NEAR = 1.5 -- map percent; icons this close overlap, so their tooltips list each other
local provider
local pinFrames, pinsUsed = {}, 0

-- Above explored-area overlays (they would cover the icon), below the player arrow.
local function PinFrameLevel(map)
  local ok, level = pcall(function()
    local m = map:GetPinFrameLevelsManager()
    if m.definitions and m.definitions.PIN_FRAME_LEVEL_AREA_POI then
      return m:GetValidFrameLevel("PIN_FRAME_LEVEL_AREA_POI")
    end
    return m:GetValidFrameLevel("PIN_FRAME_LEVEL_TOPMOST")
  end)
  if ok and type(level) == "number" then return level end
  return map:GetCanvas():GetFrameLevel() + 10
end

local function PinTooltip(self)
  local p = self.aipin
  if not p then return end
  GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
  GameTooltip:SetText(p.title or "AIPin", 1, 0.82, 0)
  GameTooltip:AddLine(MapName(p.uiMapID), 0.8, 0.8, 0.8)
  GameTooltip:AddLine(string.format("%.1f, %.1f", p.x or 0, p.y or 0), 1, 1, 1)
  local header
  for _, q in ipairs(AIPinDB.pins) do
    if q ~= p and q.uiMapID == p.uiMapID and q.x and q.y
       and math.abs(q.x - p.x) < NEAR and math.abs(q.y - p.y) < NEAR then
      if not header then
        GameTooltip:AddLine("附近还有", 0.6, 0.6, 0.6)
        header = true
      end
      GameTooltip:AddDoubleLine(q.title or "AIPin", string.format("%.1f, %.1f", q.x, q.y), 1, 0.82, 0, 1, 1, 1)
    end
  end
  GameTooltip:AddLine(IsWaypointPin(p) and "当前导航点" or "点击设为导航点", 0.5, 0.8, 1)
  GameTooltip:Show()
end

local function NewPinFrame(canvas)
  local pin = CreateFrame("Button", nil, canvas)
  pin:SetSize(24, 24)
  pin.tex = pin:CreateTexture(nil, "OVERLAY")
  pin.tex:SetAllPoints()
  pin.tex:SetTexture(ICON)
  pin:EnableMouse(true)
  pin:RegisterForClicks("LeftButtonUp")
  -- Right-click still reaches the map (zoom out).
  if pin.SetPassThroughButtons then pcall(pin.SetPassThroughButtons, pin, "RightButton") end
  pin:SetScript("OnClick", function(self)
    if self.aipin then WaypointTo(self.aipin) end
    if self:IsMouseOver() then PinTooltip(self) end
  end)
  pin:SetScript("OnEnter", PinTooltip)
  pin:SetScript("OnLeave", function() GameTooltip:Hide() end)
  return pin
end

local HookWorldMap -- defined below

local function RefreshOwnPins()
  if not provider then HookWorldMap() end
  if not provider then return end
  provider:RemoveAllData()
  local map = provider:GetMap()
  local mapID = map and map:GetMapID()
  if not mapID then return end
  EnsureDB()
  local canvas = map:GetCanvas()
  local w, h = canvas:GetWidth(), canvas:GetHeight()
  local level
  for _, p in ipairs(AIPinDB.pins) do
    if p.uiMapID == mapID and p.x and p.y then
      level = level or PinFrameLevel(map)
      local pin = provider:AcquirePin()
      pin.aipin = p
      pin:SetFrameLevel(level)
      pin:ClearAllPoints()
      pin:SetPoint("CENTER", canvas, "TOPLEFT", w * p.x / 100, -h * p.y / 100)
      pin:Show()
    end
  end
end

HookWorldMap = function()
  if provider or not (WorldMapFrame and WorldMapFrame.AddDataProvider and MapCanvasDataProviderMixin) then return end
  provider = CreateFromMixins(MapCanvasDataProviderMixin)
  provider.GetMap = function() return WorldMapFrame end
  provider.AcquirePin = function(self)
    pinsUsed = pinsUsed + 1
    local pin = pinFrames[pinsUsed]
    if not pin then
      pin = NewPinFrame(self:GetMap():GetCanvas())
      pinFrames[pinsUsed] = pin
    end
    return pin
  end
  provider.RemoveAllData = function()
    for _, pin in ipairs(pinFrames) do
      pin:Hide()
      pin.aipin = nil
    end
    pinsUsed = 0
  end
  -- The map calls these when it opens, when the viewed map changes and when the
  -- canvas resizes, so each map shows exactly its own pins.
  provider.RefreshAllData = function() RefreshOwnPins() end
  provider.OnMapChanged = function() RefreshOwnPins() end
  provider.OnCanvasSizeChanged = function() RefreshOwnPins() end
  WorldMapFrame:AddDataProvider(provider)
  WorldMapFrame:HookScript("OnShow", function() RefreshOwnPins() end)
end

-- Saves a pin (or retitles the one already at that spot) and returns it.
local function StorePin(uiMapID, xPct, yPct, title)
  EnsureDB()
  title = title or "AIPin"
  for _, q in ipairs(AIPinDB.pins) do
    if q.uiMapID == uiMapID and math.abs((q.x or 0) - xPct) < 0.15 and math.abs((q.y or 0) - yPct) < 0.15 then
      q.title = title
      return q
    end
  end
  local pin = { uiMapID = uiMapID, x = xPct, y = yPct, title = title, created = time() }
  table.insert(AIPinDB.pins, pin)
  -- Over the limit: drop the oldest by creation time, not the top of the list
  -- (the player can reorder it).
  while #AIPinDB.pins > MAX_PINS do
    local oldest = 1
    for i, q in ipairs(AIPinDB.pins) do
      if (q.created or 0) < (AIPinDB.pins[oldest].created or 0) then oldest = i end
    end
    table.remove(AIPinDB.pins, oldest)
  end
  return pin
end

-- Panel drag-to-reorder: move pin `from` to position `to`.
local function MovePin(from, to)
  EnsureDB()
  local pins = AIPinDB.pins
  if not (pins[from] and to and to >= 1 and to <= #pins and to ~= from) then return false end
  table.insert(pins, to, table.remove(pins, from))
  RefreshOwnPins()
  return true
end

-- /aipin: save the pin and point the waypoint at it.
local function AddPin(uiMapID, xPct, yPct, title)
  local pin = StorePin(uiMapID, xPct, yPct, title)
  SetNativeWaypoint(uiMapID, xPct / 100, yPct / 100, pin.title, true)
  RefreshOwnPins()
  RefreshPanel()
  Print(string.format(L.pinned, pin.title, MapName(uiMapID), xPct, yPct))
end

local function ClearPins()
  EnsureDB()
  AIPinDB.pins = {}
  if C_Map and C_Map.ClearUserWaypoint then
    pcall(C_Map.ClearUserWaypoint)
  end
  activeTitle = nil
  AIPinDB.activeWaypoint = nil
  RefreshOwnPins()
  Print(L.cleared)
end

local function ListPins()
  EnsureDB()
  if #AIPinDB.pins == 0 then
    Print(L.listEmpty)
    return
  end
  Print(L.listHeader)
  for i, p in ipairs(AIPinDB.pins) do
    Print(string.format(L.listItem, i, p.title or "?", MapName(p.uiMapID), p.x, p.y))
  end
end

-- Parse from end-ish: two consecutive numbers = x y; before = zone; after = title
local function ParseArgs(msg)
  local tokens = {}
  for t in string.gmatch(Trim(msg), "%S+") do
    tokens[#tokens + 1] = t
  end
  if #tokens < 2 then return nil end

  local xi
  for i = 1, #tokens - 1 do
    if tonumber(tokens[i]) and tonumber(tokens[i + 1]) then
      xi = i
      break
    end
  end
  if not xi then return nil end

  local x = tonumber(tokens[xi])
  local y = tonumber(tokens[xi + 1])
  if not x or not y or x < 0 or x > 100 or y < 0 or y > 100 then
    return nil
  end

  local zoneParts, titleParts = {}, {}
  for i = 1, xi - 1 do zoneParts[#zoneParts + 1] = tokens[i] end
  for i = xi + 2, #tokens do titleParts[#titleParts + 1] = tokens[i] end

  local zone = (#zoneParts > 0) and table.concat(zoneParts, " ") or nil
  local title = (#titleParts > 0) and table.concat(titleParts, " ") or "AIPin"
  return zone, x, y, title
end

local function SlashHandler(msg)
  local raw = Trim(msg or "")
  local low = Normalize(raw)
  if low == "" or low == "help" then
    Print(L.help)
    return
  end
  if low == "clear" then
    ClearPins()
    return
  end
  if low == "me" then
    if AIPin_SnapshotNow then pcall(AIPin_SnapshotNow) end
    local c = AIPin_LastChar
    if not c then Print("还没有角色数据，请稍后再试。") return end
    local z = c.zone or "?"
    if c.subzone and c.subzone ~= "" then z = z .. " - " .. c.subzone end
    Print(string.format("%s，%s 级 %s，位置：%s (%s, %s)，任务 %d 个。", c.name or "?", tostring(c.level or "?"), c.class or "", z, tostring(c.x or "?"), tostring(c.y or "?"), c.quests and #c.quests or 0))
    Print("角色信息会在 /reload、下线或切换角色时写入存档，助手之后就能读取。")
    return
  end
  if low == "sync" then
    if AIPin_Sync then AIPin_Sync() end
    return
  end
  if low == "minimap" then
    if AIPin_ToggleMinimap then AIPin_ToggleMinimap() end
    return
  end
  if low == "list" then
    ListPins()
    return
  end

  local zone, x, y, title = ParseArgs(raw)
  if not x then
    Print(L.badArgs)
    return
  end

  local uiMapID
  if zone then
    uiMapID = ResolveZone(zone)
    if not uiMapID then
      Print(string.format(L.unknownZone, zone))
      uiMapID = C_Map and C_Map.GetBestMapForUnit and C_Map.GetBestMapForUnit("player")
    end
  else
    uiMapID = C_Map and C_Map.GetBestMapForUnit and C_Map.GetBestMapForUnit("player")
  end

  if not uiMapID then
    Print(L.noMap)
    return
  end

  AddPin(uiMapID, x, y, title)
end

SLASH_AIPIN1 = "/aipin"
SLASH_AIPIN2 = "/ap"
SlashCmdList["AIPIN"] = SlashHandler

-- Inbox.lua is a plain addon file (never written by the game), so the
-- assistant can edit it on disk and a /reload imports the new pins.
local function ImportInbox()
  local box = AIPinInbox
  if type(box) ~= "table" or type(box.pins) ~= "table" then return end
  local ver = tonumber(box.version) or 0
  if ver <= (AIPinDB.inboxVersion or 0) then return end
  AIPinDB.inboxVersion = ver
  local n = 0
  for _, p in ipairs(box.pins) do
    local x, y = tonumber(p.x), tonumber(p.y)
    local uiMapID = tonumber(p.map) or (p.zone and ResolveZone(p.zone))
    if uiMapID and x and y then
      local pin = StorePin(uiMapID, x, y, p.title)
      Print(string.format(L.pinned, pin.title, MapName(uiMapID), x, y))
      n = n + 1
    elseif p.zone then
      Print("|cffffd100AIPin:|r 收件箱里有未知区域: " .. tostring(p.zone))
    end
  end
  if n > 0 then Print(string.format("已从助手导入 %d 个新标记。", n)) end
  return n
end

-- Set at login, used once the player is in the world (their map is known by then).
local importedAtLogin

local function OnLogin()
  EnsureDB()
  HookWorldMap()
  importedAtLogin = (ImportInbox() or 0) > 0
  RefreshOwnPins()
end

local function RemovePin(i)
  EnsureDB()
  if not AIPinDB.pins[i] then return end
  table.remove(AIPinDB.pins, i)
  RefreshOwnPins()
end

AIPin_API = {
  Print = Print, MapName = MapName, ClearPins = ClearPins, RemovePin = RemovePin, MovePin = MovePin, EnsureDB = EnsureDB,
  ResolveZone = ResolveZone, Trim = Trim,
  SetNativeWaypoint = SetNativeWaypoint, WaypointTo = WaypointTo, IsWaypointPin = IsWaypointPin,
}

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:SetScript("OnEvent", function(self, event, arg1)
  if event == "ADDON_LOADED" and arg1 == ADDON then
    EnsureDB()
  elseif event == "ADDON_LOADED" and arg1 == "Blizzard_WorldMap" then
    RefreshOwnPins() -- hooks the map if it loaded after us
  elseif event == "PLAYER_LOGIN" then
    OnLogin()
    if AIPinDB and AIPinDB.activeWaypoint and not activeTitle then
      activeTitle = AIPinDB.activeWaypoint
    end
    HookWaypointTooltip()
    UpdateHudLabel()
  elseif event == "PLAYER_ENTERING_WORLD" then
    self:UnregisterEvent("PLAYER_ENTERING_WORLD")
    RestoreWaypoint(importedAtLogin)
    RefreshOwnPins()
  end
end)
