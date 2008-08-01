local Bollo = LibStub("AceAddon-3.0"):GetAddon("Bollo")
local Buff = Bollo:NewModule("Buff")
local cache = {}

function Buff:OnInitialize()
	local bf = _G["BuffFrame"]
	bf:Hide()
	bf:SetScript("OnEvent", nil)

	local defaults = {
		profile = {
			size = 32,
			spacing = 5,
			growthX = "LEFT",
			growthY = "DOWN",
		},
	}

	self.db = Bollo.db:RegisterNamespace("Buff", defaults)
end

function Buff:OnEnable()
	self:RegisterEvent("PLAYER_AURAS_CHANGED", "Update")
	self.icons = self.icons or {}
end

function Buff:Update()
	for i = 1, 40 do
		if GetPlayerBuff(i, "HELPFUL") > 0 then
			local icon = self.icons[i] or Bollo:NewIcon()
			icon:SetBase("HELPFUL")
			icon:SetID(i)
			icon:Setup(self.db.profile)
			self.icons[i] = icon
		elseif self.icons[i] then
			while self.icons[i] do
				Bollo:DelIcon(self.icons[i])
				self.icons[i] = nil
				i = i + 1
			end
			break
		end
	end
	self:UpdatePosition()
end

function Buff:UpdatePosition()
	local size, spacing = self.db.profile.size, self.db.profile.spacing
	local growthX, growthY = self.db.profile.growthX == "LEFT" and -1 or 1, self.db.profile.growthY == "DOWN" and -1 or 1

	local offset = 0
	for index, buff in ipairs(self.icons) do
		buff:ClearAllPoints()
		buff:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", (size + spacing) * offset - 200, 0)
		offset = offset + 1
	end
end