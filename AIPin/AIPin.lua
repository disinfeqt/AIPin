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
  help = "|cffffd100AIPin|r 用法:\n  /aipin [区域] <x> <y> [名称]\n  /aipin clear — 清除标记\n  /aipin list — 列出标记\n  /aipin me — 查看角色信息\n  /aipin sync — 同步（保存并重载界面）\n  /aipin minimap — 显示/隐藏小地图按钮\n示例: /aipin 丹莫罗 44.1 57.1 巡山人格雷琴",
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

local function RefreshMap()
  if WorldMapFrame and WorldMapFrame:IsShown() then
    if WorldMapFrame.RefreshAllDataProviders then
      pcall(function() WorldMapFrame:RefreshAllDataProviders() end)
    end
  end
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
  ev:SetScript("OnEvent", UpdateHudLabel)
end

local function SetNativeWaypoint(uiMapID, x, y, title)
  if not (C_Map and UiMapPoint and C_Map.CanSetUserWaypointOnMap and C_Map.SetUserWaypoint) then
    return false
  end
  local ok, can = pcall(C_Map.CanSetUserWaypointOnMap, uiMapID)
  if not ok or not can then return false end
  local point = UiMapPoint.CreateFromCoordinates(uiMapID, x, y)
  if not point then return false end
  activeTitle = { uiMapID = uiMapID, x = x, y = y, title = title }
  EnsureDB()
  AIPinDB.activeWaypoint = activeTitle
  HookWaypointTooltip()
  C_Map.SetUserWaypoint(point)
  if C_SuperTrack and C_SuperTrack.SetSuperTrackedUserWaypoint then
    pcall(C_SuperTrack.SetSuperTrackedUserWaypoint, true)
  end
  UpdateHudLabel()
  return true
end

local function AddTomTom(uiMapID, x, y, title)
  if TomTom and TomTom.AddWaypoint then
    pcall(function()
      TomTom:AddWaypoint(uiMapID, x, y, {
        title = title or "AIPin",
        source = "AIPin",
        world = true,
        minimap = true,
        crazy = true,
      })
    end)
  end
end

local function AddPin(uiMapID, xPct, yPct, title)
  EnsureDB()
  local pin = {
    uiMapID = uiMapID,
    x = xPct,
    y = yPct,
    title = title or "AIPin",
    created = time(),
  }
  local dup
  for _, q in ipairs(AIPinDB.pins) do
    if q.uiMapID == uiMapID and math.abs((q.x or 0) - xPct) < 0.15 and math.abs((q.y or 0) - yPct) < 0.15 then
      dup = q
      break
    end
  end
  if dup then
    dup.title = pin.title
    pin = dup
  else
    table.insert(AIPinDB.pins, pin)
  end
  while #AIPinDB.pins > MAX_PINS do
    table.remove(AIPinDB.pins, 1)
  end

  local nx, ny = xPct / 100, yPct / 100
  SetNativeWaypoint(uiMapID, nx, ny, pin.title)
  AddTomTom(uiMapID, nx, ny, pin.title)
  RefreshMap()

  Print(string.format(L.pinned, pin.title, MapName(uiMapID), xPct, yPct))
end

local function ClearPins()
  EnsureDB()
  AIPinDB.pins = {}
  if C_Map and C_Map.ClearUserWaypoint then
    pcall(C_Map.ClearUserWaypoint)
  end
  ClearOverlayPins()
  RefreshMap()
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
      AddPin(uiMapID, x, y, p.title)
      n = n + 1
    elseif p.zone then
      Print("|cffffd100AIPin:|r 收件箱里有未知区域: " .. tostring(p.zone))
    end
  end
  if n > 0 then Print(string.format("已从助手导入 %d 个新标记。", n)) end
end

local function OnLogin()
  EnsureDB()
  ImportInbox()
  local pins = AIPinDB.pins
  if pins and #pins > 0 then
    local last = pins[#pins]
    SetNativeWaypoint(last.uiMapID, last.x / 100, last.y / 100)
  end
end

local function RemovePin(i)
  EnsureDB()
  if not AIPinDB.pins[i] then return end
  table.remove(AIPinDB.pins, i)
  ClearOverlayPins()
  RefreshMap()
end

AIPin_API = { Print = Print, MapName = MapName, ClearPins = ClearPins, RemovePin = RemovePin, EnsureDB = EnsureDB }

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:SetScript("OnEvent", function(_, event, arg1)
  if event == "ADDON_LOADED" and arg1 == ADDON then
    EnsureDB()
  elseif event == "PLAYER_LOGIN" then
    OnLogin()
    if AIPinDB and AIPinDB.activeWaypoint and not activeTitle then
      activeTitle = AIPinDB.activeWaypoint
    end
    HookWaypointTooltip()
    UpdateHudLabel()
  end
end)
