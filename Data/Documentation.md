# Data library documentation

## Installation
Add this library to your Lua environment using the following code:
```lua
local DataLibrary = loadstring(game:HttpGet("https://raw.githubusercontent.com/Null-Cherry/Utilities/refs/heads/main/Data/Main.lua", true))()
```

## Overview
Data library is a cross-server communication library that allows data sharing between users on the same channel, regardless of the Roblox game they're currently in. The library provides a simple event-based system for sending and receiving messages across servers.

## Core Concepts
- **Channels**: Communication groups where messages are broadcasted
- **Server-wide**: Data is shared across all servers running the same channel
- **Event-driven**: Uses listeners to handle incoming messages
- **Player Validation**: Verify player identity across servers

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
myChannel.Enabled = true -- Enable/disable the channel (default: true)
myChannel.Rate = 1 -- Polling rate in seconds (default: 1)
myChannel.Ping = any -- Current ping/latency (read-only)
myChannel.ChannelName = "MyChannelName" -- Channel identifier (overwriting can cause issues, so keep it read-only)
myChannel.RecieveOwn = false -- Whether you will receive your own messages (default: false)
```

## Events

### OnMessage Event
Listens for JSON-encoded messages:
```lua
local connection = myChannel.OnMessage:Connect(function(message, sender, data)
    -- message: Decoded JSON data
    -- sender: Player instance (if in same game/server), otherwise nil
    -- data: Table containing message metadata:
    --   data.Hash: Encoded player identifier (always available)
    --   data.Sender: Same as sender parameter
    --   data.Message: Same as message parameter
    --   data.Timestamp: When message was recieved on server
    --   data.MessageId: Unique message identifier made on server
    --   data.IsRaw: Whether message was sent as raw

    print("Received:", message)
    if sender then
        print("From:", sender.Name)
    end

    print("Message ID:", data.MessageId)
end)
```

### OnMessageRaw Event
Listens for raw (non-JSON) messages:
```lua
local connection = myChannel.OnMessageRaw:Connect(function(rawMessage, sender, data)
    -- rawMessage: Raw string data
    -- sender: Player instance (if in same game/server), otherwise nil
    -- data: Table containing message metadata (same structure as OnMessage)

    print("Raw message:", rawMessage)
    print("Sent at:", data.Timestamp)
end)
```

### Event Methods
```lua
local event = myChannel.OnMessage

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
    content = "Hello world!"
})

-- Send to specific player (if they're on the same server as you), targetPlayer is a Player from "Players" service, e.g. game:GetService("Players")
myChannel:Send(dataTable, targetPlayer)
```

### Send Raw Data
```lua
-- Send raw string (won't be JSON decoded)
-- if 3rd argument is true, message won't be json encoded, so it MUST be a string
myChannel:Send("Raw string message", nil, true)

-- Send raw to specific player
myChannel:Send("Raw data", targetPlayer, true)
```

### Asynchronous Sending
```lua
-- Send asynchronously with success/failure return
local success = myChannel:SendAsync(data, targetPlayer, isRaw)
-- Returns true if sent successfully, false otherwise

-- Unsafe asynchronous send (can fail when rate limited)
local success = myChannel:SendAsyncUnsafe(data, targetPlayer, isRaw)
-- Returns immediately with success/failure status
```

## Player Validation

### Validate Player Identity
```lua
-- Verify if a player ID matches their encoded hash
local isValid = DataLibrary:ValidatePlayer(playerId, hash)
-- Returns true if the player ID matches the hash, false otherwise
-- hash can be either a string or the data table from event handlers

-- Example usage in event handler
myChannel.OnMessage:Connect(function(message, sender, data)
    if sender then
        -- Player is in same server
        print("Local player:", sender.Name)
    else
        -- Cross-server player - validate identity
        local playerId = message.playerId -- Extract from your message format
        if DataLibrary:ValidatePlayer(playerId, data.Hash) then
            print("Validated cross-server player:", playerId)
        end
    end
end)
```

## Important Notes

### Player Detection
- The `sender` parameter in events will be a Player instance **only if** that player is in the same Roblox game and server
- If the sender is in a different server, `sender` will be `nil`
- The `data.Hash` parameter always contains an encoded player identifier, even for cross-server communication
- `DataLibrary:ValidatePlayer(userId, hash)` validates if a user ID matches the encoded hash
- `ValidatePlayer` can be called with `data` table directly, e.g. `DataLibrary:ValidatePlayer(playerId, data)`, not `DataLibrary:ValidatePlayer(playerId, data.Hash)`
- This allows for cross-server communication while maintaining privacy and player identification

## Example Usage

### Basic Chat System with Player Validation
```lua
local DataLibrary = loadstring(game:HttpGet("https://raw.githubusercontent.com/Null-Cherry/Utilities/refs/heads/main/Data/Main.lua", true))()

local chatChannel = DataLibrary.new("GlobalChat")

-- Listen for messages
chatChannel.OnMessage:Connect(function(message, sender, data)
    if sender then
        print(sender.Name .. ": " .. message.content)
    else
        -- Validate cross-server player
        if DataLibrary:ValidatePlayer(message.authorId, data) then
            print("[Cross-server] " .. message.author .. ": " .. message.content)
        else
            print("[Unverified]: " .. message.content)
        end
    end
end)

-- Send a message with author info
chatChannel:Send({
    content = "Hello from another server!",
    author = game.Players.LocalPlayer.Name, -- bad, you should better get player name using services like UserService or Players
    authorId = game.Players.LocalPlayer.UserId
})
```

### Cross-Server Notifications with Async Sending
```lua
local notifyChannel = DataLibrary.new("Notifications")

notifyChannel.OnMessage:Connect(function(notification, sender, data)
    if notification.type == "achievement" then
        if DataLibrary:ValidatePlayer(notification.playerId, data.Hash) then
            print(notification.player .. " unlocked: " .. notification.achievement)
        end
    end
end)

-- Broadcast achievement unlock with guaranteed delivery
local success = notifyChannel:SendAsync({
    type = "achievement",
    player = game.Players.LocalPlayer.Name,
    playerId = game.Players.LocalPlayer.UserId,
    achievement = "Master Explorer"
})

if success then
    print("Achievement broadcast successfully!")
end
```

### Real-time Updates with Faster Polling
```lua
local updateChannel = DataLibrary.new("RealTimeUpdates")
updateChannel.Rate = 0.5 -- Poll every 0.5 seconds for faster updates

updateChannel.OnMessageRaw:Connect(function(rawData, sender, data)
    -- Process raw data for performance-critical applications
    print("Update received:", rawData, "at", data.Timestamp)
end)
```

## Best Practices
1. Use descriptive channel names to avoid conflicts
2. Always check if `sender` is `nil` before using player-specific methods
3. Use JSON encoding for structured data, raw for simple strings
4. Adjust the `Rate` property based on your needs (lower = faster polling)
5. Disable channels when not in use to reduce network traffic
6. Use `SendAsync()` for guaranteed message delivery when needed
7. Validate cross-server players using `ValidatePlayer()` for security
8. Include player IDs in your message format for validation purposes
9. If you gonna include player ID in the message, make sure you use encoding for that and obfuscate your code
