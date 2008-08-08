local bollo = LibStub("AceAddon-3.0"):GetAddon("Bollo")
local bf = bollo:NewModule("ButtonFacade", "AceConsole-3.0")
local lib
local SetVertexColor

local layers = {
	"Backdrop",
	"Flash",
	"Border",
	"Normal",
	"Pushed",
	"Disabled",
	"Checked",
	"Highlight",
	"Gloss",
}

function bf:PostCreateIcon(event, parent, button)
	button.border._SetVertexColor = button.border.SetVertexColor

	local data = {
		["Icon"] = button.icon,
		["Border"] = button.border,
		["normalTexture"] = button.icon,
		["Count"] = button.count,
	}

	local G = lib:Group("Bollo", button.name)

	G:AddButton(button, data)

	if self.db.profile[button.name] then
		local db = self.db.profile[button.name]
		G:Skin(unpack(db))
	end
end

function bf:PostSetBuff(event, button)
	if button.name == "debuff" then
		local index = button:GetID()
		local col = DebuffTypeColor[GetPlayerBuffDispelType(index) or "none"]
		button:SetLayerColor("Border", col.r, col.g, col.b)
	end
end

function bf:OnInitialize()
	local defaults = {
		profile = {
			enabled = true,
		}
	}

	self.db = bollo.db:RegisterNamespace("Bollo-ButtonFacade", defaults)

	self.options = {
		type = "group",
		name = "Button Facade",
		args = {
			enableDesc = {
				type = "description",
				name = "Enable the Button Facade module, will only take effect after reload of UI",
				order = 1,
			},
			enabled = {
				type = "toggle",
				name = "Enable",
				order = 2,
				set = function(info, val)
					local key = info[# info]
					self.db.profile[key] = val
					if val then
						self:Enable()
					else
						self:Disable()
					end
				end,
				get = function(info)
					local key = info[# info]
					return self.db.profile[key]
				end
			},
		},
	}

	bollo:AddOptions(self)

	self:SetEnabledState(self.db.profile.enabled)
end

function bf:UpdateSkin(SkinID, Gloss, Backdrop, Group, Button, Colors)
	if Group then
		self.db.profile[Group] = self.db.profile[Group] or {}
		local db = self.db.profile[Group]
		db[1] = SkinID
		db[2] = Gloss
		db[3] = Backdrop
		db[4] = Colors
	end
end

function bf:OnEnable()
	lib = lib or LibStub("LibButtonFacade")

	lib:RegisterSkinCallback("Bollo", self.UpdateSkin, self)
	bollo.RegisterCallback(bf, "PostCreateIcon")
	bollo.RegisterCallback(bf, "PostSetBuff")
	bollo.RegisterCallback(bf, "PostUpdateConfig", "UpdateSkins")
	bollo.RegisterCallback(bf, "NewIconGroup", "UpdateSkins")

	self:UpdateSkins()
end

function bf:UpdateSkins(event)
	for name in pairs(bollo.icons) do
		for k, v in ipairs(bollo.icons[name]) do
			self:PostCreateIcon(nil, bollo.icons[name], v)
		end
	end
end

function bf:NewIconGroup(event, name, table)
end

function bf:OnDisable()
	self.Print(self, "To unskin the buffs you must reload your interface")
	bollo.UnregisterCallback(bf, "PostCreateIcon")
	bollo.UnregisterCallback(bf, "PostSetBuff")
	bollo.UnregisterCallback(bf, "PostUpdateConfig")
end
