--[[
	config.lua
		Adds module configs to interface panels
]]

local bollo = LibStub("AceAddon-3.0"):GetAddon("Bollo")
local conf = bollo:NewModule("Config", "AceConsole-3.0")

local optGet = function(info)
	local key = info[#info]
	return bollo.db.profile[key]
end

--[[
	:AddChildOptions(name)
	args:
		name - Name of what your adding, ie buff. Must be the same as what is in your db and the bollo.icons
]]

function conf:AddChildOpts(name, db, module)
	if type(name) ~= "string" then
		error("Bad argument to #1 :AddChildOpts, expected string")
	end

	if bollo.options.args[name] then return end -- Already added.

	local c = bollo.options.args
	local db = db or bollo.db.profile[name]
	local icons = bollo.icons[name]

	self.count = (self.count or 0) + 1

	if not module then
		module = bollo
	end

	c[name] = {
		order = self.count,
		type = "group",
		set = function(info, val)
			local key = info[# info]
			db[key] = val
			bollo:UpdateSettings(icons, db)
		end,
		get = function(info)
			local key = info[# info]
			return db[key]
		end,
		disabled = function()
			return not module:IsEnabled()
		end,
		name = name .. " Settings",
		args = {
			desc = {
				order = 1,
				type = "description",
				name = "Settings for Buff display",
			},
			sizeDesc = {
				order = 2,
				name = "Set the size of the buffs (height and width)",
				type = "description",
			},
			size = {
				order = 3,
				name = "Size",
				type = "range",
				min = 10,
				max = 100,
				step = 1,
			},
			spacingDesc = {
				order = 4,
				name = "Set the horizontal spacing between buffs",
				type = "description",
			},
			spacing = {
				order = 5,
				name = "Spacing",
				type = "range",
				min = -20,
				max = 20,
				step = 1,
			},
			rowSpacingDesc = {
				order = 5,
				name = "Set the vertical spacing between rows",
				type = "description",
			},
			rowSpace = {
				order = 6,
				name = "Row Spacing",
				type = "range",
				min = 0,
				max = 50,
				step = 1,
			},
			perRow_desc = {
				order = 7,
				name = "Set the max icons per row",
				type = "description",
			},
			perRow = {
				type = "range",
				name = "Per Row",
				order = 8,
				step = 1,
				min = 1,
				max = 40,
			},
			growthxDesc = {
				order = 11,
				name = "Set the Growth-X",
				type = "description",
			},
			growthx = {
				order = 12,
				name = "Growth X",
				type = "select",
				values = {
					["LEFT"] = "LEFT",
					["RIGHT"] = "RIGHT",
				},
			},
			growthyDesc = {
				order = 13,
				name = "Set the Growth-X",
				type = "description",
			},
			growthy = {
				order = 14,
				name = "Growth X",
				type = "select",
				values = {
					["UP"] = "UP",
					["DOWN"] = "DOWN",
				},
			},
			lockDesc = {
				order = 15,
				name = "Lock or unlock the display",
				type = "description",
			},
			lock = {
				order = 16,
				name = "lock",
				type = "toggle",
				set = function(info, key)
					if key then
						icons.bg:Hide()
					else
						icons.bg:Show()
					end
					icons.lock = key
				end,
				get = function(info)
					return not icons.bg:IsShown()
				end,
			},
		}
	}
end

local defaults
function conf:InitCore()
	if not defaults then
		defaults = {
			type = "group",
			name = "Bollo",
			order = 1,
			type = "group",
			childGroups  = "tab",
			args = {
				desc = {
					order = 1,
					type = "description",
					name = "Bollo displays Buffs and Debuffs",
				},
			}
		}
	end

	return defaults
end


function conf:OnInitialize()
	bollo.options = self:InitCore()
	LibStub("AceConfigRegistry-3.0"):RegisterOptionsTable("Bollo", defaults)
	LibStub("AceConfigDialog-3.0"):AddToBlizOptions("Bollo", "Bollo", nil)

	self:RegisterChatCommand("bollo", function() InterfaceOptionsFrame_OpenToFrame(LibStub("AceConfigDialog-3.0").BlizOptions["Bollo"].frame) end)

	local ldb = LibStub("LibDataBroker-1.1", true)
	if ldb then
		ldb:NewDataObject("Bollo", {
			type = "launcher",
			icon = "Interface\\Icons\\Spell_Shadow_DeathCoil",
			OnClick = function()
				InterfaceOptionsFrame_OpenToFrame(LibStub("AceConfigDialog-3.0").BlizOptions["Bollo"].frame)
			end,
		})
	end
end

function conf:OnEnable()
	self:AddChildOpts("buff")
	self:AddChildOpts("debuff")
end

function bollo:AddOptions(module)
	if module.options then
		local modName = tostring(module)
		local name = modName:match("Bollo_(.+)")
		LibStub("AceConfigRegistry-3.0"):RegisterOptionsTable(modName, module.options)
		module.bliz = LibStub("AceConfigDialog-3.0"):AddToBlizOptions(modName, name, "Bollo")
	end
end
