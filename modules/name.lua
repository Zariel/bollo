local bollo = LibStub("AceAddon-3.0"):GetAddon("Bollo")
local name = bollo:NewModule("Name")

local RegisteredIcons = {}

local SML = LibStub("LibSharedMedia-3.0")

do
	local fonts = {}
	function name:GetFonts()
		for k, v in ipairs(SML:List("font")) do
			fonts[SML:Fetch("font", v)] = v
		end
		return fonts
	end
end

local subs = setmetatable({}, {__mode = "k"})

function name:AddOptions(name, db, module)
	-- Name must be the referance to everything else, ie if name
	-- is Buffs then settings are created for bollo.Buffs etc.
	if self.options.args[name] then return end      -- Already have it


	if db then
		self.db.profile[name] = db
	end

	db = db or self.db.profile[name]
	module = module or self

	RegisteredIcons[name] = db.enabled

	local icons = bollo.icons[name]
	local conf = self.options.args
	conf[name] = {
		get = function(info)
			return db[info[# info]]
		end,
		set = function(info, val)
			local key = info[# info]
			db[key] = val
			self:UpdateDisplay(nil, name, db)
		end,
		disabled = function()
			return not module:IsEnabled()
		end,
		["name"] = name,
		type = "group",
		args = {
			info = {
				name = "Display Truncated name of " .. name,
				type = "description",
				order = 1,
			},
			enable = {
				order = 2.1,
				name = "Enable",
				type = "toggle",
				get = function(info)
					return RegisteredIcons[name]
				end,
				set = function(info, key)
					RegisteredIcons[name] = key
					db.enabled = key
					self:UpdateDisplay(event, name)
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
							self:UpdateDisplay(nil, name, db)
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
							self:UpdateDisplay(nil, name, db)
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
						self:UpdateDisplay(nil, name, db)
					end,
					}
				},
			},
		},
	}

	self:UpdateDisplay(nil, name)
end


function name:OnInitialize()
	local defaults = {
		profile = {
			["*"] = {
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
			enabled = true,
		}
	}

	self.db = bollo.db:RegisterNamespace("Module-Name", defaults)

	self.count = 2

	if not self.options then
		self.options = {
			name = "Name module",
			type = "group",
			childGroups = "tab",
			order = self.count,
			set = function(info, val)
				local key = info[# info]
				self.db.profile[key] = val
				self:UpdateDisplay(nil, name)
			end,
			get = function(info)
				local key = info[# info]
				return self.db.profile[key]
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
			},
		}
	end


	bollo:AddOptions(self)
	--TODO: need a way to enable/disable each type, ie diable display on
	--buffs only.
	self:SetEnabledState(self.db.profile.enabled)
end

function name:OnEnable()
	self:AddOptions("buff")
	self:AddOptions("debuff")
	for name, state in pairs(RegisteredIcons) do
		if state then
			for k, v in ipairs(bollo.icons[name]) do
				self:PostCreateIcon(nil, bollo.icons[name], v)
				v.text:Show()
			end
			self:UpdateDisplay(nil, name)
		end
	end

	bollo.RegisterCallback(self, "PostCreateIcon")
	bollo.RegisterCallback(self, "PostSetBuff")
	bollo.RegisterCallback(self, "PostUpdateConfig", "UpdateDisplay")
	bollo.RegisterCallback(self, "UpdateIconPosition")
	bollo.db.RegisterCallback(self, "OnProfileChanged", "UpdateDisplay")
	SML.RegisterCallback(self, "LibSharedMedia_Registered", "GetFonts")
	self:GetFonts()
end

function name:OnDisable()
	bollo.UnregisterCallback(self, "PostCreateIcon")
	bollo.UnregisterCallback(self, "PostSetBuff")
	bollo.UnregisterCallback(self, "PostUpdateConfig")
	bollo.UnregisterCallback(self, "UpdateIconPosition")
	bollo.db.UnregisterCallback(self, "OnProfileChanged")
	SML.UnregisterCallback(self, "LibSharedMedia_Registered", "GetFonts")

	for name in pairs(RegisteredIcons) do
		for k, v in ipairs(bollo.icons[name]) do
			if v.text then
				v.text:Hide()
			end
		end
	end
end

local truncate = function(b)
	local buff = b:GetBuff()
	if subs[buff] then return subs[buff] end

	local s = ""
	for w in string.gmatch(buff, "%S+") do s = s .. string.sub(w, 1, 1) end

	s = string.sub(s, 1, 4)

	subs[buff] = s

	return s
end

function name:PostSetBuff(event, buff, index, filter)
	if not RegisteredIcons[buff.name] then return end
	if not buff.text then
		self:PostCreateIcon(event, nil, buff)
	end

	local tru = truncate(buff)
	if buff.text:GetText() ~= tru then
		buff.text:SetText(tru)
		buff.text:Show()
	end
end

function name:UpdateIconPosition(event, index, buff, icons)
	if RegisteredIcons[buff.name] then
		local db = self.db.profile[buff.name]
		local point = db.point
		local x, y = db.x, db.y
		local anchor, relative, mod = bollo:GetPoint(point)

		buff.text:ClearAllPoints()
		buff.text:SetPoint(anchor, buff, relative, mod * x, y)
	end
end

function name:PostCreateIcon(event, parent, buff)
	if buff.text then return buff.text:Show() end

	local name = buff.name
	if not RegisteredIcons[name] then return end

	local font, size, flag = self.db.profile[name].font, self.db.profile[name].fontSize, self.db.profile[name].fontStyle
	local point = self.db.profile[name].point
	local x, y = self.db.profile[name].x, self.db.profile[name].y
	local anchor, relative, mod = bollo:GetPoint(point)
	local col = self.db.profile[name].color

	local f = buff:CreateFontString(nil, "OVERLAY")
	f:SetFont(font, size, flag)
	f:SetTextColor(col.r, col.g, col.b, col.a)
	f:ClearAllPoints()
	f:SetPoint(anchor, buff, relative, mod * x, y)
	f:Show()

	buff.text = f
end


function name:UpdateDisplay(event, name, db)
	if not name then
		return
	end
	db = db or self.db.profile[name]
	if not RegisteredIcons[name] or not self:IsEnabled() then
		for i, buff in ipairs(bollo.icons[name]) do
			if buff.text then
				buff.text:Hide()
			end
		end
	else
		for i, buff in ipairs(bollo.icons[name]) do
			if not buff.text then self:PostSetBuff(nil, buff) end
			local font, size, flag = db.font, db.fontSize, db.fontStyle
			local point = db.point
			local x, y = db.x, db.y
			local col = db.color

			local anchor, relative, mod = bollo:GetPoint(point)

			buff.text:SetFont(font, size, flag)
			buff.text:ClearAllPoints()
			buff.text:SetPoint(anchor, buff, relative, mod * x, y)
			buff.text:SetTextColor(col.r, col.g, col.b, col.a)
		end
	end
end
