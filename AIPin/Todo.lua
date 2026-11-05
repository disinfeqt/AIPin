-- AIPin todos + geo-reminders (v1.3.1)
local function P(msg) if AIPin_API and AIPin_API.Print then AIPin_API.Print(msg) else print("AIPin: " .. msg) end end
local function DB() AIPinDB = AIPinDB or {}; AIPinDB.todos = AIPinDB.todos or {}; return AIPinDB end
local function Trim(s) return (tostring(s or ""):gsub("^%s+", ""):gsub("%s+$", "")) end
local TAG = "|cffffd100AIPin:|r "
local NEAR, FAR = 0.03, 0.05

local function Counts()
  local undone, total = 0, 0
  for _, t in ipairs(DB().todos) do
    total = total + 1
    if not t.done then undone = undone + 1 end
  end
  return undone, total
end

-- Badge -------------------------------------------------------------------
local badge
local function UpdateBadge()
  local btn = _G.AIPinMinimapButton
  if not btn then return end
  if not badge then
    badge = CreateFrame("Frame", nil, btn)
    badge:SetSize(16, 14); badge:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", 2, -2)
    badge:SetFrameLevel(btn:GetFrameLevel() + 5)
    local bg = badge:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints(); bg:SetColorTexture(0, 0, 0, 0.75)
    badge.text = badge:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    badge.text:SetPoint("CENTER", 0, 0)
    local font, size = badge.text:GetFont()
    if font then badge.text:SetFont(font, size or 10, "OUTLINE") end
    badge.text:SetTextColor(1, 0.82, 0)
  end
  local n = Counts()
  if n > 0 then
    badge.text:SetText(n > 99 and "99+" or tostring(n))
    badge:SetWidth(math.max(14, badge.text:GetStringWidth() + 6))
    badge:Show()
  else
    badge:Hide()
  end
end

local function NotifyPanel()
  UpdateBadge()
  if AIPin_RefreshPanel then AIPin_RefreshPanel() end
end

-- Core ops ----------------------------------------------------------------
local function FindByText(text)
  for i, t in ipairs(DB().todos) do if t.text == text then return t, i end end
end

-- Parse:
--   "text"                  -> plain todo
--   "text @ zone"           -> zone reminder (map set, x/y nil)
--   "text @ zone x y"       -> coord reminder
-- Returns: text, err, map, x, y
local function Parse(raw)
  raw = Trim(raw)
  local text, loc = raw:match("^(.-)%s*@%s*(.+)$")
  if not text or text == "" then return raw end
  loc = Trim(loc)

  -- Try "zone x y" first
  local zone, xs, ys = loc:match("^(.-)%s+([%d%.]+)[,%s]+([%d%.]+)$")
  local x, y = tonumber(xs), tonumber(ys)
  if zone and x and y and x >= 0 and x <= 100 and y >= 0 and y <= 100 then
    zone = Trim(zone)
    local map
    if zone ~= "" then
      map = AIPin_API and AIPin_API.ResolveZone and AIPin_API.ResolveZone(zone)
      if not map then return nil, "未知区域: " .. zone end
    else
      map = C_Map and C_Map.GetBestMapForUnit and C_Map.GetBestMapForUnit("player")
    end
    return Trim(text), nil, map, x, y
  end

  -- Zone only (no coords)
  zone = loc
  if zone == "" then return nil, "区域名不能为空，例如: 学法杖 @ 暴风城" end
  local map = AIPin_API and AIPin_API.ResolveZone and AIPin_API.ResolveZone(zone)
  if not map then return nil, "未知区域: " .. zone end
  return Trim(text), nil, map, nil, nil
end

local function AddTodo(text, map, x, y, quiet)
  text = Trim(text)
  if text == "" then return false end
  local t = FindByText(text)
  if t then
    if map then t.map, t.x, t.y = map, x, y end
  else
    t = { text = text, done = false, created = time(), map = map, x = x, y = y }
    table.insert(DB().todos, t)
  end
  if not quiet then
    if map and x and y then
      local zone = AIPin_API and AIPin_API.MapName and AIPin_API.MapName(map) or tostring(map)
      P(string.format(TAG .. "已添加地理提醒：%s（%s %.1f, %.1f）", text, zone or "?", x, y))
    elseif map then
      local zone = AIPin_API and AIPin_API.MapName and AIPin_API.MapName(map) or tostring(map)
      P(string.format(TAG .. "已添加区域提醒：%s（进入 %s 时）", text, zone or "?"))
    else
      P(TAG .. "已添加待办：" .. text)
    end
  end
  NotifyPanel()
  return true
end

local function AddFromInput(raw)
  local text, err, map, x, y = Parse(raw)
  if not text then P(TAG .. err) return false end
  return AddTodo(text, map, x, y)
end

local function SetDone(i, v)
  local t = DB().todos[i]
  if not t then P(TAG .. "没有第 " .. tostring(i) .. " 条待办") return end
  t.done = v and true or false
  t.triggered = nil
  NotifyPanel()
end

local function DelTodo(i)
  if not DB().todos[i] then P(TAG .. "没有第 " .. tostring(i) .. " 条待办") return end
  table.remove(DB().todos, i)
  NotifyPanel()
end

