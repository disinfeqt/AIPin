-- AIPin minimap button + panel (tabs: 待办 | 标记). No external libraries.
local ADDON = "AIPin"
local ICON = "Interface\\AddOns\\AIPin\\media\\icon"
local FALLBACK = "Interface\\Icons\\INV_Misc_Map_01"
local WHITE = "Interface\\Buttons\\WHITE8X8"
local BD = BackdropTemplateMixin and "BackdropTemplate" or nil

local function P(msg) if AIPin_API and AIPin_API.Print then AIPin_API.Print(msg) else print("AIPin: " .. msg) end end
local function DB() AIPinDB = AIPinDB or {}; AIPinDB.pins = AIPinDB.pins or {}; return AIPinDB end

-- The version shown in the panel header comes from AIPin.toc, so it never goes stale.
local function AddonVersion()
  local get = (C_AddOns and C_AddOns.GetAddOnMetadata) or GetAddOnMetadata
  if not get then return nil end
  local ok, v = pcall(get, ADDON, "Version")
  if ok and type(v) == "string" and v ~= "" then return v end
end

-- media/icon.tga, or a built-in icon if the client cannot load it.
local function SetIcon(tex)
  local ok, loaded = pcall(tex.SetTexture, tex, ICON)
  if not ok or loaded == false or not tex:GetTexture() then
    pcall(tex.SetTexture, tex, FALLBACK)
  end
end

-- SavedVariables are written at reload with whatever is in memory, so wait (up to
-- ~8s) for the game's data to load first. Snapshot keeps old fields that still
-- read empty, so reloading after the wait is safe either way.
local SYNC_WAIT = 8
local syncing = false
function AIPin_Sync()
  if syncing then return end
  local function InCombat() return InCombatLockdown and InCombatLockdown() end
  if InCombat() then P("战斗中无法同步，请脱战后再试。") return end
  syncing = true
  local tries = 0
  local function Attempt()
    if InCombat() then syncing = false; P("战斗中无法同步，请脱战后再试。") return end
    local complete = true
    if AIPin_SnapshotNow then
      local ok, res = pcall(AIPin_SnapshotNow)
      complete = ok and res == true
    end
    if not complete and C_Timer and tries < SYNC_WAIT then
      if tries == 0 then print("AIPin：等待角色数据加载…") end
      tries = tries + 1
      C_Timer.After(1, Attempt)
      return
    end
    print("AIPin：正在同步…")
    DB().lastSync = time()
    ReloadUI()
  end
  Attempt()
end

local function Ago(t)
  if not t then return "从未" end
  local m = math.floor((time() - t) / 60)
  if m < 1 then return "刚刚" end
  if m < 60 then return m .. " 分钟前" end
  if m < 60 * 24 then return math.floor(m / 60) .. " 小时前" end
  return math.floor(m / 60 / 24) .. " 天前"
end

-- Look ----------------------------------------------------------------------
local C = {
  bg      = { 0.04, 0.04, 0.05, 0.90 },
  border  = { 0.80, 0.64, 0.30, 0.80 },
  gold    = { 1.00, 0.82, 0.30 },
  text    = { 0.93, 0.91, 0.86 },
  dim     = { 0.58, 0.56, 0.52 },
  zone    = { 0.45, 0.75, 1.00 },
  line    = { 1.00, 0.82, 0.30, 0.18 },
  well    = { 0.00, 0.00, 0.00, 0.32 },
  wellEdge = { 1.00, 1.00, 1.00, 0.07 },
}

-- Tooltip border = rounded corners; the background takes any colour/alpha.
local ROUNDED = {
  bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
  edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
  tile = true, tileSize = 16, edgeSize = 16,
  insets = { left = 4, right = 4, top = 4, bottom = 4 },
}
local FLAT = {
  bgFile = WHITE, edgeFile = WHITE, edgeSize = 1,
  insets = { left = 1, right = 1, top = 1, bottom = 1 },
}

local function Paint(f, preset, bg, border)
  if not f.SetBackdrop then return end
  if f.aipinBackdrop ~= preset then f:SetBackdrop(preset); f.aipinBackdrop = preset end
  f:SetBackdropColor(bg[1], bg[2], bg[3], bg[4] or 1)
  f:SetBackdropBorderColor(border[1], border[2], border[3], border[4] or 1)
end

