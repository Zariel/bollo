local bollo = LibStub("AceAddon-3.0"):GetAddon("Bollo")
local Weapon = bollo:NewModule("WeaponBuffs")

function Weapon:OnInitialize()
	local defaults = {
		profile = {
			enabled = true,
			weapon = {
				["growthx"] = "LEFT",
				["growthy"] = "DOWN",
				["size"] = 30,
				["spacing"] = 2,
				["lock"] = false,
				["x"] = 0,
				["y"] = 0,
				["height"] = 100,
				["width"] = 350,
				["rowSpace"] = 20,
				["enabled"] = true,
				["Name"] = {
					["Description"] = "Shows truncated names of buffs",
					["font"] = STANDARD_TEXT_FONT,
					["fontStyle"] = "OUTLINE",
					["fontSize"] = 9,
					["x"] = 0,
					["y"] = 0,
					["point"] = "BOTTOM",
					["color"] = {
						r = 1,
						g = 1,
						b = 1,
						a = 1,
					},
					["enabled"] = true,
				},
				["Duration"] = {
					["Description"] = "Show buff durations",
					["point"] = "TOP",
					["font"] = STANDARD_TEXT_FONT,
					["fontSize"] = 9,
					["fontStyle"] = "OUTLINE",
					["x"] = 0,
					["y"] = 0,
					["format"] = "M:SS",
					["color"] = {
						r = 1,
						g = 1,
						b = 1,
						a = 1,
					},
				},
			}
		}
	}

	self.db = bollo.db:RegisterNamespace("Bollo-Weapon", defaults)

	bollo.icons.weapon = bollo.icons.weapon or setmetatable({}, {__tostring = function() return "weapon" end})

	self.options = {
		name = "Weapons",
		type = "group",
		args = {
			enableDesc = {
				name = "Enable or disable the module",
				type = "description",
				order = 1,
			},
			enable = {
				name = "Enable",
				type = "toggle",
				get = function(info)
					return self:IsEnabled()
				end,
				set = function(info, key)
					if key then
						self:Enable()
					else
						self:Disable()
					end
					self.db.profile.enabled = key
				end,
				order = 2,
			},
		}
	}

	bollo:AddOptions(self)

	self:SetEnabledState(self.db.profile.enabled)

	TemporaryEnchantFrame:SetScript("OnUpdate", nil)
	TemporaryEnchantFrame:Hide()
end

local GetTimeLeft = function(self)
	local hasMainHandEnchant, mainHandExpiration, mainHandCharges, hasOffHandEnchant, offHandExpiration, offHandCharges = GetWeaponEnchantInfo()

	local id = self:GetID()
	if id == 16 then
		return hasMainHandEnchant and mainHandExpiration / 1000 or 0
	else
		return hasOffHandEnchant and offHandExpiration / 1000 or 0
	end
end

local GetBuff = function(self)
	if GetInventoryItemLink("player", self:GetID()) then
		return GetItemInfo(GetInventoryItemLink("player", self:GetID()))
	else
		return ""
	end
end

