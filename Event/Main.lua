local env = getfenv()
local function g(n)
	return env[n]
end

local global = (g("getgenv") or function() return _G end)()
local n = "EventLib1"

if global[n] then
	return global[n]
end

local pack = table.pack
local error = error
local spawn = task.spawn
local freeze = table.freeze
local smt = setmetatable
local insert = table.insert
local remove = table.remove
local rawset = rawset
local unpack = table.unpack

local quick = Instance.new("BindableEvent") -- only for instant :Wait response
local quickEvent = quick.Event

local connectionBase = {
	Disconnect = function(self)
		if self.Connected then
			rawset(self, "Connected", false)
			freeze(self)
			
			self.Parent:Cleanup()
		end
	end,
	Fire = function(self, ...)
		if not self.Enabled or not self.Connected then return end
		spawn(self.Callback, ...)
	end
}

connectionBase = { __index = connectionBase }

local eventBase = {
	Connect = function(self, func)
		local connection = smt({ Callback = func, Connected = true, Enabled = true, Parent = self }, connectionBase)
		insert(self._Connections, connection)
		
		self:Cleanup()

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
			quick:Fire()
		end)

		repeat quickEvent:Wait() until result
		return unpack(result, 1, result.n)
	end,
	Cleanup = function(self) -- usually not needed to be called manually
		local cons = self._Connections
		local i = 1
		
		while i <= #cons do
			if not cons[i].Connected then
				remove(cons, i)
			else
				i += 1
			end
		end
	end,
	
	Fire = function(self, ...)
		local cons = self._Connections
		for i = 1, #cons do
			cons[i]:Fire(...)
		end
	end,
	DisconnectAll = function(self)
		for i, v in self._Connections do
			v:Disconnect()
		end
		
		self:Cleanup()
	end
}

eventBase = { __index = eventBase }

local new = function()
	return smt({ _Connections = { } }, eventBase)
end

local lib = setmetatable({
	new = new
}, { __call = function(_, ...) return new(...) end })
global[n] = lib

return lib
