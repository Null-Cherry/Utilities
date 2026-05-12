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
			quick:Fire()
		end)

		repeat quickEvent:Wait() until result
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

local new = function()
	return smt({ _Connections = { } }, eventBase)
end

return setmetatable({
	new = new
}, { __call = function(_, ...) return new(...) end })
