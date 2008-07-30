local bollo = LibStub("AceAddon-3.0"):NewAddon("Bollo", "AceEvent-3.0", "AceConsole-3.0")

local ipairs = ipairs
local pairs = pairs

local GetPlayerBuffName = GetPlayerBuffName
local GetPlayerBuff = GetPlayerBuff
local DebuffTypeColor = DebuffTypeColor
local GetPlayerBuffDispelType = GetPlayerBuffDispelType
local GetPlayerBuffApplications = GetPlayerBuffApplications
local DebuffTypeColor = DebuffTypeColor

function bollo:CreateBackground(name, db)
	db = db or self.db.profile[name]

	local bg = CreateFrame("Frame", nil, UIParent)
	bg:SetWidth(db.width)
	bg:SetHeight(db.height)

	bg:SetBackdrop({
		bgFile = "Interface\\ChatFrame\\ChatFrameBackground", tile = true, tileSize = 16,
		edgeFile = [[Interface\Tooltips\UI-Tooltip-Border]], edgeSize = 10,
		insets = {left = 1, right = 1, top = 1, bottom = 1},
	})

	bg:SetBackdropColor(0, 1, 0, 0.3)

	bg:SetMovable(true)
	bg:EnableMouse(true)
	bg:SetClampedToScreen(true)

	bg:SetScript("OnMouseDown", function(self, button)
		self:ClearAllPoints()
		return self:StartMoving()
	end)

	bg:SetScript("OnMouseUp", function(self, button)
		local x, y, s = self:GetLeft(), self:GetTop(), self:GetEffectiveScale()
		db.x, db.y = x * s, y * s

		return self:StopMovingOrSizing()
	end)

	local x, y, s = db.x, db.y, bg:GetEffectiveScale()

	bg:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", x / s, y / s)

	local f = bg:CreateFontString(nil, "OVERLAY")
	f:SetFont(STANDARD_TEXT_FONT, 14)
	f:SetShadowColor(0, 0, 0, 1)
	f:SetShadowOffset(1, -1)
	f:SetAllPoints(bg)
	f:SetFormattedText("%s - Anchor", name)

	bg:Hide()

	return setmetatable({
		bg = bg
	}, {
		__tostring = function()
			return name
		end
	})
end

function bollo:OnInitialize()
	local defaults = {
		profile = {
			buff = {
				["growthx"] = "LEFT",
				["growthy"] = "DOWN",
				["size"] = 32,
				["spacing"] = 6,
				["lock"] = false,
				["x"] = 0,
				["y"] = 0,
				["height"] = 100,
				["width"] = 350,
				["rowSpace"] = 20,
			},
			debuff = {
				["growthx"] = "LEFT",
				["growthy"] = "DOWN",
				["size"] = 32,
				["spacing"] = 6,
				["lock"] = false,
				["x"] = 0,
				["y"] = 0,
				["height"] = 100,
				["width"] = 350,
				["rowSpace"] = 20,
			}
		},
	}

	self.db = LibStub("AceDB-3.0"):New("BolloDB", defaults)
	self.events = LibStub("CallbackHandler-1.0"):New(bollo)

	self.icons = setmetatable({}, {
		__newindex = function(t, key, val)
			rawset(t, key, val)
			self.events:Fire("NewIconGroup", key, val)
		end
	})

	local OnUpdate
	do
		local timer = 1
		OnUpdate = function(self, elapsed)
			timer = timer + elapsed
			if timer > 0.25 then
				bollo.events:Fire("OnUpdate")
				timer = 0
			end
		end
	end

	function bollo.events:OnUsed(target, event)
		if event == "OnUpdate" then
			bollo.frame:SetScript("OnUpdate", OnUpdate)
		end
	end

	function bollo.events:OnUnused(target, event)
		if event == "OnUpdate" then
			bollo.frame:SetScript("OnUpdate", nil)
		end
	end
end

function bollo:OnEnable()
	self.frame = self.frame or CreateFrame("Frame")       -- Frame for modules to run OnUpdate

	local bf = _G["BuffFrame"]
	bf:UnregisterAllEvents()
	bf:Hide()
	bf:SetScript("OnUpdate", nil)
	bf:SetScript("OnEvent", nil)
	_G.BuffButton_OnUpdate = nil

	self.icons.buff = self:CreateBackground("buff")
	self.icons.debuff = self:CreateBackground("debuff")

	self:RegisterEvent("PLAYER_AURAS_CHANGED")
	self:PLAYER_AURAS_CHANGED()

	local Update = function(self)
		for name in pairs(self.icons) do
			for k, v in pairs(self.icons[name]) do
				if v.UpdateSettings then
					bollo:UpdateSettings(v)
				end
			end
		end
	end
	self.db.RegisterCallback("", "OnProfileChanged", Update)
