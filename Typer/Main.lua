local keyboardMap = {
	"1234567890-=",
	"qwertyuiop[]\\",
	"asdfghjkl;'\n",
	"zxcvbnm,./",
	" "
}

local uppercaseKeyboardMap = {
	"!@#$%^&*()_+",
	"QWERTYUIOP{}|",
	"ASDFGHJKL:\"",
	"ZXCVBNM<>?",
	" "
}

local v2 = vector and vector.create or Vector2.new
local wait, spawn = task.wait, task.spawn
local codes = utf8.codes
local char = utf8.char
local remove, insert, find, concat = table.remove, table.insert, table.find, table.concat
local random, min, max = math.random, math.min, math.max

local default = v2(0, 2)

local decodedMap = { }
local reverseMap = { }

for row = 1, #keyboardMap do
	local keyboardRow = keyboardMap[row]
	for col = 1, #keyboardRow do
		local v = v2(row - 1, col - 1)
		local s = keyboardRow:sub(col, col)

		decodedMap[v] = s
		reverseMap[s] = v
	end
end

local decodedUppercaseMap = { }
local reverseUppercaseMap = { }

for row = 1, #uppercaseKeyboardMap do
	local keyboardRow = uppercaseKeyboardMap[row]
	for col = 1, #keyboardRow do
		local v = v2(row - 1, col - 1)
		local s = keyboardRow:sub(col, col)

		decodedUppercaseMap[v] = s
		reverseUppercaseMap[s] = v
	end
end

local function symbols(message)
	local symbols = { }
	for i, v in codes(message) do
		insert(symbols, char(v))
	end

	return symbols
end

local function getPosition(symbol)
	return reverseMap[symbol] or reverseUppercaseMap[symbol] or default
end

local function getClosestRandom(position)
	position = v2(position.Y, position.X) -- yeah, I fucked that up somehow and lazy to fix
	
	local dirs = { -- left, right, up, down
		v2(-1, 0),
		v2(1, 0),
		v2(0, 1),
		v2(0, -1),
	}

	while #dirs > 0 do
		local newPos = position + remove(dirs, random(1, #dirs))
		if decodedMap[newPos] or decodedUppercaseMap[newPos] then
			return newPos
		end
	end

	return position
end

local function getKeyAt(position, isUppercase)
	return (isUppercase and decodedUppercaseMap or decodedMap)[position] or "\0"
end

local defaultOptions = {
	Speed = 100,
	Accuracy = 95, -- 95 and more is the best. Less Accuracy = more chance of skipping or hitting a closer letter. Less Accuracy = less chance of detecting the typos. When typo detected, using speed variable, remove letters, until removed typo, then continue typing from that point
	AccuracyMinimum = 100, -- just a second value for Accuracy, better dont change it, or else typos gonna look weird
	SlowdownFactor = 0.75, -- 0 = same speed as bot types, bigger number = slower typing for each symbol
	AllowIncorrect = true, -- allow hitting closer keys on keyboard, e.g. when typo, instead of "a" it will type or "q", or "s" or "z"
}

local function getKeyboardDistance(a, b)
	return (getPosition(a) - getPosition(b)).Magnitude
end

local resetSymbols = { " ", ",", ".", "!", "?", ":", ";", "-", "_", "=", "+", "[", "]", "{", "}", "\\", "|", "/", "<", ">", "~", "`", "#", "@", "$", "%", "^", "&", "*", "(", "'", '"', "\n", "#", "\t", "\r" }
local slowFactor2 = 12.5

return function(message, options, onType, finished)
	onType = onType or function() end
	finished = finished or function() end
	options = options and setmetatable(options, { __index = defaultOptions }) or defaultOptions

	local symbolList = symbols(message)
	local index = 1
	local typed = ""
	local lastSymbol = "\0"
	local typoPosition = false
	local accuracy = (options.Accuracy + options.AccuracyMinimum) / (100 + options.AccuracyMinimum)
	local speed = max((100 - options.Speed) / 2000, 0)
	local symbolsTyped = -1
	local slowFactor = options.SlowdownFactor
	local allowIncorrect = options.AllowIncorrect

	while message ~= "" do
		local symbol = symbolList[index]
		if not symbol then
			index -= 1
			continue
		end

		local pos = getPosition(symbol)
		local isUppercase = reverseUppercaseMap[symbol] ~= nil

		if typoPosition and (index == #symbolList or random() < accuracy) then
			wait(min(max(speed / 5, symbolsTyped * slowFactor), slowFactor2 * slowFactor) * speed * (3.5 * (random() + 1)))

			for i = typoPosition + 1, index do
				local newTyped = symbols(typed)
				typed = concat(newTyped, "", 1, #newTyped - 1)
				index -= 1
				symbolsTyped -= 0.5
				lastSymbol = "\0"

				spawn(onType, typed, "")
				wait(min(max(speed / 5, symbolsTyped * slowFactor), slowFactor2 * slowFactor) * speed * (2 * (random() + 1)))

				if index <= 1 then
					index = 1
					break
				end
			end

			typoPosition = false
			continue
		end

		local isTypo = random() > accuracy
		local randomLetter = allowIncorrect and getClosestRandom(pos) or pos

		if isTypo and random() < 0.2 then
			if index + 1 <= #symbolList then
				randomLetter = getPosition(symbolList[index + 1])
			elseif index > 1 then
				randomLetter = getPosition(symbolList[index - 1])
			end
		end

		if isTypo and randomLetter ~= pos then
			local key = getKeyAt(randomLetter, isUppercase)
			wait(getKeyboardDistance(key, lastSymbol) * speed)

			typed ..= key
			spawn(onType, typed, key)

			if find(resetSymbols, key) then
				symbolsTyped *= random() * random()
			end

			lastSymbol = key
			typoPosition = typoPosition or index
			index += 1
			symbolsTyped += 1
		else
			wait(getKeyboardDistance(symbol, lastSymbol) * speed)

			typed ..= symbol
			spawn(onType, typed, symbol)
			lastSymbol = symbol
			index += 1
			symbolsTyped += 1

			if #symbol > 1 then
				wait(((#symbol) ^ 2) * speed)
			end
		end

		wait(min(max(speed / 5, symbolsTyped * slowFactor), slowFactor2 * slowFactor) * speed)

		if not typoPosition and index > #symbolList then
			break
		end
	end

	if message == "" then
		spawn(onType, "", "")
		wait(speed)
	end

	spawn(finished, message)
end
