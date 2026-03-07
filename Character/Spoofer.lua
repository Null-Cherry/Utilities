local rawget, rawset = rawget, rawset
local pack, unpack = table.pack, table.unpack
local wait = task.wait
local zero = Vector3.zero
local ws = workspace
local ni = Instance.new
local cfr = CFrame
local xyz = cfr.fromEulerAnglesXYZ
local ncf = cfr.new
local v3 = Vector3.new
local cfzero = ncf()
local find = table.find
local error = error
local pcall = pcall
local typeof = typeof
local tonum = tonumber
local spawn = task.spawn
local freeze = table.freeze
local smt = setmetatable
local insert = table.insert
local remove = table.remove

local connectionBase = {
	Disconnect = function(self)
		rawset(self, "Connected", false)
		freeze(self)
	end,
	Fire = function(self, ...)
		if not self.Connected then
			error("Event is not connected!", 0)
		end
		
		if not self.Enabled then return end
		
		spawn(self.Callback, ...)
	end,
}

connectionBase = { __index = connectionBase }

local eventBase = {
	Connect = function(self, func)
		local connection = smt({ Callback = func, Connected = true, Enabled = true }, connectionBase)
		insert(self._Connections, connection)
		
		return connection
	end,
	Once = function(self, func)
		local con; con = self:Connect(function(...)
			con:Disconnect()
			con = nil
			
			func(...)
		end)
		
		return con
	end,
	Wait = function(self)
		local result
		self:Once(function(...)
			result = pack(...)
		end)
		
		repeat wait() until result
		return unpack(result, 1, result.n)
	end,
	Fire = function(self, ...)
		local cons = self._Connections
		for i = #cons, 1, -1 do
			local v = cons[i]
			if v.Connected then
				v:Fire(...)
			else
				remove(cons, i)
			end
		end
	end
}

eventBase = { __index = eventBase }

local event = {
	new = function()
		return smt({ _Connections = { } }, eventBase)
	end
}

local plr = game:GetService("Players").LocalPlayer
local rs = game:GetService("RunService")

local cCFrame, root

local hb = rs.Heartbeat
local rns = rs.RenderStepped
local s = rs.Stepped

local beforeSpoofingEvent = event.new()
local afterSpoofingEvent = event.new()
local afterSpoofingLoopEvent = event.new()
local beforeSpoofingLoopEvent = event.new()
local startSpoofingLoopEvent = event.new()

local fire = beforeSpoofingEvent.Fire
local d = game.Destroy

local can = pcall(function() plr.DevCameraOcclusionMode = plr.DevCameraOcclusionMode end)
local origin = can and plr.DevCameraOcclusionMode

local values = { -- replace nil with any Vector3
	AbsoluteRelativePosition = nil,
	RelativePosition = nil,
	AbsolutePosition = nil,
	RelativeRotation = nil,
	AbsoluteRotation = nil,
	RelativeVelocity = nil,
	AbsoluteVelocity = nil,
	RelativeAngularVelocity = nil,
	AbsoluteAngularVelocity = nil,

	ShowSpoofedPosition = false,
	AdjustCamera = true,
	Enabled = true,
	NewEvent = event.new,

	BeforeSpoofing = beforeSpoofingEvent,
	AfterSpoofing = afterSpoofingEvent,
	AfterSpoofingLoop = afterSpoofingLoopEvent,
	BeforeSpoofingLoop = afterSpoofingLoopEvent,
	StartSpoofingLoop = afterSpoofingLoopEvent
}

local part
local prev

local cameraBypass = false
local set = false

local function r(a, b, c)
	root.CFrame = a
	root.AssemblyLinearVelocity = b
	root.AssemblyAngularVelocity = c
end

task.spawn(function()
	while hb:Wait() do
		if not values.Enabled then continue end

		beforeSpoofingLoopEvent:Fire()

		local pos, vel1, vel2 = nil, nil, nil
		local character

		while not (character and character.Parent and root and root.Parent) do
			hb:Wait()
			character = plr.Character

			if not character or not character.Parent then continue end

			root = character:FindFirstChild("HumanoidRootPart")
			if not root then
				local hum = character:FindFirstChildOfClass("Humanoid")
				if hum then
					root = hum.RootPart
				end
			end
		end

		startSpoofingLoopEvent:Fire()

		pos, vel1, vel2 = root.CFrame, root.AssemblyLinearVelocity, root.AssemblyAngularVelocity

		local re = values.RelativePosition or zero

		local rt = values.RelativeRotation or zero
		local rot = (values.AbsoluteRotation or v3(pos.Rotation:ToOrientation())) + v3(rt.Y, rt.X, rt.Z)

		cCFrame = (ncf((values.AbsolutePosition or pos.Position)) * xyz(rot.X, rot.Y, rot.Z)) + (pos.XVector * re.X) + (pos.YVector * re.Y) + (pos.ZVector * re.Z) + (values.AbsoluteRelativePosition or zero)

		beforeSpoofingEvent:Fire()

		r(
			cCFrame,
			(values.AbsoluteVelocity or root.AssemblyLinearVelocity) + (values.RelativeVelocity or zero),
			(values.AbsoluteAngularVelocity or root.AssemblyAngularVelocity) + (values.RelativeAngularVelocity or zero)
		)

		afterSpoofingEvent:Fire()

		cameraBypass = (pos.Position - cCFrame.Position).Magnitude > 1

		rns:Wait()
		r(pos, vel1, vel2)

		s:Wait()
		r(pos, vel1, vel2)

		afterSpoofingLoopEvent:Fire()
	end
end)