end

local SortFunc = function(a, b)
	if not a then
		a = 0
	else
		a = a:GetTimeLeft()
	end
	if not b then
		b = 0
	else
		b = b:GetTimeLeft()
	end
	return a > b
end

function bollo:GetPoint(point)
	local anchor, relative, mod
	if point == "TOP" then
		relative = "TOP"
		anchor = "BOTTOM"
		mod = 1
	elseif point == "BOTTOM" then
		relative = "BOTTOM"
		anchor = "TOP"
		mod = -1
	elseif point == "CENTER" then
		relative = "CENTER"
		anchor = "CENTER"
		mod = 1
	elseif point == "LEFT" then
		relative = "LEFT"
		anchor = "RIGHT"
		mod = 1
	elseif point == "RIGHT" then
		relative = "RIGHT"
		anchor = "LEFT"
		mod = 1
	end
	return anchor, relative, mod
end

function bollo:SortBuffs(icons, max)
	self.events:Fire("PreUpdateIcons", icons)
	if not icons then return end
	local name = tostring(icons)
	local offset = 0
	local growthx = self.db.profile[name]["growthx"] == "LEFT" and -1 or 1
	local growthy = self.db.profile[name]["growthy"] == "DOWN" and -1 or 1
	local size = self.db.profile[name].size
	local perCol = math.floor(icons.bg:GetWidth() / size + 0.5)
	local perRow = math.floor(icons.bg:GetHeight() / size + 0.5)
	local rowSpace = self.db.profile[name].rowSpace
	local rows = 0
	local anchor = growthx > 0 and "LEFT" or "RIGHT"
	local relative = growthy  > 0 and "BOTTOM" or "TOP"
	local point = relative .. anchor
	for i, buff in ipairs(icons) do
		if buff:IsShown() then
			buff:ClearAllPoints()

			if offset == perCol then
				rows = rows + 1
				offset = 0
			end

			buff:SetPoint(point, icons.bg, point, (offset * (size + self.db.profile[name].spacing) * growthx), (rows * (size + rowSpace) * growthy))
			self.events:Fire("UpdateIconPosition", i, buff, icons)
			offset = offset + 1
		end
	end
	self.events:Fire("PostPositionIcons", icons)
end

function bollo:UpdateIcons(i, parent, filter)
	local index = GetPlayerBuff(i, filter)
	local icon = parent[i]
	bollo.events:Fire("PreUpddate")

	if index > 0 then
		icon = icon or self:CreateIcon(parent)
		icon:SetBuff(index, filter)
		return true
	elseif icon then
		icon:SetID(0)
		icon:Hide()
		return false
	end
end

-- Blatently copied from oUF
function bollo:PLAYER_AURAS_CHANGED()
	local max = 1
	for i = 1, 40 do
		if not self:UpdateIcons(i, self.icons.buff, "HELPFUL") then
			for a = i,  #self.icons.buff do
				self.icons.buff[a]:Hide()
			end
			break
		end
		max = max + 1
	end
	self:SortBuffs(self.icons.buff, max - 1)
	max = 1
	for i = 1, 40 do
		if not self:UpdateIcons(i, self.icons.debuff, "HARMFUL") then
			for a = i,  #self.icons.debuff do
				self.icons.debuff[a]:Hide()
			end
			break
		end
		max = max + 1
	end
	self:SortBuffs(self.icons.debuff, max - 1)
end

function bollo:UpdateSettings(table, db)
	local name = tostring(table)
	table.bg:SetHeight(db and db.height or self.db.profile[name].height)
	table.bg:SetWidth(db and db.width or self.db.profile[name].width)

	for index, buff in ipairs(table) do
		local size = db and db.size or self.db.profile[name].size
		buff:SetHeight(size)
		buff:SetWidth(size)
		buff.border:ClearAllPoints()
		buff.border:SetAllPoints(buff)
		buff.icon:ClearAllPoints()
		buff.icon:SetAllPoints(buff)
	end

	if self.db.profile[name] then
		self:SortBuffs(table)
	end

	self.events:Fire("PostUpdateConfig", name)
end
