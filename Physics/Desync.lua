local env = getfenv()
local function g(n)
	return env[n]
end

local request = g("request")
local global = (g("getgenv") or function() return _G end)()

if global.DesyncLib then
	return global.DesyncLib
end

local function gHTTPG(url)
	return game:HttpGet(url)
end

local function httpGet(url)
	if request then
		local result = request({ Url = url, Method = "GET", Headers = { } })
		local success = result.Success or tostring(result.StatusCode):sub(1, 1) == "2"
		return success and result.Body or "", success
	else
		local s, e = pcall(gHTTPG, url)
		return s and e or "", s
	end
end

local function urlLoad(url)
	local ret
	while true do
		ret = nil

		local r, s = httpGet(url)
		if s then
			ret = loadstring(r)

			if ret then
				ret = ret()

				if ret then
					break
				end
			end
		end
	end

	return ret
end

local physics = urlLoad("https://raw.githubusercontent.com/Null-Cherry/Utilities/refs/heads/main/Physics/Main.lua")
local spoofer = physics.Spoofer
local clock = urlLoad("https://raw.githubusercontent.com/Null-Cherry/Utilities/refs/heads/main/Event/Main.lua").Clock
local plrSpoofer = spoofer:SpoofPlayer()
plrSpoofer.Enabled = false

local rs = game:GetService("RunService")

local library = {
	Enabled = false,
	Delay = 1,
	RandomLagTime = 0,
	Show = false,
	DontResetValues = false,
	ClearHistoryOnDeath = true,
	
	OverrideVelocity = nil,
	OverrideRotVelocity = nil,
	
	Physics = physics,
	Spoofer = spoofer,
	PlayerSpoofer = plrSpoofer,
}

local history = { }

local insert, remove, clear = table.insert, table.remove, table.clear
local tick = tick
local wait = task.wait
local random = math.random

local plr = game:GetService("Players").LocalPlayer
local fakeHrp = Instance.new("Part")
fakeHrp.Transparency = 0.5
fakeHrp.CanCollide = false
fakeHrp.CanTouch = false
fakeHrp.CanQuery = false
fakeHrp.Anchored = true
fakeHrp.Name = "Desync display"

local history = { }
local function makeRecord(hrp)
	insert(history, { hrp.CFrame, hrp.AssemblyLinearVelocity, hrp.AssemblyAngularVelocity, tick() })
end

local resetState = false
task.spawn(function()
	while true do
		local random = random()
		if random * library.RandomLagTime > 0 then
			local start = tick()
			while tick() - start < random * library.RandomLagTime do
				wait()
			end
		end
		
		while true do
			local _, skip = clock:Wait()
			if skip then break end
			
			if #history == 0 or library.Delay <= 0 then
				if not library.Enabled and not resetState then
					resetState = true
					fakeHrp.Parent = nil

					if not library.DontResetValues then
						plrSpoofer.CFrame, plrSpoofer.Velocity, plrSpoofer.RotVelocity = nil, nil, nil
					end
				end

				break
			end

			local record = history[1]
			if record[4] + library.Delay < tick() then
				remove(history, 1)
			end

			plrSpoofer.CFrame = record[1]
			plrSpoofer.Velocity = library.OverrideVelocity or record[2]
			plrSpoofer.RotVelocity = library.OverrideRotVelocity or record[3]
			fakeHrp.CFrame = record[1]
			fakeHrp.Parent = library.Show and (workspace:FindFirstChildOfClass("Terrain") or workspace) or nil
		end
	end
end)

local can = pcall(function() plr.DevCameraOcclusionMode = plr.DevCameraOcclusionMode end)
local original = can and plr.DevCameraOcclusionMode
local invis = Enum.DevCameraOcclusionMode.Invisicam

rs.RenderStepped:Connect(function()
	plrSpoofer.Enabled = library.Enabled
	if library.Enabled and library.Delay > 0 then
		local hrp = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
		if hrp then
			if can then
				plr.DevCameraOcclusionMode = invis
			end
			
			resetState = false
			fakeHrp.Size = hrp.Size
			makeRecord(hrp)
		else
			if can then
				plr.DevCameraOcclusionMode = original
			end
			
			if library.ClearHistoryOnDeath then
				clear(history)
			end
		end
	else
		if can then
			plr.DevCameraOcclusionMode = original
		end
		
		clear(history)
	end
end)

global.DesyncLib = library
return library
