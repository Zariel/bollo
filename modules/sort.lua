local Bollo = LibStub("AceAddon-3.0"):GetAddon("Bollo")
local Sort = Bollo:NewModule("Sort")

local registered = {}

function Sort:OnEnable()
	Bollo.RegisterCallback(self, "PrePositionIcons", "SortIcons")
end

function Sort:Register(module)
	local name = tostring(module)
	if registered[name] then return end

	registeredp[name] = module
end

local SortTimeLeft = function(a, b)
	if not b or not b:GetTimeleft() then return false end
	if not a or not a:GetTimeleft() then return true end

	return a:GetTimeleft() > b:GetTimeleft()
end

function Sort:SortIcons(event, icons. module)
	if not registered[tostring(module)] then return end

	table.sort(icons, SortTimeLeft)
end
