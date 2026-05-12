# Event Library for Roblox Lua

A lightweight, efficient, and robust event system for Roblox Lua, designed for performance, safety, and ease of use. Inspired by modern event patterns, this library provides `Connect`, `Once`, `Wait`, and `Fire` functionality with automatic cleanup and connection management.

---

## 📦 Installation

To use this library in your Roblox project, load it via `loadstring` or `require`:

### Option 1: Load from GitHub (Exploit environments)
```lua
local Event = loadstring(game:HttpGet("https://raw.githubusercontent.com/Null-Cherry/Utilities/refs/heads/main/Event/Main.lua"))()
```

### Option 2: Use as a ModuleScript (Game environments)
1. Create a `ModuleScript` somewhere.
2. Paste the full library code into it.
3. Require it like any other module:

```lua
local Event = require(game.ReplicatedStorage.Event) -- Adjust path as needed
```

---

## 🚀 Usage

### Create a New Event
```lua
local myEvent = Event() -- or Event.new(); Returns a new event instance
```

### Connect a Callback
```lua
local connection = myEvent:Connect(function(player, score)
    print(player.Name .. " scored " .. score .. " points!")
end)
```

### Trigger the Event
```lua
myEvent:Fire(player, 100) -- Fires to all connected listeners
```

### Run Once Only
```lua
myEvent:Once(function(message)
    print("This runs only once: " .. message)
end)
```

### Wait for the Next Fire (Blocking)
```lua
local player, score = myEvent:Wait() -- Suspends execution until next fire
print(player.Name .. " scored " .. score)
```

### Disconnect a Connection
```lua
connection:Disconnect() -- Stops the connection from firing again
```

> ⚠️ Attempting to fire a disconnected event will throw an error.

---

## 🔧 Features

| Feature       | Description |
|---------------|-------------|
| ✅ `Connect`    | Adds a function to be called every time the event is fired. |
| ✅ `Once`       | Adds a function that runs only once, then auto-disconnects. |
| ✅ `Wait`       | Suspends execution until the next fire, then returns all arguments. |
| ✅ `Fire`       | Fires the event to all active connections with provided arguments. |
| ✅ `Disconnect` | Safely removes a connection. Once disconnected, the connection object is frozen. |
| ✅ Automatic Cleanup | Automatically removes disconnected connections on `Fire`. |
| ✅ Thread-Safe  | Uses `task.spawn` to ensure callbacks run asynchronously without blocking the main thread. |

---

## 🛡️ Safety & Performance

- **No memory leaks**: Automatically prunes disconnected connections on every `Fire`.
- **No yield in main thread**: Uses `task.spawn` to avoid blocking the main thread during callback execution.
- **Fast `Wait`**: Does not use task.wait.
- **Error on misuse**: Throws clear errors if you try to `Fire` or `Disconnect` a disconnected connection.

---

## 📌 Example: Player Score System

```lua
local Event = require(game.ReplicatedStorage.Event)
local scoreEvent = Event() -- or Event.new()

scoreEvent:Connect(function(player, points)
    print(player.Name .. " gained " .. points .. " points!")
end)

local player, points = scoreEvent:Wait()
if points >= 100 then
    print(player.Name .. " reached a milestone!")
end

scoreEvent:Fire(player, 50)
```