local function HLine(parent, y, fromBottom)
  local t = parent:CreateTexture(nil, "ARTWORK")
  t:SetHeight(1)
  t:SetColorTexture(C.line[1], C.line[2], C.line[3], C.line[4])
  local edge = fromBottom and "BOTTOM" or "TOP"
  t:SetPoint(edge .. "LEFT", 16, y)
  t:SetPoint(edge .. "RIGHT", -16, y)
  return t
end

local function Tip(owner, text)
  GameTooltip:SetOwner(owner, "ANCHOR_TOP")
  GameTooltip:AddLine(text, 1, 1, 1, true)
  GameTooltip:Show()
end

-- Flat button. primary = gold fill, otherwise a quiet outline.
local function FlatButton(parent, text, width, primary, tip, height)
  local b = CreateFrame("Button", nil, parent, BD)
  b:SetSize(width, height or 24)
  local fs = b:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  fs:SetPoint("CENTER", 0, 0)
  fs:SetText(text)
  b:SetFontString(fs)
  local function paint(over)
    if primary then
      Paint(b, FLAT, over and { 0.96, 0.76, 0.33, 1 } or { 0.84, 0.64, 0.25, 0.95 }, { 1, 0.88, 0.55, 0.9 })
      fs:SetTextColor(0.12, 0.08, 0.02)
    else
      Paint(b, FLAT, over and { 1, 1, 1, 0.12 } or { 1, 1, 1, 0.05 }, over and { 1, 0.82, 0.3, 0.6 } or { 1, 1, 1, 0.16 })
      if over then fs:SetTextColor(C.gold[1], C.gold[2], C.gold[3]) else fs:SetTextColor(C.text[1], C.text[2], C.text[3]) end
    end
  end
  b:SetScript("OnEnter", function(self) paint(true); if tip then Tip(self, tip) end end)
  b:SetScript("OnLeave", function() paint(false); if tip then GameTooltip:Hide() end end)
  paint(false)
  return b
end

-- Dark inset area that holds a scrolling list.
local function ListWell(parent, name, width)
  local well = CreateFrame("Frame", nil, parent, BD)
  Paint(well, FLAT, C.well, C.wellEdge)
  local sf = CreateFrame("ScrollFrame", name, well, "UIPanelScrollFrameTemplate")
  sf:SetPoint("TOPLEFT", 4, -4)
  sf:SetPoint("BOTTOMRIGHT", -26, 4)
  local child = CreateFrame("Frame", nil, sf)
  child:SetSize(width, 1)
  sf:SetScrollChild(child)
  sf.child = child
  -- Only show the scroll bar when there is something to scroll.
  local bar = sf.ScrollBar or _G[name .. "ScrollBar"]
  if bar then
    bar:Hide()
    sf:HookScript("OnScrollRangeChanged", function(self)
      bar:SetShown((self:GetVerticalScrollRange() or 0) > 0.5)
    end)
  end
  well.scroll = sf
  well.empty = well:CreateFontString(nil, "OVERLAY", "GameFontDisable")
  well.empty:SetPoint("CENTER", 0, 10)
  well.empty:SetJustifyH("CENTER")
  return well
end

-- Row highlight that survives moving the mouse onto the row's own buttons.
local function RowHover(r, ...)
  local function on() r.hl:Show() end
  local function off() if not r:IsMouseOver() then r.hl:Hide() end end
  r:EnableMouse(true)
  r:HookScript("OnEnter", on)
  r:HookScript("OnLeave", off)
  for i = 1, select("#", ...) do
    local c = select(i, ...)
    c:HookScript("OnEnter", on)
    c:HookScript("OnLeave", off)
  end
end

local function DeleteButton(r)
  local d = CreateFrame("Button", nil, r, "UIPanelCloseButton")
  d:SetSize(20, 20)
  d:SetPoint("RIGHT", -4, 0)
  d:SetAlpha(0.55)
  d:HookScript("OnEnter", function(self) self:SetAlpha(1) end)
  d:HookScript("OnLeave", function(self) self:SetAlpha(0.55) end)
  return d
end

local function RowBase(parent, height)
  local r = CreateFrame("Frame", nil, parent)
  r:SetHeight(height)
  r.hl = r:CreateTexture(nil, "BACKGROUND")
  r.hl:SetAllPoints()
  r.hl:SetColorTexture(1, 1, 1, 0.06)
  r.hl:Hide()
  r.sep = r:CreateTexture(nil, "BORDER")
  r.sep:SetHeight(1)
  r.sep:SetPoint("BOTTOMLEFT", 6, 0)
  r.sep:SetPoint("BOTTOMRIGHT", -6, 0)
  r.sep:SetColorTexture(1, 1, 1, 0.05)
  return r