function Weapon:OnEnable()
	bollo.db.RegisterCallback(self, "OnProfileChanged", "UpdateConfig")

	if not bollo.icons.weapon[1] then
		for i = 1, 2 do
			local button = bollo:CreateIcon(bollo.icons.weapon, Weapon.db.profile.weapon)
			button:SetID(15 + i)
			button.GetBuff = GetBuff
			button.GetTimeLeft = GetTimeLeft
			button:SetScript("OnEnter", function(self)
				if self:IsVisible() then
					GameTooltip:SetOwner(self, "ANCHOR_BOTTOMRIGHT")
					GameTooltip:SetInventoryItem("player", self:GetID())
				end
			end)
			button:SetScript("OnMouseUp", function(self, button)
				if button == "RightButton" then
					CancelItemTempEnchantment(self:GetID() - 15)
				end
			end)
		end
	end

	if not bollo.icons.weapon.bg then
		local bg = CreateFrame("Frame", nil, UIParent)
		bg:SetWidth(Weapon.db.profile.weapon.width)
		bg:SetHeight(Weapon.db.profile.weapon.height)
		bg:SetBackdrop({
			bgFile = "Interface\\ChatFrame\\ChatFrameBackground", tile = true, tileSize = 16,
			insets = {left = 1, right = 1, top = 1, bottom = 1},
		})
		bg:SetBackdropColor(0, 0, 1, 0.3)
		bg:Hide()

		bg:SetMovable(true)
		bg:EnableMouse(true)
		bg:SetClampedToScreen(true)
		bg:SetScript("OnMouseDown", function(self, button)
			self:ClearAllPoints()
			return self:StartMoving()
		end)

		bg:SetScript("OnMouseUp", function(self, button)
			local x, y = self:GetLeft(), self:GetTop()
			Weapon.db.profile.weapon.x, Weapon.db.profile.weapon.y = x, y
			return self:StopMovingOrSizing()
		end)

		bg:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", Weapon.db.profile.weapon.x, Weapon.db.profile.weapon.y)
		bollo.icons.weapon.bg = bg
	end

	bollo.RegisterCallback(self, "OnUpdate")

	local conf = bollo:GetModule("Config")
	conf:AddChildOpts("weapon", Weapon.db.profile.weapon, Weapon)

	for k, v in bollo:IterateModules() do
		if v.AddOptions and self.db.profile.weapon[k] then
			v:AddOptions("weapon", self.db.profile.weapon[k], self)
		end
	end
end

function Weapon:OnDisable()
	bollo.UnregisterCallback(self, "OnUpdate")
	bollo.db.UnregisterCallback(self, "OnProfileChanged")
	bollo.icons.weapon.bg:Hide()

	for k, v in pairs(bollo.icons.weapon) do
		if v then
			v:Hide()
		end
	end

	--TemporaryEnchantFrame:Show()
	--TemporaryEnchantFrame:SetScript("OnUpdate", BuffFrame_Enchant_OnUpdate)
end

local hasMainHandEnchant, mainHandExpiration, mainHandCharges, hasOffHandEnchant, offHandExpiration, offHandCharges
function Weapon:OnUpdate()
	hasMainHandEnchant, mainHandExpiration, mainHandCharges, hasOffHandEnchant, offHandExpiration, offHandCharges = GetWeaponEnchantInfo()
	local offset = 0
	local growthx = self.db.profile.weapon["growthx"] == "LEFT" and -1 or 1
	local growthy = self.db.profile.weapon["growthy"] == "DOWN" and -1 or 1
	local size = self.db.profile.weapon.size
	local perCol = math.floor(bollo.icons.weapon.bg:GetWidth() / size + 0.5)
	local perRow = math.floor(bollo.icons.weapon.bg:GetHeight() / size + 0.5)
	local rowSpace = self.db.profile.weapon.rowSpace
	local spacing = self.db.profile.weapon.spacing
	local rows = 0
	local anchor = growthx > 0 and "LEFT" or "RIGHT"
	local relative = growthy  > 0 and "BOTTOM" or "TOP"
	local point = relative .. anchor

	local icon = bollo.icons.weapon[1]
	if hasMainHandEnchant then
		local texture = GetInventoryItemTexture("player", icon:GetID())
		icon.icon:SetTexture(texture)
		icon:Show()
	else
		icon:Hide()
	end

	icon = bollo.icons.weapon[2]
	if hasOffHandEnchant then
		local texture = GetInventoryItemTexture("player", icon:GetID())
		icon.icon:SetTexture(texture)
		icon:Show()
	else
		icon:Hide()
	end

	for i, buff in ipairs(bollo.icons.weapon) do
		if buff:IsShown() then
			buff:ClearAllPoints()

			if offset == perCol then
				rows = rows + 1
				offset = 0
			end

			buff:SetPoint(point, bollo.icons.weapon.bg, point, (offset * (size + spacing) * growthx), (rows * (size + rowSpace) * growthy))
			offset = offset + 1
		end
	end
end

function Weapon:UpdateConfig()
	local size = Weapon.db.profile.size
	for k, v in ipairs(bollo.icons.weapon) do
		v:SetHeight(size)
		v:SetWidth(size)
		v.icon:SetAllPoints(v)
	end

	local bf = bollo:GetModule("ButtonFacade")
	if bf then
		bf:OnEnable()
	end

	self:OnUpdate()
end
