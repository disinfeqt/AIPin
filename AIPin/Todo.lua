-- AIPin todos + geo-reminders (v1.3.0)
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

local Refresh -- forward
local function Changed() UpdateBadge(); if Refresh then Refresh() end end

-- Core ops ----------------------------------------------------------------
local function FindByText(text)
  for i, t in ipairs(DB().todos) do if t.text == text then return t, i end end
end

-- "text @ zone x y" -> text, map, x, y (map may be nil / error string)
local function Parse(raw)
  raw = Trim(raw)
  local text, loc = raw:match("^(.-)%s*@%s*(.+)$")
  if not text or text == "" then return raw end
  local zone, x, y = loc:match("^(.-)%s*([%d%.]+)[,%s]+([%d%.]+)$")
  x, y = tonumber(x), tonumber(y)
  if not x or not y or x < 0 or x > 100 or y < 0 or y > 100 then return nil, "坐标格式错误，例如: 学法杖 @ 暴风城 63.9 69.1" end
  local map
  zone = Trim(zone)
  if zone ~= "" then
    map = AIPin_API and AIPin_API.ResolveZone and AIPin_API.ResolveZone(zone)
    if not map then return nil, "未知区域: " .. zone end
  else
    map = C_Map and C_Map.GetBestMapForUnit and C_Map.GetBestMapForUnit("player")
  end
  return Trim(text), nil, map, x, y
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
    if map then
      local zone = AIPin_API and AIPin_API.MapName and AIPin_API.MapName(map) or tostring(map)
      P(string.format(TAG .. "已添加地理提醒：%s（%s %.1f, %.1f）", text, zone or "?", x, y))
    else
      P(TAG .. "已添加待办：" .. text)
    end
  end
  Changed()
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
  Changed()
end

local function DelTodo(i)
  if not DB().todos[i] then P(TAG .. "没有第 " .. tostring(i) .. " 条待办") return end
  table.remove(DB().todos, i)
  Changed()
end