end

local function ZoneName(map)
  return (AIPin_API and AIPin_API.MapName and AIPin_API.MapName(map)) or tostring(map or "?")
end

-- Panel -----------------------------------------------------------------------
local W, H, PAD = 440, 540, 16
local LIST_W = W - PAD * 2 - 30 -- scroll child width inside the well
local PIN_ROW, TODO_ROW = 42, 30
local panel
local pinRows, todoRows = {}, {}
local activeTab = "todo"
local ShowTab -- forward

local function StyleTab(b, selected, over)
  if selected then
    b.bg:SetColorTexture(1, 0.82, 0.3, 0.12)
    b.line:Show()
    b.label:SetTextColor(C.gold[1], C.gold[2], C.gold[3])
  else
    b.bg:SetColorTexture(1, 1, 1, over and 0.06 or 0)
    b.line:Hide()
    if over then b.label:SetTextColor(C.text[1], C.text[2], C.text[3]) else b.label:SetTextColor(C.dim[1], C.dim[2], C.dim[3]) end
  end
end

local function MakeTab(parent, which, x, y)
  local b = CreateFrame("Button", nil, parent)
  b:SetSize(128, 28)
  b:SetPoint("TOPLEFT", x, y)
  b.which = which
  b.bg = b:CreateTexture(nil, "BACKGROUND")
  b.bg:SetAllPoints()
  b.line = b:CreateTexture(nil, "ARTWORK")
  b.line:SetHeight(2)
  b.line:SetPoint("BOTTOMLEFT")
  b.line:SetPoint("BOTTOMRIGHT")
  b.line:SetColorTexture(C.gold[1], C.gold[2], C.gold[3], 1)
  b.label = b:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  b.label:SetPoint("CENTER", 0, 1)
  b:SetScript("OnClick", function() ShowTab(which) end)
  b:SetScript("OnEnter", function(self) StyleTab(self, activeTab == self.which, true) end)
  b:SetScript("OnLeave", function(self) StyleTab(self, activeTab == self.which, false) end)
  return b
end

local function RefreshPins()
  if not panel then return end
  local db = DB()
  local child = panel.pinWell.scroll.child
  for _, r in ipairs(pinRows) do r:Hide() end
  for i, p in ipairs(db.pins) do
    local r = pinRows[i]
    if not r then
      r = RowBase(child, PIN_ROW)
      r.del = DeleteButton(r)
      r.text = r:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
      r.text:SetPoint("TOPLEFT", 10, -6)
      r.text:SetPoint("RIGHT", r.del, "LEFT", -6, 0)
      r.text:SetJustifyH("LEFT"); r.text:SetWordWrap(false)
      r.sub = r:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
      r.sub:SetPoint("BOTTOMLEFT", 10, 7)
      r.sub:SetPoint("RIGHT", r.del, "LEFT", -6, 0)
      r.sub:SetJustifyH("LEFT"); r.sub:SetWordWrap(false)
      r.sub:SetTextColor(C.dim[1], C.dim[2], C.dim[3])
      RowHover(r, r.del)
      pinRows[i] = r
    end
    r:ClearAllPoints()
    r:SetPoint("TOPLEFT", 0, -(i - 1) * PIN_ROW)
    r:SetWidth(LIST_W)
    r.text:SetText(p.title or "?")
    r.sub:SetText(string.format("|cff73bfff%s|r   %.1f, %.1f", ZoneName(p.uiMapID), p.x or 0, p.y or 0))
    r.del:SetScript("OnClick", function()
      if AIPin_API and AIPin_API.RemovePin then AIPin_API.RemovePin(i) end
      AIPin_RefreshPanel()
    end)
    r:Show()
  end
  local n = #db.pins
  child:SetHeight(math.max(n, 1) * PIN_ROW)
  panel.pinWell.empty:SetShown(n == 0)
  panel.tabPins.label:SetText(n > 0 and ("标记  " .. n) or "标记")
end

