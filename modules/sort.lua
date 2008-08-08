local bollo = LibStub("AceAddon-3.0"):GetAddon("Bollo")
local Sort = bollo:NewModule("Sort")

local table_sort = table.sort

local RegisteredIcons = {}

function Sort:AddOptions(name, module)
	if type(name) ~= "string" then
		error("Wrong argument to #1 :AddOptions, expected string")
	end

	if self.options.args[name] then return end

	RegisteredIcons[name] = true

	module = module or self
	local db = module and module.db.profile[name] or self.db.profile[name]

	local conf = self.options.args
	conf[name] = {
		name = name,
		type = "group",
		set = function(info, key)
			db[info[#info]] = key
			bollo:SortBuffs(bollo.icons[name], 0)
		end,
		get = function(info)
			return db[info[#info]]
		end,
		args = {
			method_desc = {
				name = "Set the sorting method for " .. name,
				type = "description",
				order = 10,
			},
			method = {
				name = "Method",
				order = 11,
				type = "select",
				values = {
					["TimeLeft"] = "TimeLeft",
					["Alphabetical"] = "Alphabetical",
				},
			},
			reversed_desc = {
				name = "Reverse the sorting method",
				type = "description",
				order = 20,
			},
			reversed = {
				name = "Reverse",
				type = "toggle",
				order = 21,
			},
		}
	}
	bollo:SortBuffs(bollo.icons[name], 0)
end

function Sort:OnInitialize()
	local defaults = {
		profile = {
			["*"] = {
				method = "TimeLeft",
				reversed = false,
			},
			enabled = true,
		}
	}

	self.db = bollo.db:RegisterNamespace("Bollo-Sort", defaults)
	self:SetEnabledState(self.db.profile.enabled)

	self.options = {
		type = "group",
		name = "Sorting",
		childGroups = "tab",
		get = function(info)
			local key = info[#info]
			return self.db.profile[key]
		end,
		set = function(info, val)
			local key = info[#info]
			self.db.profile[key] = val
		end,
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

	self:AddOptions("buff")
	self:AddOptions("debuff")
	bollo:AddOptions(self)
end

function Sort:OnEnable()
	bollo.RegisterCallback(self, "PreUpdateIcons")
end

function Sort:OnDisable()
	bollo.UnregisterCallback(self, "PreUpdateIcons")
end

Sort.TimeLeft = function(a, b)
	if not b or not b:GetTimeLeft() then return false end
	if not a or not a:GetTimeLeft() then return true end

	return a:GetTimeLeft() > b:GetTimeLeft()
end

Sort.TimeLeftReverse = function(b, a)
	if not b or not b:GetTimeLeft() then return false end
	if not a or not a:GetTimeLeft() then return true end

	return a:GetTimeLeft() > b:GetTimeLeft()
end

Sort.Alphabetical = function(a, b)
	if not b or not b:GetBuff() then return false end
	if not a or not a:GetBuff() then return true end

	return a:GetBuff() > b:GetBuff()
end

Sort.AlphabeticalReverse = function(b, a)
	if not b or not b:GetBuff() then return false end
	if not a or not a:GetBuff() then return true end

	return a:GetBuff() > b:GetBuff()
end

function Sort:PreUpdateIcons(event, icons)
	local name = tostring(icons)
	if not RegisteredIcons[name] then return end
	if self.db.profile[name].reversed then
		table_sort(icons, self[self.db.profile[name].method .. "Reverse"])
	else
		table_sort(icons, self[self.db.profile[name].method])
	end
end