values.BeforeSpoofing:Connect(function()
	if not values.Enabled then
		if part then
			part.Parent = nil
		end

		return
	end

	if can then
		if cameraBypass then
			plr.DevCameraOcclusionMode = Enum.DevCameraOcclusionMode.Invisicam
			set = false
		elseif not set then
			set = true
			plr.DevCameraOcclusionMode = origin
		end
	end

	local ssp = values.ShowSpoofedPosition
	if (not part or not part:IsDescendantOf(ws)) and ssp then
		pcall(d, part)
		part = ni("Part")
	end

	if not part then return end

	part.Parent = ssp and (ws.CurrentCamera or ws.Terrain or ws) or nil

	if not ssp then return end

	part.Transparency = 0.75
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.Name = "SpoofDisplay"
	part.Size = v3(2, 2, 1)
	part.CFrame = cCFrame or cfzero
	part.Anchored = true
end)

values.AfterSpoofingLoop:Connect(function()
	if not values.AdjustCamera or not values.Enabled then return end

	local cam = ws.CurrentCamera
	if root and cam.CFrame ~= prev and cCFrame then
		cam.CFrame += (root.CFrame.Position - cCFrame.Position)
		prev = cam.CFrame
	end
end)

-- LIBRARY --

local vectorIndexes = {
	"AbsoluteRelativePosition",
	"RelativePosition",
	"AbsolutePosition",
	"RelativeRotation",
	"AbsoluteRotation",
	"RelativeVelocity",
	"AbsoluteVelocity",
	"RelativeAngularVelocity",
	"AbsoluteAngularVelocity"
}

local booleanIndexes = {
	"ShowSpoofedPosition",
	"Enabled",
	"AdjustCamera"
}

local otherIndexes = {
	"BeforeSpoofing",
	"AfterSpoofing",
	"AfterSpoofingLoop",
	"BeforeSpoofingLoop",
	"StartSpoofingLoop",
	
	"NewEvent"
}

return setmetatable({ }, {
	__index = function(self, index)
		if find(vectorIndexes, index) or find(booleanIndexes, index) or find(otherIndexes, index) then
			return values[index]
		end

		error(("Invalid index '%s'"):format(index), 0)
	end,
	__newindex = function(self, index, value : CFrame)
		if index == "Position" or index == "CFrame" then
			if value then
				local t = typeof(value)
				local position, rotation
				
				if t == "CFrame" then
					position, rotation = value.Position, v3(value.Rotation:ToEulerAnglesXYZ())
				elseif t:sub(1, 6) == "Vector" then
					position = v3(value.X, value.Y, t:sub(7, 7) ~= "2" and value.Z or 0)
				elseif t == "table" then
					position = v3(tonum(value[1] or value.X) or 0, tonum(value[2] or value.Y) or 0, tonum(value[3] or value.Z) or 0)
				else
					return error(("Invalid types (%s) to convert to Vector3s!"):format(t), 0)
				end
				
				values.AbsolutePosition, values.AbsoluteRotation = position, rotation
			elseif index == "Position" then
				values.AbsolutePosition = nil
			else
				values.AbsolutePosition, values.AbsoluteRotation = nil, nil
			end
			
			return
		end
		
		if find(vectorIndexes, index) then
			if value then
				local t = typeof(value)
				if t == "CFrame" or t:sub(1, 6) == "Vector" then
					value = v3(value.X, value.Y, t:sub(7, 7) ~= "2" and value.Z or 0)
				elseif t == "table" then
					value = v3(tonum(value[1] or value.X) or 0, tonum(value[2] or value.Y) or 0, tonum(value[3] or value.Z) or 0)
				else
					return error(("Invalid type (%s) to convert to Vector3!"):format(t), 0)
				end

				values[index] = value
			else
				values[index] = nil
			end

			return
		end

		if find(booleanIndexes, index) then
			values[index] = not not value
			return
		end

		if find(otherIndexes, index) then
			return error(("Index '%s' is not editable!"):format(index), 0)
		end

		error(("Invalid index '%s'"):format(index), 0)
	end
})
