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
local defer = task.defer
local delay = task.delay

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
		self.Parent:Cleanup()
		
		if not self.Enabled or not self.Connected or not self.Parent.Enabled then return end
		spawn(self.Callback, ...)
	end
}

connectionBase = { __index = connectionBase, __tostring = function() return "Connection" end, __newindex = function(self, key, value) if key ~= "Enabled" then error() end rawset(self, key, value) end }
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

		self:Cleanup()
		return con
	end,
	Wait = function(self)
		local result
		self:Once(function(...)
			result = pack(...)
			quick:Fire()
		end)

		repeat quickEvent:Wait() until result
		self:Cleanup()
		
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
		self:Cleanup()
		
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

eventBase = { __index = eventBase, __tostring = function() return "Event" end, __newindex = function(self, key, value) if key ~= "Enabled" then error() end rawset(self, key, value) end }
local lib = setmetatable({
	new = function()
		return smt({ _Connections = { }, Enabled = true }, eventBase)
	end,
	RaceEvents = function(self, ...)
		local events = { ... }
		if typeof(events[1]) == "table" then
			events = events[1]
		end
		
		if #events == 0 then return end
		if #events == 1 then return events[1]:Wait() end
		
		local result, winner
		local connections = { }
		
		for i, v in events do
			connections[#connections + 1] = v:Once(function(...)
				for i, v in connections do
					v:Disconnect()
				end
				
				winner = v
				result = pack(...)
				quick:Fire()
			end)
		end
		
		repeat quickEvent:Wait() until result
		
		insert(result, 1, winner)
		return unpack(result, 1, result.n + 1)
	end
}, freeze({ __call = function(self, ...) return self.new(...) end }))
global[n] = lib

local clock, fakeClock, deferClock = lib.new(), lib.new(), lib.new()
local race = lib.RaceEvents
local rs = game:GetService("RunService")
local r1, r2, r3 = rs.RenderStepped, rs.Heartbeat, rs.Stepped
local last = tick()
local fire = clock.Fire
local maxDefer = 10

clock:Connect(function(isDefer, dontFire)
	local current = tick()
	fakeClock:Fire(current - last, isDefer)
	last = current
	
	if dontFire then return end
	
	race(clock, r1, r2, r3)
	fire(clock, false, false)
	delay(0, fire, clock, false, true)
	
	for i = 1, maxDefer do
		defer(fire, deferClock)
		deferClock:Wait()
		
		if i <= 3 or i == 10 or i == maxDefer then
			fire(clock, true, true)
			delay(0, fire, clock, false, true)
		end
	end
end)

rawset(lib, "Clock", fakeClock)
freeze(lib)
fire(clock, false)

return lib
