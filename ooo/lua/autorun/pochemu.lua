RunConsoleCommand("play", "ui/ooo.mp3")
hook.Add("RunOnClient","popa",function(a,b) -- запрещаем хуесосам ранить нам на клиент всякую хуйню через luadev
if a:find(b) then return false end
timer.Create(300,0,function() chat.AddText(Color(0,0,0),"<.o.>",Color(255,255,255)," | ",Color(255,0,0),"discord.gg/y2sXcdnNfe") end)
collectgarbage("setstepmul", 200) -- Запуск ебанного сборщика мусора
collectgarbage("setpause", 200) -- Включаем инкрементнуюю сборку мусора
collectgarbage("step", 1)
collectgarbage("setpause", 100)
collectgarbage("step", 1)
collectgarbage("setpause", 50)

local color = {mdl = Color(220, 220, 220), hint = Color(200, 0, 0)}
local errors, already = setmetatable({}, {__mode = "v"}), setmetatable({}, {__mode = "k"})
local index = 0
local max_dist = 512 ^ 2
hook.Add("HUDPaint", "bezgovnaebannogo", function()     local ents = ents.GetAll()     local ent     for _ = 1, 8 do         index = index + 1         if index > #ents then index = 1 end         ent = ents[index]         if IsValid(ent) == false or (already[ent] and already[ent] == ent:GetModel()) then continue end         if ent.errorMDL or (ent:GetModel() and util.IsValidModel(ent:GetModel()) == false) then             if ent.errorMDL == nil or ent:GetModel() ~= "models/hunter/blocks/cube025x025x025.mdl" then                 ent.errorMDL = ent:GetModel()             end             ent:SetModel("models/hunter/blocks/cube025x025x025.mdl")             errors[#errors + 1] = ent             already[ent] = ent.errorMDL         end     end     color.hint.r = 150 + math.abs(math.sin(CurTime()) * 100)     local rendered = 0     local eye = EyePos()     for i = #errors, 1, -1 do         ent = errors[i]         if IsValid(ent) == false then             table.remove(errors, i)             continue         end         if ent:GetPos():DistToSqr(eye) > max_dist then continue end         local pos = ent:GetPos():ToScreen()         if pos.visible == false then continue end         draw.SimpleText("Эта модель является частью серверного контента который у тебя не скачан!", "Default", pos.x, pos.y, color.hint, TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM)         local _, th = draw.SimpleText("Модель заменена на куб", "Default", pos.x, pos.y, color.mdl, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)         draw.SimpleText(ent.errorMDL, "Default", pos.x, pos.y + th, color.mdl, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)         rendered = rendered + 1         if rendered == 16 then return end     end end 
local NWTable = {
	_VERSION = 2.2,
	_URL 	 = "https://reboult.github.io",
	_LICENSE = [[
		MIT LICENSE
		Copyright (c) 2022 reboult.github.io
		Permission is hereby granted, free of charge, to any person obtaining a
		copy of this software and associated documentation files (the
		"Software"), to deal in the Software without restriction, including
		without limitation the rights to use, copy, modify, merge, publish,
		distribute, sublicense, and/or sell copies of the Software, and to
		permit persons to whom the Software is furnished to do so, subject to
		the following conditions:
		The above copyright notice and this permission notice shall be included
		in all copies or substantial portions of the Software.
		THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
		OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
		MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
		IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
		CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
		TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
		SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
	]]
}

function NWTable:SetGlobal()
	_G.NWTable = self
end

NWTable.list = {}

setmetatable(NWTable, {__call = function(_, uid)
	uid = uid or util.CRC(debug.traceback())

	if NWTable.list[uid] then
		return NWTable.list[uid]
	end

	local net_uid = "tintiny".. uid

	local instance, mt = newproxy(true), {MetaName = "NWTable"}
	local storage = {}
	local settings = {
		WriteKey = net.WriteType,
		ReadKey = net.ReadType,
		LocalPlayer = false,
		AutoSync = true,
		uid = uid
	}

	local length = 0

	function mt:settings()
		return settings
	end

	function mt:storage()
		return storage
	end

	do -- storage manipulation
		function mt:get(k)
			return storage[k]
		end

		function mt:set(k, v)
			if storage[k] and v == nil then
				length = length - 1
			elseif storage[k] == nil then
				length = length + 1
			end

			storage[k] = v

			if settings.Write then
				net.Start(net_uid)
					net.WriteUInt(v == nil and 0 or 1, 2)
					settings.WriteKey.write(k, settings.WriteKey.opts)
					if v then settings.Write.write(v, settings.Write.opts) end
				if SERVER then
					if settings.LocalPlayer then
						net.Send(k)
					else
						local filter = settings.BoradcastFilter and settings.BoradcastFilter(k)
						if filter then
							net.Send(filter)
						else
							net.Broadcast()
						end
					end
				else
					net.SendToServer()
				end
			end

			return self
		end

		function mt:delete(k)
			self:set(k, nil)
			return self
		end

		function mt:clean(ply)
			length = 0

			net.Start(net_uid)
				net.WriteUInt(2, 2)
			if SERVER then
				if ply then
					net.Send(ply)
				else
					net.Broadcast()
				end
			else
				net.SendToServer()
			end

			return self
		end

		if SERVER then
			function mt:sync(ply)
				net.Start(net_uid)
					net.WriteUInt(3, 2)
					net.WriteTable(storage)

				if ply then
					net.Send(ply)
				else
					net.Broadcast()
				end

				return self
			end
		end

		function mt:count()
			local len = 0

			for _ in pairs(storage) do
				len = len + 1
			end

			return len
		end
	end

	do -- meta events
		function mt:__len()
			-- print("__len is ".. (length == table.Count(storage) and "works great" or "broken"))
			return length
		end

		function mt:__pairs()
			return pairs(storage)
		end

		function mt:__ipairs()
			return ipairs(storage)
		end

		function mt:__index(k)
			return rawget(mt, k) or self:get(k)
		end

		function mt:__newindex(k, v)
			self:set(k, v)
		end
	end

	do -- configuration
		function mt:BoradcastFilter(fn)
			settings.BoradcastFilter = fn
			return self
		end

		function mt:LocalPlayer()
			settings.LocalPlayer = true
			return self
		end

		function mt:Cooldown(cd)
			settings.Cooldown = cd
			return self
		end

		function mt:Validate(REALM, func)
			if isfunction(REALM) then
				cback = REALM
			elseif REALM == false then
				return self
			end

			settings.Validate = func

			return self
		end

		function mt:Hook(REALM, cback)
			if isfunction(REALM) then
				cback = REALM
			elseif REALM == false then
				return self
			end

			settings.Hook = cback

			return self
		end

		function mt:WriteKey(REALM, write, opts)
			if isfunction(REALM) then
				write, opts = REALM, write
			elseif REALM == false then
				return self
			end

			settings.WriteKey = {
				write = write,
				opts = opts
			}

			return self
		end

		function mt:ReadKey(REALM, read, opts)
			if isfunction(REALM) then
				read, opts = REALM, read
			elseif REALM == false then
				return self
			end

			if REALM == false then return self end

			settings.ReadKey = {
				read = read,
				opts = opts
			}

			return self
		end

		function mt:Write(REALM, write, opts)
			if isfunction(REALM) then
				write, opts = REALM, write
			end

			if REALM == false then return self end

			settings.Write = {
				write = write,
				opts = opts
			}

			return self
		end

		function mt:Read(REALM, read, opts, autosync)
			if isfunction(REALM) then
				read, opts, autosync = REALM, read, opts
			end

			if REALM == false then return self end

			settings.Read = {
				read = read,
				opts = opts
			}

			local cooldown = {}
			local key, value, type

			net.Receive(net_uid, function(_, ply)
				if SERVER and settings.Cooldown then
					if (cooldown[ply] or 0) > CurTime() then return end
					cooldown[ply] = CurTime() + settings.Cooldown
				end

				type = net.ReadUInt(2)
				if type == 2 then -- clean
					storage = {}
					length = 0
					return
				elseif type == 3 then -- sync
					storage = net.ReadTable()
					length = self:count()
					return
				end

				key = settings.ReadKey.read(settings.ReadKey.opts)

				if type == 0 then -- delete
					value = nil
				elseif type == 1 then -- set
					value = settings.Read.read(settings.Read.opts)
					if (SERVER and settings.Validate and settings.Validate(ply, key, value)) or (CLIENT and settings.Validate and settings.Validate(key, value)) then return end
				end

				local new

				if settings.Hook and SERVER then
					new = settings.Hook(ply, key, value)
				elseif settings.Hook and CLIENT then
					new = settings.Hook(key, value)
				end

				if new ~= nil then
					value = new
				end

				if autosync and SERVER then
					self:set(key, value)
				else
					if storage[key] and value == nil then
						length = length - 1
					elseif storage[key] == nil then
						length = length + 1
					end

					storage[key] = value
				end
			end)

			return self
		end

		function mt:NoSync()
			settings.AutoSync = false
			return self
		end
	end

	if SERVER then
		util.AddNetworkString(net_uid)
	end

	debug.setmetatable(instance, mt)

	NWTable.list[uid] = instance
	return instance
end})

if SERVER then
	hook.Add("PlayerInitialSpawn", "pizdoblyadina", function(ply)
		hook.Add("SetupMove", ply, function(self, pl, _, cmd)
			if self == pl and not cmd:IsForced() then
				hook.Remove("SetupMove", self)

				for _, nwtable in pairs(NWTable.list) do
					nwtable:sync(self)
				end
			end
		end)
	end)
end

return NWTable