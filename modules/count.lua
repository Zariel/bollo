local bollo = LibStub("AceAddon-3.0"):GetAddon("Bollo")
local Count = bollo:NewModule("Count")
local RegisteredIcons = {}

local SML = LibStub("LibSharedMedia-3.0")

do
	local fonts = {}
	function Count:GetFonts()
		for k, v in ipairs(SML:List("font")) do
			fonts[SML:Fetch("font", v)] = v
		end
		return fonts
	end
end

function Count:PostSetBuff(event, buff, index, filter)
	if not RegisteredIcons[buff.name] then return end
	local count = buff:GetCount()
	if count > 1 then
		local db = self.db.profile[buff.name]
		local point = db.point
		local x, y = db.x, db.y
		local anchor, relative, mod = bollo:GetPoint(point)
		buff.count:ClearAllPoints()
		buff.count:SetPoint(anchor, buff, relative, mod * x, y)

		buff.count:SetText(count)
		buff.count:Show()
	else
		buff.count:Hide()
	end
end

function Count:PostCreateIcon(event, parent, buff)
	if not RegisteredIcons[buff.name] then return end

	local db = self.db.profile[buff.name]

	local f = buff:CreateFontString(nil, "OVERLAY")

	local font, size, flag = db.font, db.fontSize, db.fontStyle
	local point = db.point
	local x, y = db.x, db.y
	local col = db.color

	local anchor, relative, mod = bollo:GetPoint(point)

	f:SetFont(font, size, flag)
	f:SetTextColor(col.r, col.g, col.b, col.a)
	f:ClearAllPoints()
	f:SetPoint(anchor, buff, relative, mod * x, y)

	buff.count = f
end

