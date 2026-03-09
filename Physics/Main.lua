local pack = table.pack
local error = error
local pcall = pcall
local typeof = typeof
local tonum = tonumber
local spawn = task.spawn
local freeze = table.freeze
local smt = setmetatable
local clear = table.clear
local insert = table.insert
local remove = table.remove
local rawset = rawset
local find = table.find
local wait = task.wait
local unpack = table.unpack
local v3 = vector.create
local deg = math.deg
local ncf = CFrame.new
local xyz = CFrame.fromEulerAnglesXYZ
local rad = math.rad
local look = CFrame.lookAt
local workspace = workspace

local zero = v3(0, 0, 0)

local ino = getfenv().isnetworkowner
local ghp = getfenv().gethiddenproperty

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
				spawn(v.Fire, v, ...)
			else
				remove(cons, i)
			end
		end
	end
}

eventBase = { __index = eventBase }
local event = smt({
	new = function()
		return smt({ _Connections = { } }, eventBase)
	end
}, { __call = function(self, ...) return self.new(...) end })

local beforeSpoofing, afterSpoofing, afterSpoofCycle = event.new(), event.new(), event.new()

local spoofQueue = { }

local spooferBase = {
	Set = function(self)
		if not self.Enabled or not self.Object then return end
		
		local props = self.Properties
		local object = self.Object
		local originalValues = self.OriginalValues
		
		originalValues.CFrame = object.CFrame
		originalValues.Velocity = object.AssemblyLinearVelocity
		originalValues.RotVelocity = object.AssemblyAngularVelocity
		
		local originalPosition = props.Position or object.Position
		local originalRotation = props.Rotation or object.Rotation
		
		local originalCFrame = ncf(originalPosition) * xyz(originalRotation.X, originalRotation.Y, originalRotation.Z)

		local offsetPosition = props.OffsetPosition or zero
		local offsetRotation = props.OffsetRotation or zero

		local rot = originalRotation + v3(offsetRotation.Y, offsetRotation.X, offsetRotation.Z)
		
		object.CFrame = (ncf(originalPosition) * xyz(rad(rot.X), rad(rot.Y), rad(rot.Z))) + (originalCFrame.XVector * offsetPosition.X) + (originalCFrame.YVector * offsetPosition.Y) + (originalCFrame.ZVector * offsetPosition.Z) + (props.WorldOffsetPosition or zero)
		object.AssemblyLinearVelocity = (props.AssemblyLinearVelocity or object.AssemblyLinearVelocity) + (props.OffsetVelocity or zero)
		object.AssemblyAngularVelocity = (props.RotVelocity or object.AssemblyAngularVelocity) + (props.OffsetRotVelocity or zero)
	end,
	Restore = function(self)
		if not self.Object then return end
		
		local object = self.Object
		local originalValues = self.OriginalValues
		
		for i, v in originalValues do
			object[i == "RotVelocity" and "AssemblyAngularVelocity" or i] = v
		end
		
		clear(originalValues)
	end,
	
	Unlink = function(self)
		local found = find(spoofQueue, self)
		if found then
			remove(spoofQueue, found)
		end
	end,
}

spooferBase = {
	__index = spooferBase,
	__newindex = function(self, index, value)
		if index == "Enabled" then
			rawset(self, index, not not value)
		elseif index == "Object" then
			rawset(self, index, typeof(value) == "Instance" and value or nil)
		elseif index == "CFrame" then
			if typeof(value) == "Vector3" then
				self.Properties.Position = value
				self.Properties.Rotation = nil
			elseif typeof(value) == "CFrame" then
				local x, y, z = value:ToEulerAnglesXYZ()
				self.Properties.Position = value.Position
				self.Properties.Rotation = v3(deg(x), deg(y), deg(z))
			else
				self.Properties.Position = nil
				self.Properties.Rotation = nil
			end
		elseif index == "OffsetCFrame" then
			if typeof(value) == "Vector3" then
				self.Properties.OffsetPosition = value
				self.Properties.OffsetRotation = nil
			elseif typeof(value) == "CFrame" then
				local x, y, z = value:ToEulerAnglesXYZ()
				self.Properties.OffsetPosition = value.Position
				self.Properties.OffsetRotation = v3(deg(x), deg(y), deg(z))
			else
				self.Properties.OffsetPosition = nil
				self.Properties.OffsetRotation = nil
			end
		else
			self.Properties[index] = value
		end
	end,
}

local newSpoofer = function(object)
	local self = smt({ Properties = { }, OriginalValues = { }, Enabled = true, Object = object })
	insert(spoofQueue, self)
	
	return self
end

local rs = game:GetService("RunService")
local hb = rs.Heartbeat
local rns = rs.RenderStepped
local s = rs.Stepped

local plr = game:GetService("Players").LocalPlayer
local playerSpoofer = newSpoofer(plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") or nil)
playerSpoofer.Enabled = false

local lib

task.spawn(function()
	while task.wait() do
		playerSpoofer.Object = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") or nil
	end
end)

task.spawn(function()
	while hb:Wait() do
		if not lib.Spoofer.Enabled then continue end
		
		beforeSpoofing:Fire()
		for i, v in spoofQueue do
			v:Set()
		end

		afterSpoofing:Fire()
		rns:Wait()
		for i, v in spoofQueue do
			v:Restore()
		end

		s:Wait()
		for i, v in spoofQueue do
			v:Restore()
		end

		afterSpoofCycle:Fire()
	end
end)

lib = freeze({
	Spoofer = {
		Spoof = function(self, object) return newSpoofer(object) end,
		Enabled = true,
		Objects = spoofQueue,

		SpoofPlayer = function(self)
			playerSpoofer.Enabled = true
			return playerSpoofer
		end,
		
		BeforeSpoofing = beforeSpoofing,
		AfterSpoofing = afterSpoofing,
		AfterSpoofCycle = afterSpoofCycle
	},

	Predict = function(self, part)
		if part:IsA("Model") then
			part = part.PrimaryPart or part:FindFirstChild("HumanoidRootPart") or part:FindFirstChildWhichIsA("BasePart")
		end

		if not part or not part:IsA("BasePart") or not part:IsDescendantOf(workspace) then
			return plr.Character and plr.Character:GetPivot() or ncf()
		end

		local pos = part.Position

		if part.Anchored then
			return part.CFrame
		end

		return part.CFrame * ncf(part.AssemblyLinearVelocity * (plr:GetNetworkPing() / 2))
	end,

	IsNetworkOwner = function(self, part)
		if ino then
			return ino(part)
		end

		local currentNetworkOwner = ghp and ghp(part, "NetworkOwnerV3")
		return (typeof(currentNetworkOwner) == "number" and currentNetworkOwner > 2 or part.ReceiveAge == 0) and not part.Anchored
	end
})

return lib
