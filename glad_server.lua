-- === Config & State ===
local gladiatorPlayers = {}
local gladiatorQueueCount = 0
local gladiatorMin = 2
local gladiatorMax = 5

local countdownRunning = false
local countdownStartTime = 0
local countdownDuration = 60

local matchLocked = false
local gladiatorMatchRunning = false
local gladiatorMatchStartTime = 0
local activeParticipants = {}

-- Ganti dengan lokasi arena kamu
local gladiatorZone = {
    x1 = 8206, y1 = 11266,
    x2 = 8218, y2 = 11277
}

-- === Utility ===
local function getGladiatorUsernames()
    local list = {}
    for username, _ in pairs(gladiatorPlayers) do
        table.insert(list, username)
    end
    return list
end

local function resetGladiatorQueue()
    gladiatorPlayers = {}
    gladiatorQueueCount = 0
end

local function broadcastToAll(module, command, args)
    local players = getOnlinePlayers()
    for i = 0, players:size() - 1 do
        sendServerCommand(players:get(i), module, command, args)
    end
end

local function sendToPlayerByUsername(username, module, command, args)
    local players = getOnlinePlayers()
    for i = 0, players:size() - 1 do
        local player = players:get(i)
        if player:getUsername() == username then
            sendServerCommand(player, module, command, args)
            return
        end
    end
end

local function isPlayerInGladiatorZone(playerObj)
    local x = math.floor(playerObj:getX())
    local y = math.floor(playerObj:getY())
    return x >= gladiatorZone.x1 and x <= gladiatorZone.x2 and y >= gladiatorZone.y1 and y <= gladiatorZone.y2
end

-- === Reset Match ===
function resetGladiatorMatch()
    print("[Gladiator] Manual match reset.")

    gladiatorPlayers = {}
    gladiatorQueueCount = 0
    countdownRunning = false
    countdownStartTime = 0

    matchLocked = false
    gladiatorMatchRunning = false
    gladiatorMatchStartTime = 0
    activeParticipants = {}

    broadcastToAll("ZMAlert", "gladiatorCancelled", {})
    broadcastToAll("ZMAlert", "gladiatorUpdate", {
        count = 0,
        needed = gladiatorMax,
        list = {}
    })
end

-- === Start Countdown ===
local function startGladiatorCountdown()
    countdownRunning = true
    countdownStartTime = getTimestamp()
    print("[Gladiator] Countdown started.")
end

-- === Client Command Handler ===
Events.OnClientCommand.Add(function(module, command, player, args)
    if module ~= "ZMNotif" then return end

    local username = player:getUsername()

    if command == "regGladiator" then
        if matchLocked or gladiatorMatchRunning then
            sendServerCommand(player, "ZMAlert", "gladiatorLocked", { reason = "Match in progress." })
            return
        end

        if gladiatorPlayers[username] then
            sendServerCommand(player, "ZMAlert", "gladiatorAlreadyRegistered", { name = username })
            return
        end

        if gladiatorQueueCount >= gladiatorMax then
            sendServerCommand(player, "ZMAlert", "gladiatorFull", { name = username })
            return
        end

        gladiatorPlayers[username] = true
        gladiatorQueueCount = gladiatorQueueCount + 1

        broadcastToAll("ZMAlert", "gladiatorUpdate", {
            count = gladiatorQueueCount,
            needed = gladiatorMax,
            list = getGladiatorUsernames()
        })

        if gladiatorQueueCount >= gladiatorMin and not countdownRunning then
            startGladiatorCountdown()
        end

    elseif command == "unregGladiator" then
        if not gladiatorPlayers[username] then
            sendServerCommand(player, "ZMAlert", "gladiatorNotRegistered", { name = username })
            return
        end

        gladiatorPlayers[username] = nil
        gladiatorQueueCount = gladiatorQueueCount - 1

        if gladiatorQueueCount < gladiatorMin and countdownRunning then
            countdownRunning = false
            broadcastToAll("ZMAlert", "gladiatorCancelled", {})
        end

        broadcastToAll("ZMAlert", "gladiatorUpdate", {
            count = gladiatorQueueCount,
            needed = gladiatorMax,
            list = getGladiatorUsernames()
        })

    elseif command == "getGladiatorList" then
        sendServerCommand(player, "ZMAlert", "gladiatorUpdate", {
            count = gladiatorQueueCount,
            needed = gladiatorMax,
            list = getGladiatorUsernames()
        })
    end
end)

-- === Countdown Check ===
Events.EveryOneMinute.Add(function()
    if countdownRunning then
        local elapsed = getTimestamp() - countdownStartTime
        local remaining = countdownDuration - elapsed

        if remaining <= 3 and remaining > 0 then
            broadcastToAll("ZMAlert", "gladiatorCountdown", { timeLeft = math.floor(remaining) })
        end

        if remaining <= 0 then
            countdownRunning = false
            matchLocked = true
            gladiatorMatchRunning = true
            gladiatorMatchStartTime = getTimestamp()

            local participants = getGladiatorUsernames()
            activeParticipants = {}

            for index, name in ipairs(participants) do
                activeParticipants[name] = true
                sendToPlayerByUsername(name, "ZMAlert", "gladiatorStart", {
                    participants = participants,
                    myIndex = index
                })
            end

            resetGladiatorQueue()

            broadcastToAll("ZMAlert", "gladiatorUpdate", {
                count = 0,
                needed = gladiatorMax,
                list = {}
            })
        end
    end
end)

-- === Winner Check ===
Events.OnTick.Add(function()
    if not gladiatorMatchRunning or gladiatorMatchStartTime == 0 then return end

    local timeSinceStart = getTimestamp() - gladiatorMatchStartTime
    if timeSinceStart < 120 then return end -- tunggu 5 menit

    local aliveInZone = {}
    local players = getOnlinePlayers()

    for i = 0, players:size() - 1 do
        local playerObj = players:get(i)
        local username = playerObj:getUsername()

        if activeParticipants[username]
            and not playerObj:isDead()
            and isPlayerInGladiatorZone(playerObj) then

            table.insert(aliveInZone, username)
        end
    end

    if #aliveInZone == 1 then
        local winner = aliveInZone[1]
        print("[Gladiator] Winner: " .. winner)

        sendToPlayerByUsername(winner, "ZMAlert", "gladiatorWinner", {})

        -- FULL RESET
        matchLocked = false
        gladiatorMatchRunning = false
        gladiatorMatchStartTime = 0
        activeParticipants = {}
    end
end)