local function ClearDone()
  local keep, n = {}, 0
  for _, t in ipairs(DB().todos) do if t.done then n = n + 1 else keep[#keep + 1] = t end end
  DB().todos = keep
  P(string.format(TAG .. "已清除 %d 条已完成待办", n))
  Changed()
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
      loc = string.format(" @ %s %.1f, %.1f", zone or "?", t.x or 0, t.y or 0)
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

local function CheckGeo()
  if not (C_Map and C_Map.GetBestMapForUnit and C_Map.GetPlayerMapPosition) then return end
  local map = C_Map.GetBestMapForUnit("player")
  if not map then return end
  local pos = C_Map.GetPlayerMapPosition(map, "player")
  if not pos then return end
  local px, py = pos:GetXY()
  if not px or (px == 0 and py == 0) then return end
  for _, t in ipairs(DB().todos) do
    if not t.done and t.map and t.x and t.y then
      local d = 1
      if t.map == map then
        local dx, dy = t.x / 100 - px, t.y / 100 - py
        d = math.sqrt(dx * dx + dy * dy)
      end
      if d < NEAR and not t.triggered then
        t.triggered = true
        print("|cffffd100AIPin 提醒:|r " .. t.text)
        ShowPopup(t.text)
        pcall(PlaySound, 888)
      elseif d > FAR and t.triggered then
        t.triggered = nil
      end
    end
  end
end

-- Panel section -----------------------------------------------------------
local sec, rows = nil, {}
local ROW = 24

Refresh = function()
  if not sec then return end
  local todos = DB().todos
  for _, r in ipairs(rows) do r:Hide() end
  for i, t in ipairs(todos) do
    local r = rows[i]
    if not r then
      r = CreateFrame("Frame", nil, sec)
      r:SetSize(300, ROW)
      r.cb = CreateFrame("CheckButton", nil, r, "UICheckButtonTemplate")
      r.cb:SetSize(22, 22); r.cb:SetPoint("LEFT", 0, 0)
      r.text = r:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
      r.text:SetPoint("LEFT", r.cb, "RIGHT", 2, 0); r.text:SetPoint("RIGHT", -26, 0)
      r.text:SetJustifyH("LEFT"); r.text:SetWordWrap(false)
      r.strike = r:CreateTexture(nil, "OVERLAY")
      r.strike:SetHeight(1); r.strike:SetColorTexture(0.6, 0.6, 0.6, 0.9)
      r.strike:SetPoint("LEFT", r.text, "LEFT", 0, 0)
      r.del = CreateFrame("Button", nil, r, "UIPanelCloseButton")
      r.del:SetSize(22, 22); r.del:SetPoint("RIGHT", 0, 0)
      r:SetScript("OnEnter", function(self)
        local tt = self.todo
        if not tt or not tt.map then return end
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:AddLine(tt.text, 1, 0.82, 0)
        local zone = AIPin_API and AIPin_API.MapName and AIPin_API.MapName(tt.map) or tostring(tt.map)
        GameTooltip:AddLine(string.format("到达 %s %.1f, %.1f 附近时提醒", zone or "?", tt.x or 0, tt.y or 0), 1, 1, 1)
        GameTooltip:Show()
      end)
      r:SetScript("OnLeave", function() GameTooltip:Hide() end)
      rows[i] = r
    end
    r.todo = t
    r:ClearAllPoints(); r:SetPoint("TOPLEFT", 10, -30 - (i - 1) * ROW)
    r.cb:SetChecked(t.done and true or false)
    r.cb:SetScript("OnClick", function(self) SetDone(i, self:GetChecked()) end)
    r.del:SetScript("OnClick", function() DelTodo(i) end)
    r.text:SetText(t.map and ("|cff66ccff[地]|r " .. t.text) or t.text)
    if t.done then
      r.text:SetTextColor(0.5, 0.5, 0.5)
      r.strike:SetWidth(math.min(r.text:GetStringWidth(), 250)); r.strike:Show()
    else
      r.text:SetTextColor(1, 1, 1); r.strike:Hide()
    end
    r:Show()
  end
  local u, n = Counts()
  sec.title:SetText(string.format("待办 (%d/%d)", u, n))
  sec.empty:SetShown(n == 0)
  sec:SetHeight(100 + math.max(n, 1) * ROW)
end

function AIPin_TodoAttach(panel)
  if sec then return end
  sec = CreateFrame("Frame", "AIPinTodoPanel", panel, BackdropTemplateMixin and "BackdropTemplate" or nil)
  sec:SetPoint("TOPLEFT", panel, "BOTTOMLEFT", 0, 2); sec:SetPoint("TOPRIGHT", panel, "BOTTOMRIGHT", 0, 2)
  sec:SetHeight(124); sec:EnableMouse(true)
  if sec.SetBackdrop then
    sec:SetBackdrop({ bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background", edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
      tile = true, tileSize = 16, edgeSize = 16, insets = { left = 4, right = 4, top = 4, bottom = 4 } })
  end
  sec.title = sec:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  sec.title:SetPoint("TOP", 0, -10)
  sec.empty = sec:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  sec.empty:SetPoint("TOPLEFT", 14, -34); sec.empty:SetText("暂无待办，在下面输入后点「添加」")

  local eb = CreateFrame("EditBox", "AIPinTodoInput", sec, "InputBoxTemplate")
  eb:SetSize(200, 22); eb:SetPoint("BOTTOMLEFT", 18, 40)
  eb:SetAutoFocus(false); eb:SetMaxLetters(120)
  local ph = eb:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  ph:SetPoint("LEFT", 2, 0); ph:SetText("添加待办…（可加 @ 区域 x y）")
  local function UpdPh() ph:SetShown(eb:GetText() == "" and not eb:HasFocus()) end
  eb:SetScript("OnTextChanged", UpdPh)
  eb:SetScript("OnEditFocusGained", UpdPh)
  eb:SetScript("OnEditFocusLost", UpdPh)
  local function Submit()
    if AddFromInput(eb:GetText()) then eb:SetText("") end
    UpdPh()
  end
  eb:SetScript("OnEnterPressed", Submit)
  eb:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)

  local add = CreateFrame("Button", nil, sec, "UIPanelButtonTemplate")
  add:SetSize(80, 22); add:SetPoint("LEFT", eb, "RIGHT", 8, 0); add:SetText("添加待办")
  add:SetScript("OnClick", Submit)

  local hint = sec:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  hint:SetPoint("BOTTOMLEFT", 14, 68); hint:SetText("例：学法杖 @ 暴风城 63.9 69.1  — 到达附近时提醒")
  local here = CreateFrame("Button", nil, sec, "UIPanelButtonTemplate")
  here:SetSize(100, 22); here:SetPoint("BOTTOMLEFT", 10, 10); here:SetText("提醒在此处")
  here:SetScript("OnClick", function()
    local text = Trim(eb:GetText()):gsub("%s*@.*$", "")
    if text == "" then P(TAG .. "先在输入框写待办内容") return end
    local map = C_Map and C_Map.GetBestMapForUnit and C_Map.GetBestMapForUnit("player")
    local pos = map and C_Map.GetPlayerMapPosition(map, "player")
    if not pos then P(TAG .. "无法获取当前位置") return end
    local x, y = pos:GetXY()
    if AddTodo(text, map, x * 100, y * 100) then eb:SetText(""); UpdPh() end
  end)
  here:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:AddLine("用当前位置添加地理提醒", 1, 1, 1); GameTooltip:Show()
  end)
  here:SetScript("OnLeave", function() GameTooltip:Hide() end)
  local clr = CreateFrame("Button", nil, sec, "UIPanelButtonTemplate")
  clr:SetSize(100, 22); clr:SetPoint("BOTTOMRIGHT", -10, 10); clr:SetText("清除已完成")
  clr:SetScript("OnClick", ClearDone)
  UpdPh()
  Refresh()
end

function AIPin_TodoRefresh() Refresh() end

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
      if not (map and x and y) then map, x, y = nil, nil, nil end
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
  -- Minimap button is created on PLAYER_LOGIN too; wait a tick.
  if C_Timer then
    C_Timer.After(0.5, UpdateBadge)
    C_Timer.NewTicker(2, function() pcall(CheckGeo) end)
  else
    UpdateBadge()
  end
end)
