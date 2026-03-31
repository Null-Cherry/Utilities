# DataLibrary Documentation

## Installation
Add this library to your Lua environment using the following code:
```lua
local DataLibrary = loadstring(game:HttpGet("https://raw.githubusercontent.com/Null-Cherry/Utilities/refs/heads/main/Data/Main.lua", true))()
```

## Overview
DataLibrary is a cross-server communication library that allows data sharing between users on the same channel, regardless of the Roblox game they're currently in. The library provides a simple event-based system for sending and receiving messages across servers.

## Core Concepts
- **Channels**: Communication groups where messages are broadcasted
- **Server-wide**: Data is shared across all servers running the same channel
- **Event-driven**: Uses listeners to handle incoming messages

## Basic Usage

### Creating a Channel
```lua
local myChannel = DataLibrary.new("MyChannelName")
```
If no channel name is provided, it defaults to "Global":
```lua
local globalChannel = DataLibrary.new() -- Uses "Global" channel
```

### Channel Properties
```lua
myChannel.Enabled = true -- Enable/disable the channel
myChannel.Rate = 5 -- Polling rate in seconds (default: 5)
myChannel.Ping = math.huge -- Current ping/latency (read-only)
myChannel.ChannelName = "MyChannelName" -- Channel identifier
```

## Events

### OnMessage Event
Listens for JSON-encoded messages:
```lua
local connection = myChannel.OnMessage:Connect(function(message, sender)
    -- message: Decoded JSON data
    -- sender: Player instance (if in same game/server), otherwise nil
    print("Received:", message)
    if sender then
        print("From:", sender.Name)
    end
end)
```

### OnMessageRaw Event
Listens for raw (non-JSON) messages:
```lua
local connection = myChannel.OnMessageRaw:Connect(function(rawMessage, sender)
    -- rawMessage: Raw string data
    -- sender: Player instance (if in same game/server), otherwise nil
    print("Raw message:", rawMessage)
end)
```

### Event Methods
```lua
-- Connect a callback function
local connection = event:Connect(function(data)
    -- Handle event
end)

-- Connect a callback that fires only once
event:Once(function(data)
    -- Runs once then automatically disconnects
end)

-- Wait for the next event
local data = event:Wait() -- Returns when next event fires

-- Disconnect an event listener
connection:Disconnect()
```

## Sending Messages

### Send JSON Data
```lua
-- Send to all users in the channel
myChannel:Send({
    type = "chat",
    content = "Hello world!",
    timestamp = os.time()
})

-- Send to specific player (if they're online)
myChannel:Send(dataTable, targetPlayer)
```

### Send Raw Data
```lua
-- Send raw string (won't be JSON decoded)
myChannel:Send("Raw string message", nil, true)

-- Send raw to specific player
myChannel:Send("Raw data", targetPlayer, true)
```

## Important Notes

### Player Detection
- The `sender` parameter in events will be a Player instance **only if** that player is in the same Roblox game and server
- If the sender is in a different server, `sender` will be `nil`
- This allows for cross-server communication while maintaining privacy

### Message Processing
- Messages are automatically JSON encoded/decoded when using `Send()` without the raw flag
- Raw messages bypass JSON processing
- Each message has a unique ID to prevent duplicate processing

### Channel Management
- Channels are cached - creating a channel with the same name returns the existing instance
- Each channel runs an automatic polling loop to check for new messages
- The polling rate is controlled by the `Rate` property (in seconds)

## Example Usage

### Basic Chat System
```lua
local DataLibrary = loadstring(game:HttpGet("https://raw.githubusercontent.com/Null-Cherry/Utilities/refs/heads/main/Data/Main.lua", true))()

local chatChannel = DataLibrary.new("GlobalChat")

-- Listen for messages
chatChannel.OnMessage:Connect(function(message, sender)
    if sender then
        print(sender.Name .. ": " .. message.content)
    else
        print("[Cross-server]: " .. message.content)
    end
end)

-- Send a message
chatChannel:Send({
    content = "Hello from another server!",
    author = game.Players.LocalPlayer.Name
})
```

### Cross-Server Notifications
```lua
local notifyChannel = DataLibrary.new("Notifications")

notifyChannel.OnMessage:Connect(function(notification, sender)
    if notification.type == "achievement" then
        print(notification.player .. " unlocked: " .. notification.achievement)
    end
end)

-- Broadcast achievement unlock
notifyChannel:Send({
    type = "achievement",
    player = game.Players.LocalPlayer.Name,
    achievement = "Master Explorer"
})
```

## Best Practices
1. Use descriptive channel names to avoid conflicts
2. Always check if `sender` is `nil` before using player-specific methods
3. Use JSON encoding for structured data, raw for simple strings
4. Adjust the `Rate` property based on your needs (higher = less frequent polling)
5. Disable channels when not in use to reduce network traffic
