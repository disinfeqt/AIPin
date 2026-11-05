-- AIPin minimap button + pin panel (no external libraries)
local ICON = "Interface\\AddOns\\AIPin\\media\\icon"
local FALLBACK = "Interface\\Icons\\INV_Misc_Map_01"
local function P(msg) if AIPin_API and AIPin_API.Print then AIPin_API.Print(msg) else print("AIPin: " .. msg) end end
local function DB() AIPinDB = AIPinDB or {}; AIPinDB.pins = AIPinDB.pins or {}; return AIPinDB end

function AIPin_Sync()
  if InCombatLockdown and InCombatLockdown() then P("战斗中无法同步，请脱战后再试。") return end
  if AIPin_SnapshotNow then pcall(AIPin_SnapshotNow) end
  print("AIPin：正在同步…")
  DB().lastSync = time()
  ReloadUI()
end

local function Ago(t)
  if not t then return "从未" end
  local m = math.floor((time() - t) / 60)
  if m < 1 then return "刚刚" end
  if m < 60 then return m .. " 分钟前" end
  return math.floor(m / 60) .. " 小时前"
end

-- Panel ---------------------------------------------------------------
local panel, rows = nil, {}
local function RefreshPanel()
  if not panel then return end
  local db = DB()
  for _, r in ipairs(rows) do r:Hide() end
  local ROW = 36
  for i, p in ipairs(db.pins) do
    local r = rows[i]
    if not r then
      r = CreateFrame("Frame", nil, panel)
      r:SetSize(300, ROW)
      r.text = r:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
      r.text:SetPoint("TOPLEFT", 4, -2); r.text:SetPoint("RIGHT", -28, 0)
      r.text:SetJustifyH("LEFT"); r.text:SetWordWrap(false)
      r.sub = r:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
      r.sub:SetPoint("TOPLEFT", r.text, "BOTTOMLEFT", 0, -3); r.sub:SetPoint("RIGHT", -28, 0)
      r.sub:SetJustifyH("LEFT"); r.sub:SetWordWrap(false)
      r.del = CreateFrame("Button", nil, r, "UIPanelCloseButton")
      r.del:SetSize(22, 22); r.del:SetPoint("RIGHT", 0, 0)
      rows[i] = r
    end
    r:ClearAllPoints()
    r:SetPoint("TOPLEFT", 10, -32 - (i - 1) * ROW)
    local zone = AIPin_API and AIPin_API.MapName and AIPin_API.MapName(p.uiMapID) or tostring(p.uiMapID)
    r.text:SetText(string.format("%d. %s", i, p.title or "?"))
    r.sub:SetText(string.format("%s  %.1f, %.1f", zone or "?", p.x or 0, p.y or 0))
    r.del:SetScript("OnClick", function() if AIPin_API then AIPin_API.RemovePin(i) end; RefreshPanel() end)
    r:Show()
  end
  local n = #db.pins
  panel.empty:SetShown(n == 0)
  panel:SetHeight(120 + math.max(n, 1) * ROW)
  panel.info:SetText(string.format("上次同步：%s\n收件箱版本：%s",
    db.lastSync and date("%Y-%m-%d %H:%M", db.lastSync) or "从未", tostring(db.inboxVersion or 0)))
end

local function CreatePanel()
  panel = CreateFrame("Frame", "AIPinPanel", UIParent, BackdropTemplateMixin and "BackdropTemplate" or nil)
  panel:SetSize(320, 156); panel:SetPoint("CENTER")
  panel:SetFrameStrata("DIALOG"); panel:SetMovable(true); panel:EnableMouse(true)
  panel:RegisterForDrag("LeftButton")
  panel:SetScript("OnDragStart", panel.StartMoving); panel:SetScript("OnDragStop", panel.StopMovingOrSizing)
  if panel.SetBackdrop then
    panel:SetBackdrop({ bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background", edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
      tile = true, tileSize = 16, edgeSize = 16, insets = { left = 4, right = 4, top = 4, bottom = 4 } })
  end
  local title = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  title:SetPoint("TOP", 0, -10); title:SetText("AIPin 标记列表")
  local close = CreateFrame("Button", nil, panel, "UIPanelCloseButton"); close:SetPoint("TOPRIGHT", 0, 0)
  panel.empty = panel:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  panel.empty:SetPoint("TOPLEFT", 14, -34); panel.empty:SetText("暂无标记")
  panel.info = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  panel.info:SetPoint("BOTTOMLEFT", 12, 40); panel.info:SetJustifyH("LEFT")
  local clear = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
  clear:SetSize(100, 22); clear:SetPoint("BOTTOMLEFT", 10, 10); clear:SetText("全部清除")
  clear:SetScript("OnClick", function() if AIPin_API then AIPin_API.ClearPins() end; RefreshPanel() end)
  local sync = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
  sync:SetSize(100, 22); sync:SetPoint("BOTTOMRIGHT", -10, 10); sync:SetText("同步")
  sync:SetScript("OnClick", AIPin_Sync)
  panel:SetScript("OnShow", function() RefreshPanel(); if AIPin_TodoRefresh then AIPin_TodoRefresh() end end)
  if AIPin_TodoAttach then pcall(AIPin_TodoAttach, panel) end
  panel:Hide()
  if UISpecialFrames then table.insert(UISpecialFrames, "AIPinPanel") end
end

local function TogglePanel()
  if not panel then CreatePanel() end
  if panel:IsShown() then panel:Hide() else panel:Show() end
end

-- Minimap button --------------------------------------------------------
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
  local ok = pcall(icon.SetTexture, icon, ICON)
  if not ok or not icon:GetTexture() then pcall(icon.SetTexture, icon, FALLBACK) end
  if btn.CreateMaskTexture then
    local mask = btn:CreateMaskTexture()
    pcall(mask.SetTexture, mask, "Interface\\CharacterFrame\\TempPortraitAlphaMask", "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
    mask:SetAllPoints(icon); pcall(icon.AddMaskTexture, icon, mask)
  end
  local border = btn:CreateTexture(nil, "OVERLAY")
  border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
  border:SetSize(53, 53); border:SetPoint("TOPLEFT")
  btn:SetScript("OnClick", function(_, b) if b == "RightButton" then AIPin_Sync() else TogglePanel() end end)
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
    GameTooltip:AddLine("AIPin")
    GameTooltip:AddLine("左键：打开标记和待办列表", 1, 1, 1)
    GameTooltip:AddLine("右键：同步（保存角色信息、导入助手标记）", 1, 1, 1)
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