local function RefreshTodos()
  if not panel then return end
  local todos = AIPin_TodoGetList and AIPin_TodoGetList() or {}
  local child = panel.todoWell.scroll.child
  for _, r in ipairs(todoRows) do r:Hide() end
  for i, t in ipairs(todos) do
    local r = todoRows[i]
    if not r then
      r = RowBase(child, TODO_ROW)
      r.cb = CreateFrame("CheckButton", nil, r, "UICheckButtonTemplate")
      r.cb:SetSize(22, 22)
      r.cb:SetPoint("LEFT", 4, 0)
      r.del = DeleteButton(r)
      r.loc = r:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
      r.loc:SetPoint("RIGHT", r.del, "LEFT", -6, 0)
      r.loc:SetTextColor(C.zone[1], C.zone[2], C.zone[3])
      r.text = r:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
      r.text:SetPoint("LEFT", r.cb, "RIGHT", 4, 0)
      r.text:SetPoint("RIGHT", r.loc, "LEFT", -8, 0)
      r.text:SetJustifyH("LEFT"); r.text:SetWordWrap(false)
      r.strike = r:CreateTexture(nil, "OVERLAY")
      r.strike:SetHeight(1)
      r.strike:SetColorTexture(0.6, 0.6, 0.6, 0.9)
      r.strike:SetPoint("LEFT", r.text, "LEFT", 0, 0)
      r:SetScript("OnEnter", function(self)
        local tt = self.todo
        if not tt or not tt.map then return end
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:AddLine(tt.text, C.gold[1], C.gold[2], C.gold[3])
        if tt.x and tt.y then
          GameTooltip:AddLine(string.format("到达 %s %.1f, %.1f 附近时提醒", ZoneName(tt.map), tt.x, tt.y), 1, 1, 1)
        else
          GameTooltip:AddLine(string.format("进入 %s 时提醒", ZoneName(tt.map)), 1, 1, 1)
        end
        GameTooltip:Show()
      end)
      r:SetScript("OnLeave", function() GameTooltip:Hide() end)
      RowHover(r, r.cb, r.del)
      todoRows[i] = r
    end
    r.todo = t
    r:ClearAllPoints()
    r:SetPoint("TOPLEFT", 0, -(i - 1) * TODO_ROW)
    r:SetWidth(LIST_W)
    r.cb:SetChecked(t.done and true or false)
    r.cb:SetScript("OnClick", function(self)
      if AIPin_TodoSetDone then AIPin_TodoSetDone(i, self:GetChecked()) end
    end)
    r.del:SetScript("OnClick", function()
      if AIPin_TodoDelete then AIPin_TodoDelete(i) end
    end)
    if t.map then
      r.loc:SetText(t.x and t.y and string.format("%s %.0f, %.0f", ZoneName(t.map), t.x, t.y) or ZoneName(t.map))
    else
      r.loc:SetText("")
    end
    r.text:SetText(t.text)
    if t.done then
      r.text:SetTextColor(0.5, 0.5, 0.5)
      r.loc:SetAlpha(0.5)
      r.strike:SetWidth(math.min(r.text:GetStringWidth() + 2, r.text:GetWidth() > 0 and r.text:GetWidth() or 300))
      r.strike:Show()
    else
      r.text:SetTextColor(C.text[1], C.text[2], C.text[3])
      r.loc:SetAlpha(1)
      r.strike:Hide()
    end
    r:Show()
  end
  local n = #todos
  child:SetHeight(math.max(n, 1) * TODO_ROW)
  local u, total = 0, n
  if AIPin_TodoCounts then u, total = AIPin_TodoCounts() end
  panel.todoWell.empty:SetShown(n == 0)
  panel.tabTodo.label:SetText(total > 0 and string.format("待办  %d/%d", u, total) or "待办")
end

function AIPin_RefreshPanel()
  if not panel then return end
  RefreshPins()
  RefreshTodos()
  local db = DB()
  local when = db.lastSync and (date("%m-%d %H:%M", db.lastSync) .. "（" .. Ago(db.lastSync) .. "）") or "从未"
  panel.info:SetText(string.format("上次同步 %s   ·   收件箱 v%s", when, tostring(db.inboxVersion or 0)))
end

ShowTab = function(which)
  activeTab = which
  if not panel then return end
  panel.todoPage:SetShown(which == "todo")
  panel.pinPage:SetShown(which == "pins")
  StyleTab(panel.tabTodo, which == "todo")
  StyleTab(panel.tabPins, which == "pins")
  AIPin_RefreshPanel()
end

