local utils = {
	Data = "Util",
	ESPLib = "Util",
	Event = "Util",
	Physics = "Util",
	Typer = "Util",
	Desync = "Url",
	UI = "Url"	
}

local utilGlobalKeys = {
	Data = "DataLibrary",
	ESPLib = "FESPLib",
	Event = "EventLib1",
	Physics = "PhyLib",
	Desync = "DesyncLib",
	UI = "FireLibrary"
}

local global = getgenv and getgenv() or _G
local globalKey = "QKUtil"

if global[globalKey] then
	return global[globalKey]
end

local coreFolder = "QUtil/"
local ext = ".lua"
local utilFile = coreFolder .. "Utility" .. ext
local utilsFolder = coreFolder .. "Utilities/"

local user = "https://raw.githubusercontent.com/Null-Cherry/"
local subUrls = {
	Util = user .. "Utilities/refs/heads/main/"
}

local ver = "1.0"
local wf, rf, mf, IF, df = writefile or write_file, readfile or read_file, makefolder or make_folder, isfile or is_file, deletefolder or delfolder or removefolder or delete_folder or del_folder or remove_folder
local loadstring, tonumber, game, error, warn, freeze, spawn = loadstring or load, tonumber, game, error, warn, table.freeze, task.spawn

if wf and rf and mf and IF then
	local serverVer = game:HttpGet(subUrls.Util .. "Utility/Version.txt"):gsub("\n\r\f\t\s\0 ", "")
	if tonumber(serverVer) and ver ~= serverVer then
		local self = game:HttpGet(subUrls.Util .. "Utility/Main")
		local loadTest = loadstring(self)
		
		if loadTest then
			df(coreFolder:sub(1, -2))
			mf(coreFolder:sub(1, -2))
			mf(utilsFolder:sub(1, -2))
			wf(utilFile, self)
			
			return loadTest()
		else
			error("Failed to update Utility to version " .. serverVer, 0)
		end
	elseif not tonumber(serverVer) then
		warn("Failed to get version for Utility: " .. serverVer)
		warn("The script using that utility might work incorrectly or not at all")
	end
	
	mf(coreFolder:sub(1, -2))
	mf(utilsFolder:sub(1, -2))
end

if global[globalKey] then
	return global[globalKey]
end

local urls = {
	UI = user .. "Fire-Library/refs/heads/main/QuickLoader" .. ext,
	Desync = subUrls.Util .. "Physics/Desync" .. ext
}

local shortcuts = {
	ESP = "ESPLib"
}

local function tableSearch(key, table)
	for k, v in table do
		if k:lower() == key:lower() then
			return k, v
		end
	end
end

local function getModuleInfo(name)
	if name:sub(1, 4):lower() == "http" then
		return name, "Download"
	end
	
	local _, full = tableSearch(name, shortcuts)
	full = full or name
	if not full then error("Module not found: " .. name, 0) end
	
	local _, moduleType = tableSearch(full, utils)
	if not moduleType then error("Module not found: " .. full, 0) end
	
	return full, moduleType
end

local ecs = game:GetService("EncodingService")
local md5 = Enum.HashAlgorithm.Md5

local _hx = function(a) return ("%02x"):format(a:byte()) end
local function hash(str)
	return ecs:ComputeStringHash(str, md5):gsub(".", _hx)
end

local cache = { }
local downloadModule; function downloadModule(name, forceDownload)
	local moduleName, moduleType = getModuleInfo(name)
	local filePath = hash(utilsFolder .. moduleName) .. ext
	
	if not forceDownload then
		local cached = cache[moduleName]
		if cached then
			return cached
		end
		
		if IF and IF(filePath) and not forceDownload then
			return loadstring(rf(filePath))
		end
		
		local gkey = utilGlobalKeys[moduleName]
		if gkey then
			local found = global[gkey]
			if found then
				spawn(downloadModule, true)
				return found
			end
		end
	end
	
	local moduleContents = game:HttpGet(moduleType == "Download" and moduleName or moduleType == "Url" and urls[moduleName] or subUrls[moduleType] .. moduleName .. "/Main" .. ext)
	local loadTest = loadstring(moduleContents)

	if loadTest then
		wf(filePath, moduleContents)
		return loadTest
	else
		error("Module failed to load: " .. moduleContents, 0)
	end
end

local modules = { }
for module in utils do
	modules[#modules + 1] = module
end

freeze(modules)

local defer = task.defer
spawn(function()
	for i, module in modules do
		defer(downloadModule, module, true)
	end
end)

local util = setmetatable({
	Load = function(self, name)if not self.Modules then error("Call via ':' next time!", 0) end return downloadModule(name)() end,
	LoadModule = function(self, ...) return self:Load(...) end,
	Modules = modules,
	Utililites = modules,
	Utils = modules
}, freeze({
	__index = function(self, name) return downloadModule(name) end,
	__newindex = error,
	__metatable = getmetatable(game)
}))

global[globalKey] = util

task.wait()
return util