local function ClearDone()
  local keep, n = {}, 0
  for _, t in ipairs(DB().todos) do if t.done then n = n + 1 else keep[#keep + 1] = t end end
  DB().todos = keep
  P(string.format(TAG .. "已清除 %d 条已完成待办", n))
  NotifyPanel()
end

local function ListTodos()
  local todos = DB().todos
  if #todos == 0 then P(TAG .. "没有待办") return end
  local u, n = Counts()
  P(string.format(TAG .. "待办 (%d/%d):", u, n))
  for i, t in ipairs(todos) do
    local loc = ""
    if t.map then
      local zone = AIPin_API and AIPin_API.MapName and AIPin_API.MapName(t.map) or tostring(t.map)
      if t.x and t.y then
        loc = string.format(" @ %s %.1f, %.1f", zone or "?", t.x, t.y)
      else
        loc = string.format(" @ %s", zone or "?")
      end
    end
    P(string.format("  %d) %s %s%s", i, t.done and "|cff808080[x]" or "[ ]", t.text, loc) .. (t.done and "|r" or ""))
  end
end

-- Reminder popup ----------------------------------------------------------
local popup
local function ShowPopup(text)
  if not popup then
    popup = CreateFrame("Frame", nil, UIParent)
    popup:SetSize(600, 40); popup:SetPoint("CENTER", 0, 180); popup:SetFrameStrata("HIGH")
    popup.text = popup:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
    popup.text:SetPoint("CENTER"); popup.text:SetTextColor(1, 0.82, 0)
    popup:SetScript("OnUpdate", function(self, el)
      self.t = (self.t or 0) + el
      if self.t > 5 then self:Hide()
      elseif self.t > 4 then self:SetAlpha(5 - self.t) end
    end)
  end
  popup.text:SetText("AIPin 提醒：" .. text)
  popup.t = 0; popup:SetAlpha(1); popup:Show()
end

local function Fire(t)
  t.triggered = true
  print("|cffffd100AIPin 提醒:|r " .. t.text)
  ShowPopup(t.text)
  pcall(PlaySound, 888)
end

local function CheckGeo()
  if not (C_Map and C_Map.GetBestMapForUnit) then return end
  local map = C_Map.GetBestMapForUnit("player")
  if not map then return end
  local px, py
  if C_Map.GetPlayerMapPosition then
    local pos = C_Map.GetPlayerMapPosition(map, "player")
    if pos then px, py = pos:GetXY() end
  end
  for _, t in ipairs(DB().todos) do
    if not t.done and t.map then
      if t.x and t.y then
        -- Coord reminder
        local d = 1
        if t.map == map and px and py and not (px == 0 and py == 0) then
          local dx, dy = t.x / 100 - px, t.y / 100 - py
          d = math.sqrt(dx * dx + dy * dy)
        end
        if d < NEAR and not t.triggered then
          Fire(t)
        elseif d > FAR and t.triggered then
          t.triggered = nil
        end
      else
        -- Zone-only reminder: fire on enter, re-arm on leave
        if t.map == map then
          if not t.triggered then Fire(t) end
        else
          t.triggered = nil
        end
      end
    end
  end
end

-- Exported API for Minimap.lua panel --------------------------------------
function AIPin_TodoGetList() return DB().todos end
function AIPin_TodoAdd(text, map, x, y) return AddTodo(text, map, x, y) end
function AIPin_TodoAddFromInput(raw) return AddFromInput(raw) end
function AIPin_TodoSetDone(i, v) SetDone(i, v) end
function AIPin_TodoDelete(i) DelTodo(i) end
function AIPin_TodoClearDone() ClearDone() end
function AIPin_TodoCounts() return Counts() end
function AIPin_TodoParseInput(raw) return Parse(raw) end
function AIPin_TodoUpdateBadge() UpdateBadge() end

-- Slash commands (wrap the main handler) -----------------------------------
local base = SlashCmdList["AIPIN"]
SlashCmdList["AIPIN"] = function(msg)
  local raw = Trim(msg)
  local cmd, rest = raw:match("^(%S+)%s*(.*)$")
  cmd = cmd and cmd:lower()
  if cmd == "todo" then
    if rest == "" then ListTodos() else AddFromInput(rest) end
  elseif cmd == "todos" then ListTodos()
  elseif cmd == "done" then SetDone(tonumber(rest), true)
  elseif cmd == "undone" then SetDone(tonumber(rest), false)
  elseif cmd == "deltodo" then DelTodo(tonumber(rest))
  elseif cmd == "cleartodos" then ClearDone()
  elseif base then base(msg) end
end

-- Inbox import (own version counter, dedup by text) -------------------------
local function ImportTodos()
  local box = AIPinInbox
  if type(box) ~= "table" or type(box.todos) ~= "table" then return end
  local ver = tonumber(box.version) or 0
  local db = DB()
  if ver <= (db.todoInboxVersion or 0) then return end
  db.todoInboxVersion = ver
  local n = 0
  for _, t in ipairs(box.todos) do
    if type(t) == "table" and t.text and not FindByText(Trim(t.text)) then
      local map = tonumber(t.map) or (t.zone and AIPin_API and AIPin_API.ResolveZone and AIPin_API.ResolveZone(t.zone))
      local x, y = tonumber(t.x), tonumber(t.y)
      -- Allow zone-only (map set, no coords)
      if not map then map, x, y = nil, nil, nil end
      if map and not (x and y) then x, y = nil, nil end
      if AddTodo(t.text, map, x, y, true) then n = n + 1 end
    end
  end
  if n > 0 then P(string.format(TAG .. "已从助手导入 %d 条待办。", n)) end
end

AIPin_API = AIPin_API or {}
AIPin_API.AddTodo = AddTodo
AIPin_API.UpdateBadge = UpdateBadge

local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_LOGIN")
f:SetScript("OnEvent", function()
  DB()
  for _, t in ipairs(AIPinDB.todos) do t.triggered = nil end
  pcall(ImportTodos)
  if C_Timer then
    C_Timer.After(0.5, UpdateBadge)
    C_Timer.NewTicker(2, function() pcall(CheckGeo) end)
  else
    UpdateBadge()
  end
end)