local function CreatePanel()
  panel = CreateFrame("Frame", "AIPinPanel", UIParent, BD)
  panel:SetSize(W, H)
  panel:SetPoint("CENTER")
  panel:SetFrameStrata("DIALOG")
  panel:SetToplevel(true)
  panel:SetClampedToScreen(true)
  panel:SetMovable(true)
  panel:EnableMouse(true)
  panel:RegisterForDrag("LeftButton")
  panel:SetScript("OnDragStart", panel.StartMoving)
  panel:SetScript("OnDragStop", panel.StopMovingOrSizing)
  Paint(panel, ROUNDED, C.bg, C.border)

  -- Header: icon, name, version. 64px tall so nothing is clipped.
  local ring = panel:CreateTexture(nil, "BORDER")
  ring:SetSize(42, 42)
  ring:SetPoint("TOPLEFT", PAD, -14)
  ring:SetColorTexture(C.gold[1], C.gold[2], C.gold[3], 0.55)
  local icon = panel:CreateTexture(nil, "ARTWORK")
  icon:SetSize(40, 40)
  icon:SetPoint("CENTER", ring, "CENTER")
  SetIcon(icon)
  panel.icon = icon

  local title = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  title:SetPoint("TOPLEFT", ring, "TOPRIGHT", 12, -3)
  title:SetText("AIPin")
  title:SetTextColor(C.gold[1], C.gold[2], C.gold[3])

  local sub = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  sub:SetPoint("BOTTOMLEFT", ring, "BOTTOMRIGHT", 12, 4)
  sub:SetTextColor(C.dim[1], C.dim[2], C.dim[3])
  local v = AddonVersion()
  sub:SetText((v and ("v" .. v .. "   ·   ") or "") .. "待办与地图标记")
  panel.version = sub

  local close = CreateFrame("Button", nil, panel, "UIPanelCloseButton")
  close:SetSize(26, 26)
  close:SetPoint("TOPRIGHT", -8, -8)

  -- Tabs
  local TAB_Y = -66
  panel.tabTodo = MakeTab(panel, "todo", PAD, TAB_Y)
  panel.tabPins = MakeTab(panel, "pins", PAD + 132, TAB_Y)
  HLine(panel, TAB_Y - 28)

  -- Pages share the area between the tabs and the footer.
  local BODY_TOP, BODY_BOTTOM = TAB_Y - 28 - 12, 50

  -- Todo page ---------------------------------------------------------------
  local todoPage = CreateFrame("Frame", nil, panel)
  todoPage:SetPoint("TOPLEFT", PAD, BODY_TOP)
  todoPage:SetPoint("BOTTOMRIGHT", -PAD, BODY_BOTTOM)
  panel.todoPage = todoPage

  local hereBtn = FlatButton(todoPage, "提醒在此处", 88, false, "用当前位置添加地理提醒（先在上面写好内容）")
  hereBtn:SetPoint("BOTTOMLEFT", 0, 0)
  local clrBtn = FlatButton(todoPage, "清除已完成", 88)
  clrBtn:SetPoint("LEFT", hereBtn, "RIGHT", 8, 0)
  clrBtn:SetScript("OnClick", function() if AIPin_TodoClearDone then AIPin_TodoClearDone() end end)
  -- Bounded on both sides: truncates with "…" instead of running under the buttons.
  local hint = todoPage:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  hint:SetPoint("LEFT", clrBtn, "RIGHT", 12, 0)
  hint:SetPoint("RIGHT", todoPage, "RIGHT", 0, 0)
  hint:SetJustifyH("RIGHT")
  hint:SetWordWrap(false)
  hint:SetTextColor(C.dim[1], C.dim[2], C.dim[3])
  hint:SetText("例：学法杖 @ 暴风城 63.9 69.1")

  local addBtn = FlatButton(todoPage, "添加", 64, true, nil, 28)
  addBtn:SetPoint("BOTTOMRIGHT", 0, 36)

  local eb = CreateFrame("EditBox", "AIPinTodoInput", todoPage, BD)
  eb:SetHeight(28)
  eb:SetPoint("BOTTOMLEFT", 0, 36)
  eb:SetPoint("RIGHT", addBtn, "LEFT", -8, 0)
  eb:SetFontObject(ChatFontNormal or GameFontHighlight)
  eb:SetTextInsets(10, 10, 0, 0)
  eb:SetAutoFocus(false)
  eb:EnableMouse(true)
  eb:SetMaxLetters(120)
  -- Placeholder is pinned inside the box on both sides, so a large client font
  -- truncates it instead of spilling under the 添加 button.
  local ph = eb:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  ph:SetPoint("LEFT", 10, 0)
  ph:SetPoint("RIGHT", -10, 0)
  ph:SetJustifyH("LEFT")
  ph:SetWordWrap(false)
  ph:SetText("添加待办…（可加 @ 区域，坐标可省略）")
  local function UpdPh() ph:SetShown(eb:GetText() == "" and not eb:HasFocus()) end
  local function PaintInput() Paint(eb, FLAT, { 0, 0, 0, 0.5 }, eb:HasFocus() and { 1, 0.82, 0.3, 0.7 } or { 1, 1, 1, 0.16 }) end
  eb:SetScript("OnTextChanged", UpdPh)
  eb:SetScript("OnEditFocusGained", function() UpdPh(); PaintInput() end)
  eb:SetScript("OnEditFocusLost", function() UpdPh(); PaintInput() end)
  local function Submit()
    if AIPin_TodoAddFromInput and AIPin_TodoAddFromInput(eb:GetText()) then eb:SetText("") end
    UpdPh()
  end
  eb:SetScript("OnEnterPressed", Submit)
  eb:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
  addBtn:SetScript("OnClick", Submit)
  PaintInput()
  UpdPh()
  panel.todoInput = eb

  hereBtn:SetScript("OnClick", function()
    local text = (eb:GetText() or ""):gsub("%s*@.*$", ""):gsub("^%s+", ""):gsub("%s+$", "")
    if text == "" then P("|cffffd100AIPin:|r 先在输入框写待办内容") return end
    local map = C_Map and C_Map.GetBestMapForUnit and C_Map.GetBestMapForUnit("player")
    local pos = map and C_Map.GetPlayerMapPosition and C_Map.GetPlayerMapPosition(map, "player")
    if not pos then P("|cffffd100AIPin:|r 无法获取当前位置") return end
    local x, y = pos:GetXY()
    if AIPin_TodoAdd and AIPin_TodoAdd(text, map, x * 100, y * 100) then eb:SetText(""); UpdPh() end
  end)

  panel.todoWell = ListWell(todoPage, "AIPinTodoScroll", LIST_W)
  panel.todoWell:SetPoint("TOPLEFT", 0, 0)
  panel.todoWell:SetPoint("BOTTOMRIGHT", 0, 76)
  panel.todoWell.empty:SetText("还没有待办\n在下面输入，或者让 AI 助手推送")

  -- Pin page ----------------------------------------------------------------
  local pinPage = CreateFrame("Frame", nil, panel)
  pinPage:SetPoint("TOPLEFT", PAD, BODY_TOP)
  pinPage:SetPoint("BOTTOMRIGHT", -PAD, BODY_BOTTOM)
  panel.pinPage = pinPage

  local clearPins = FlatButton(pinPage, "全部清除", 96)
  clearPins:SetPoint("BOTTOMLEFT", 0, 0)
  clearPins:SetScript("OnClick", function()
    if AIPin_API and AIPin_API.ClearPins then AIPin_API.ClearPins() end
    AIPin_RefreshPanel()
  end)
  local pinHint = pinPage:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  pinHint:SetPoint("LEFT", clearPins, "RIGHT", 12, 0)
  pinHint:SetPoint("RIGHT", pinPage, "RIGHT", 0, 0)
  pinHint:SetJustifyH("RIGHT")
  pinHint:SetWordWrap(false)
  pinHint:SetTextColor(C.dim[1], C.dim[2], C.dim[3])
  pinHint:SetText("按 M 打开地图查看标记")

  panel.pinWell = ListWell(pinPage, "AIPinPinScroll", LIST_W)
  panel.pinWell:SetPoint("TOPLEFT", 0, 0)
  panel.pinWell:SetPoint("BOTTOMRIGHT", 0, 36)
  panel.pinWell.empty:SetText("还没有标记\n粘贴 /aipin 指令，或者让 AI 助手推送")

  -- Footer: sync status + sync button -----------------------------------------
  HLine(panel, 42, true)
  local syncBtn = FlatButton(panel, "同步", 64, false, "保存角色信息并导入助手推送（会重载界面）")
  syncBtn:SetPoint("BOTTOMRIGHT", -PAD, 10)
  syncBtn:SetScript("OnClick", AIPin_Sync)
  panel.info = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  panel.info:SetPoint("LEFT", panel, "BOTTOMLEFT", PAD, 22)
  panel.info:SetPoint("RIGHT", syncBtn, "LEFT", -8, 0)
  panel.info:SetJustifyH("LEFT")
  panel.info:SetWordWrap(false)
  panel.info:SetTextColor(C.dim[1], C.dim[2], C.dim[3])

  panel:SetScript("OnShow", function() ShowTab(activeTab or "todo") end)
  panel:Hide()
  if UISpecialFrames then table.insert(UISpecialFrames, "AIPinPanel") end
  ShowTab(activeTab)
