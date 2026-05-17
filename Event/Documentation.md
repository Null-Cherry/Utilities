# 📦 Event: High-Performance Event System for Roblox Lua

A lightweight, efficient, and robust event system designed for **performance**, **memory safety**, and **ease of use** in Roblox Lua. Built with automatic connection cleanup, async callback execution via `task.spawn`, and a blazing-fast `Wait()` implementation.

> ✅ **No memory leaks** | ✅ **No main-thread blocking** | ✅ **Thread-safe**

---

## 🚀 Installation

### Option 1: Load from GitHub (Exploit / External Environments)
```lua
local Event = loadstring(game:HttpGet("https://raw.githubusercontent.com/Null-Cherry/Utilities/refs/heads/main/Event/Main.lua"))()
```

### Option 2: Use as a ModuleScript (Game Environments)
1. Create a **ModuleScript** in `ReplicatedStorage` (or any accessible location).
2. Paste the full library code into it.
3. Require it in your scripts:
```lua
local Event = require(game.ReplicatedStorage.Event) -- Adjust path as needed
```

> 💡 **Tip**: The library is **self-caching** — calling `Event()` multiple times returns the same instance.

---

## 🚀 Usage

### Race Events (Roblox Events are supported)
```lua
Event:RaceEvents({ Event1, game.Changed, Event2, ... })
```
RaceEvents returns "winner" event and what event did return

### Create a New Event
```lua
local myEvent = Event()        -- shorthand
-- or
local myEvent = Event.new()    -- explicit
```

### Connect a Callback (Persistent)
```lua
local connection = myEvent:Connect(function(player, score)
    print(player.Name .. " scored " .. score .. " points!")
end)
```

### Run Once Only (Auto-Disconnect)
```lua
myEvent:Once(function(message)
    print("This runs only once: " .. message)
end)
```

### Wait for Next Fire (Blocking Yield)
```lua
local player, score = myEvent:Wait() -- Suspends until next Fire()
print(player.Name .. " scored " .. score)
```
> ⚡ **Optimized**: Uses a pre-created `BindableEvent` for **instant** `Wait()` responses — no `task.wait()` or polling.

### Fire the Event
```lua
myEvent:Fire(player, 100) -- Fires to ALL active connections
```

### Disconnect a Connection
```lua
connection:Disconnect() -- Safely removes connection and freezes object
```
> 🛑 Attempting to `Fire()` or `Disconnect()` a **disconnected** connection will **silently do nothing** (no error).

### Disconnect All Connections
```lua
myEvent:DisconnectAll() -- Removes and disconnects all active connections
```

---

## 🔧 Features Summary

| Feature | Description |
|--------|-------------|
| `Event` instance | - |
| ✅ `:Connect(func) -> Connection` | Adds a callback that runs every time the event is fired. |
| ✅ `:Once(func) -> Connection` | Adds a callback that runs **once**, then auto-disconnects. |
| ✅ `:Wait() -> ...` | **Yields** until the next `Fire()`, then returns all arguments as individual values. |
| ✅ `:Fire(...) -> void` | Fires the event to **all active connections** using `task.spawn` (non-blocking). |
| ✅ `:DisconnectAll() -> void` | Removes and disconnects all connections at once. |
| `Connection` instance | - |
| ✅ `:Disconnect() -> void` | Safely removes a connection. Connection object is **frozen** after disconnect. |
| ✅ `:Fire(...) -> void` | Fires connection **individually**, callback wont be called if `.Connected = false` or `.Enabled = false` |
| ✅ `.Enabled` | Safe way to disable/enable Connection's callback |
| ✅ `.Callback` | A function that being called on `:Fire(...)` |
| ✅ `.Connected` | (Readonly) Shows if connection is still connected |
| ✅ `.Parent` | (Readonly) Returns Event instance |
| `Other` | - |
| ✅ Thread-Safe | All callbacks run via `task.spawn` — **never blocks** the main thread. |
| ✅ Immutable Connections | Disconnected connections are `table.freeze()`d to prevent reuse. |

---

## 🛡️ Safety & Performance Highlights

- **No Memory Leaks**: Disconnected connections are **immediately pruned** on `Fire()` — no stale references.
- **No Main Thread Blocking**: All callbacks are **asynchronously spawned** using `task.spawn`.
- **Frozen Objects**: Disconnected connections are frozen — **prevents accidental reuse**.
- **Error-Free Misuse**: Attempting to fire or disconnect a disconnected connection **does nothing** — safe by design.
- **Lightweight**: No external dependencies. Pure Lua + Roblox API.

---

## 📌 Example: Player Score System

```lua
local Event = loadstring(game:HttpGet("https://raw.githubusercontent.com/Null-Cherry/Utilities/refs/heads/main/Event/Main.lua"))()
local scoreEvent = Event()

-- Listen for all scores
scoreEvent:Connect(function(player, points)
    print(player.Name .. " gained " .. points .. " points!")
end)

-- Run once on milestone
scoreEvent:Once(function(player, points)
    if points >= 100 then
        print(player.Name .. " reached a milestone! 🎉")
    end
end)

-- Wait for first player to score 50+
local player, points = scoreEvent:Wait()
if points >= 50 then
    print(player.Name .. " hit the 50-point threshold!")
end

-- Fire an event
scoreEvent:Fire(player, 75) -- Triggers both Connect and Once (if not already fired)
```
