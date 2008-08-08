local bollo = LibStub("AceAddon-3.0"):GetAddon("Bollo")
local SML = LibStub("LibSharedMedia-3.0")
local duration = bollo:NewModule("Duration")

local RegisteredIcons = {}

do
	local fonts = {}
	function duration:GetFonts()
		for k, v in ipairs(SML:List("font")) do
			fonts[SML:Fetch("font", v)] = v
		end
		return fonts
	end
end

function duration:AddOptions(name, db, module, forced)
	-- Name must be the referance to everything else, ie if name
	-- is Buffs then settings are created for bollo.Buffs etc.
	if self.options.args[name] then return end      -- Already have it

	self.count = (self.count or 0) + 1

	local conf = self.options.args
	local icons = bollo.icons[name]
	module = module or self

	-- Probally not a good idea
	if db then
		self.db.profile[name] = db
	end

	db = db or self.db.profile[name]
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
		disabled = function()
			return not module:IsEnabled()
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
				get = function(info)
					return RegisteredIcons[name]
				end,
				set = function(info, key)
					RegisteredIcons[name] = key
					db.enabled = key
					self:UpdateDisplay(nil, name)
				end,
				order = 2.1,
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
			format = {
				name = "Format",
				type = "select",
				values = {
					["M:SS"] = "Verbose",
					["MM"] = "Blizzard",
				},
				order = 9,
			},
			fonts = {
				name = "Fonts",
				guiInline = true,
				type = "group",
				order = 10,
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

	self:UpdateDisplay(nil, name)
end

function duration:OnInitialize()
	local defaults = {
		profile = {
			enabled = true,
			["*"] = {
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
				enabled = true,
			},
		}
	}

	self.db =  bollo.db:RegisterNamespace("Duration", defaults)

	self.count = 2

	self.options = {
		name = "Duration",
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

	bollo:AddOptions(self)
	self:SetEnabledState(self.db.profile.enabled)
end

function duration:UpdateDisplay(event, name)
	if not name then return end

	if not RegisteredIcons[name] then
		for i, buff in ipairs(bollo.icons[name]) do
			if buff.duration then
				buff.duration:Hide()
			end
		end
	else
		for i, buff in ipairs(bollo.icons[name]) do
			if not buff.duration then self:PostCreateIcon(nil, bollo.icons[name], buff) end
			local font, size, flag = self.db.profile[name].font, self.db.profile[name].fontSize, self.db.profile[name].fontStyle
			local point = self.db.profile[name].point
			local x, y = self.db.profile[name].x, self.db.profile[name].y
			local col = self.db.profile[name].color

			local anchor, relative, mod = bollo:GetPoint(point)

			buff.duration:SetFont(font, size, flag)
			buff.duration:ClearAllPoints()
			buff.duration:SetPoint(anchor, buff, relative, mod * x, y)
			buff.duration:SetTextColor(col.r, col.g, col.b, col.a)
			buff.duration:Show()
		end
	end
end

function duration:PostCreateIcon(event, parent, button)
	if not RegisteredIcons[button.name] then return end

	local db = self.db.profile[button.name]
	local duration = button:CreateFontString(nil, "OVERLAY")
	local font, size, flag = db.font, db.fontSize, db.fontStyle
	local point = db.point
	local x, y = db.x, db.y
	local col = db.color

	local anchor, relative, mod = bollo:GetPoint(point)

	duration:SetFont(font, size, flag)
	duration:ClearAllPoints()
	duration:SetPoint(anchor, button, relative, mod * x, y)
	duration:SetTextColor(col.r, col.g, col.b, col.a)
	button.duration = duration
end

function duration:OnEnable()
	self:AddOptions("buff")
	self:AddOptions("debuff")

	for name, state in pairs(RegisteredIcons) do
		if state then
			for k, v in ipairs(bollo.icons[name]) do
				self:PostCreateIcon(nil, bollo.icons[name], v)
				v.duration:Show()
			end
			self:UpdateDisplay(nil, name)
		end
	end

	SML.RegisterCallback(self, "LibSharedMedia_Registered", "GetFonts")
	self:GetFonts()

	bollo.db.RegisterCallback(self, "OnProfileChanged", "UpdateDisplay")
	bollo.RegisterCallback(self, "PostCreateIcon")
	bollo.RegisterCallback(self, "OnUpdate")
	bollo.RegisterCallback(self, "UpdateIconPosition")
end

function duration:OnDisable()
	bollo.UnregisterCallback(self, "PostCreateIcon")
	bollo.UnregisterCallback(self, "OnUpdate")
	bollo.UnregisterCallback(self, "PostUpdateConfig")
	bollo.UnregisterCallback(self, "UpdateIconPosition")
	SML.UnregisterCallback(self, "LibSharedMedia_Registered")
	bollo.db.UnregisterCallback(self, "OnProfileChanged")

	for name in pairs(RegisteredIcons) do
		for k, v in ipairs(bollo.icons[name]) do
			if v.duration then
				v.duration:Hide()
			end
		end
	end
end

function duration:UpdateIconPosition(event, index, buff, icons)
	if RegisteredIcons[buff.name] then
		local db = self.db.profile[buff.name]
		local point = db.point
		local x, y = db.x, db.y
		local anchor, relative, mod = bollo:GetPoint(point)

		buff.duration:ClearAllPoints()
		buff.duration:SetPoint(anchor, buff, relative, mod * x, y)
	end
end

function duration:FormatTime(type, time)
	local hr, m, s, text
	if type == "M:SS" then
		text = "%d:%02.f"
		if time < 60 then
			m = 0
			s = time
		elseif time < 3600 then --1 hr
			m = math.floor(time/60)
			s = math.fmod(time, 60)
		elseif time >= 3660 then
			hr = math.floor(time / 60)
			m = math.floor(math.fmod(time, 3600) / 60)
		end
		return text, hr or m, hr and m or s
	elseif type == "MM" then
		if time > 3600 then
			m = math.floor(time / 360) / 10
			text = "%dhr"
		elseif time > 60 then
			m = math.floor(mod(time, 3600) / 60)
			text = "%dm"
		else
			m = time
			text = "%ds"
		end
		return text, m
	end
end

function duration:OnUpdate()
	for name, state in pairs(RegisteredIcons) do
		if state then
			for index, buff in ipairs(bollo.icons[name]) do
				if not buff.duration then self:PostAuraCreate(nil, nil, buff) end
				local timeLeft = buff:GetTimeLeft()
				if timeLeft and (type(timeLeft) == "number" and timeLeft > 0) then
					buff.duration:SetFormattedText(duration:FormatTime(duration.db.profile[name].format, timeLeft))
					buff.duration:Show()
				else
					buff.duration:Hide()
				end
			end
		end
	end
end
