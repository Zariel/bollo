local Bollo = LibStub("AceAddon-3.0"):GetAddon("Bollo")

local buff = Bollo:NewModule("Buff", "AceEvent-3.0", "AceConsole-3.0")

function buff:OnEnable()
	self:RegisterEvent("PLAYER_AURAS_CHANGED")
	self.icons = Bollo.Auras:CreateBackground()
end

function buff:PLAYER_AURAS_CHANGED()
	local i = 1
	while UnitBuff("player", i) do
		local name = UnitBuff("player", i)
		local c = self.icons[i] or Bollo.Auras:CreateIcon("buff")
		c:SetBuff(i)
		self.icons[i] = c
		i = i + 1
	end

	while self.icons[i] do
		Bollo.Auras:RemoveIcon(self.icons[i])
		self.icons[i] = nil
		i = i + 1
	end

	self:PositionIcons()
end

function buff:PositionIcons()
	local offset = 0
	for index, icon in ipairs(self.icons) do
		if icon:IsShown() then
			icon:ClearAllPoints()
			icon:SetPoint("TOPRIGHT", self.icons.bg, "TOPRIGHT", -(32 * offset + 5), 0)
			offset = offset + 1
		end
	end
end