function Count:AddOptions(name)
	-- Name must be the referance to everything else, ie if name
	-- is Buffs then settings are created for bollo.Buffs etc.
	if self.options.args[name] then return end      -- Already have it

	self.count = (self.count or 0) + 1

	local conf = self.options.args
	local icons = bollo.icons[name]
	local db = self.db.profile[name]

	RegisteredIcons[name] = db.enabled

	conf[name] = {
		get = function(info)
			return db[info[# info]]
		end,
		set = function(info, val)
			local key = info[# info]
			db[key] = val
			self:UpdateDisplay(nil, name)
		end,
		["name"] = name,
		type = "group",
		args = {
			info = {
				name = "Display Truncated name of " .. name,
				type = "description",
				order = 2,
			},
			enabled = {
				name = "Enable",
				type = "toggle",
				order = 2.1,
				get = function(info)
					return RegisteredIcons[name]
				end,
				set = function(info, key)
					RegisteredIcons[name] = key
					db.enabled = key
					self:UpdateDisplay(nil, name)
				end,
			},
			pointdesc = {
				name = "Set Where to show the name",
				type = "description",
				order = 3,
			},
			point = {
				name = "point",
				type = "select",
				order = 4,
				values = {
					["TOP"] = "TOP",
					["BOTTOM"] = "BOTTOM",
					["CENTER"] = "CENTER",
				}
			},
			xDesc = {
				name = "Set the X position of the name",
				type = "description",
				order = 5,
			},
			x = {
				order = 7,
				name = "X position",
				type = "range",
				min = -10,
				max = 10,
				step = 1,
			},
			yDesc = {
				name = "Set the Y position of the name",
				type = "description",
				order = 7,
			},
			y = {
				order = 8,
				name = "Y Position",
				type = "range",
				min = -10,
				max = 10,
				step = 1,
			},
			fontDesc = {
				name = "Set the font",
				type = "description",
				order = 8,
			},
			fonts = {
				name = "Fonts",
				guiInline = true,
				type = "group",
				order = 9,
				args = {
					fontDesc = {
						name = "Set the font, uses SharedMedia-3.0",
						type = "description",
						order = 1,
					},
					font = {
						order = 2,
						name = "Font",
						type = "select",
						values = self:GetFonts(),
						set = function(info, val)
							local key = info[# info]
							db[key] = val
							self:UpdateDisplay(nil, name)
						end,
						get = function(info)
							local key = db[info[# info]]
							return key
						end,
					},
					fontSizeDesc = {
						order = 3,
						type = "description",
						name = "Set the font Size",
					},
					fontSize = {
						order = 4,
						name = "Font Size",
						type = "range",
						min = 4,
						max = 30,
						step = 1,
						get = function(info)
							local key = info[# info]
							return db[key]
						end,
						set = function(info, val)
							local key = info[# info]
							db[key] = val
							self:UpdateDisplay(nil, name)
						end,
					},
					fontStyleDesc = {
						order = 5,
						name = "Set the font style (flags)",
						type = "description",
					},
					fontStyle = {
						order = 6,
						name = "Font Style",
						type = "select",
						values = {
							["NONE"] = "NONE",
							["OUTLINE"] = "OUTLINE",
							["THINOUTLINE"] = "THINOUTLINE",
							["THICKOUTLINE"] = "THICKOUTLINE",
						},
					},
					colorDesc = {
						order = 6,
						name = "Set the color of the font",
						type = "description",
					},
					color = {
						type = "color",
						name = "color",
						order = 7,
						hasAlpha = true,
						get = function(info)
							local t = db[info[#info]]
							return t.r, t.g, t.b, t.a
						end,
						set = function(info, r, g, b, a)
							local t = db[info[#info]]
							t.r = r
							t.g = g
							t.b = b
							t.a = a
							self:UpdateDisplay(nil, name)
						end,
					}
				}
			},
		},
	}
end
function Count:OnInitialize()
	local defaults = {
		profile = {
			enabled = true,
			["*"] = {
				["Description"] = "Shows count of buffs/debuffs",
				["font"] = STANDARD_TEXT_FONT,
				["fontStyle"] = "OUTLINE",
				["fontSize"] = 9,
				["x"] = 0,
				["y"] = 0,
				["point"] = "CENTER",
				["color"] = {
					r = 1,
					g = 1,
					b = 1,
					a = 1,
				},
				enabled = true,
			},
		}
	}

	self.db = bollo.db:RegisterNamespace("Count", defaults)

	self.count = 2

	if not self.options then
		self.options = {
			name = "Count",
			type = "group",
			childGroups = "tab",
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
				}
			}
		}
	end

	self:AddOptions("buff")
	self:AddOptions("debuff")
	bollo:AddOptions(self)
	self:SetEnabledState(self.db.profile.enabled)
end

function Count:OnEnable()
	for name, state in pairs(RegisteredIcons) do
		if state then
			for k, v in ipairs(bollo.icons[name]) do
				self:PostCreateIcon(nil, bollo.icons[name], v)
				v.count:Show()
			end
			self:UpdateDisplay(nil, name)
		end
	end

	bollo.RegisterCallback(self, "PostCreateIcon")
	bollo.RegisterCallback(self, "PostSetBuff")
	bollo.RegisterCallback(self, "PostUpdateConfig", "UpdateDisplay")
	bollo.db.RegisterCallback(self, "OnProfileChanged", "UpdateDisplay")
	SML.RegisterCallback(self, "LibSharedMedia_Registered", "GetFonts")
	self:GetFonts()
end

function Count:OnDisable()
	for name in pairs(RegisteredIcons) do
		for k, v in ipairs(bollo.icons[name]) do
			if v.count then
				v.count:Hide()
			end
		end
	end

	bollo.UnregisterCallback(self, "PostCreateIcon")
	bollo.UnregisterCallback(self, "PostSetBuff")
	bollo.UnregisterCallback(self, "PostUpdateConfig")
	bollo.db.UnregisterCallback(self, "OnProfileChanged")
	SML.UnregisterCallback(self, "LibSharedMedia_Registered", "GetFonts")
end

function Count:UpdateDisplay(event, name)
	if not RegisteredIcons[name] then
		for i, buff in ipairs(bollo.icons[name]) do
			if buff.count then
				buff.count:Hide()
			end
		end
	else
		for i, buff in ipairs(bollo.icons[name]) do
			if not buff.text then self:PostCreateIcon(nil, nil, buff) end
			local db = self.db.profile[buff.name]
			local font, size, flag = db.font, db.fontSize, db.fontStyle
			local point = db.point
			local x, y = db.x, db.y
			local col = db.color

			local anchor, relative, mod = bollo:GetPoint(point)

			buff.count:SetFont(font, size, flag)
			buff.count:ClearAllPoints()
			buff.count:SetPoint(anchor, buff, relative, mod * x, y)
			buff.count:SetTextColor(col.r, col.g, col.b, col.a)
		end
	end
end