end

local function TogglePanel()
  if not panel then CreatePanel() end
  if panel:IsShown() then panel:Hide() else panel:Show() end
end

-- Minimap button --------------------------------------------------------------
local btn
local function Place(angle)
  local r = (Minimap:GetWidth() / 2) + 5
  local a = math.rad(angle or 225)
  btn:ClearAllPoints()
  btn:SetPoint("CENTER", Minimap, "CENTER", math.cos(a) * r, math.sin(a) * r)
end

local function CreateButton()
  if btn or not Minimap then return end
  btn = CreateFrame("Button", "AIPinMinimapButton", Minimap)
  btn:SetSize(31, 31); btn:SetFrameStrata("MEDIUM"); btn:SetFrameLevel(8)
  btn:RegisterForClicks("LeftButtonUp", "RightButtonUp"); btn:RegisterForDrag("LeftButton")
  btn:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
  -- Same layout as LibDBIcon so it lines up with the standard tracking border.
  local bg = btn:CreateTexture(nil, "BACKGROUND")
  bg:SetTexture("Interface\\Minimap\\UI-Minimap-Background")
  bg:SetSize(20, 20); bg:SetPoint("TOPLEFT", 7, -5)
  local icon = btn:CreateTexture(nil, "ARTWORK")
  icon:SetSize(18, 18); icon:SetPoint("TOPLEFT", 7, -6)
  SetIcon(icon)
  if btn.CreateMaskTexture then
    local mask = btn:CreateMaskTexture()
    pcall(mask.SetTexture, mask, "Interface\\CharacterFrame\\TempPortraitAlphaMask", "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
    mask:SetAllPoints(icon); pcall(icon.AddMaskTexture, icon, mask)
  end
  local border = btn:CreateTexture(nil, "OVERLAY")
  border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
  border:SetSize(53, 53); border:SetPoint("TOPLEFT")
  btn:SetScript("OnClick", function(_, b)
    if b == "RightButton" then AIPin_Sync() else TogglePanel() end
  end)
  btn:SetScript("OnDragStart", function(self)
    self:SetScript("OnUpdate", function()
      local mx, my = Minimap:GetCenter()
      local cx, cy = GetCursorPosition()
      local s = Minimap:GetEffectiveScale()
      local ang = math.deg((math.atan2 or atan2)(cy / s - my, cx / s - mx))
      DB().minimapAngle = ang; Place(ang)
    end)
  end)
  btn:SetScript("OnDragStop", function(self) self:SetScript("OnUpdate", nil) end)
  btn:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_LEFT")
    local v = AddonVersion()
    GameTooltip:AddDoubleLine("AIPin", v and ("v" .. v) or "", C.gold[1], C.gold[2], C.gold[3], 0.6, 0.6, 0.6)
    GameTooltip:AddLine("左键：打开待办和标记", 1, 1, 1)
    GameTooltip:AddLine("右键：同步（保存角色信息、导入助手推送）", 1, 1, 1)
    GameTooltip:AddLine("拖动：移动按钮", 1, 1, 1)
    GameTooltip:AddLine("上次同步 " .. Ago(DB().lastSync), 0.7, 0.7, 0.7)
    GameTooltip:Show()
  end)
  btn:SetScript("OnLeave", function() GameTooltip:Hide() end)
  Place(DB().minimapAngle)
  if DB().minimapHidden then btn:Hide() end
end

function AIPin_ToggleMinimap()
  local db = DB()
  db.minimapHidden = not db.minimapHidden
  if not btn then CreateButton() end
  if btn then btn:SetShown(not db.minimapHidden) end
  P(db.minimapHidden and "小地图按钮已隐藏（/aipin minimap 恢复）。" or "小地图按钮已显示。")
end

local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_LOGIN")
f:SetScript("OnEvent", function() pcall(CreateButton) end)
