function ISChat.addServerMessage(messageText, isAlert)
    local player = getPlayer()
    local playerName = player and player:getUsername() or "SERVER"

    local message = {}
    message.getTextWithPrefix = function() return messageText end
    message.getText = function() return messageText end
    message.isServerAlert = function() return isAlert or false end
    message.isShowAuthor = function() return true end
    message.getAuthor = function() return "Server" end

    ISChat.addLineInChat(message, 0)
end

-- === Airdrop & Extraction Commands ===
function extractionNotif()
    sendClientCommand("ZMNotif", "ExtractionNotif", {})
end

function checkCDAirdrop()
    sendClientCommand("ZMNotif", "checkCDAirdrop", {})
end

function resetCDAirdrop()
    sendClientCommand("ZMNotif", "resetCDAirdrop", {})
end

function forceAirdrop()
    sendClientCommand("ZMNotif", "forceAirdrop", {})
end

function forceRandCrate()
    sendClientCommand("ZMNotif", "forceRandCrate", {})
end

function forceRemoveAirdrop()
    sendClientCommand("ZMNotif", "removeAllAirdrop", {})
end

function extractionRegist()
    local username = getPlayer():getUsername()
    sendClientCommand("ZMNotif", "regAirdrop", { username = username })
end

-- === Gladiator Mode ===
function registerGladiator()
    local username = getPlayer():getUsername()
    sendClientCommand("ZMNotif", "regGladiator", { username = username })
end

function unregisterGladiator()
    local username = getPlayer():getUsername()
    sendClientCommand("ZMNotif", "unregGladiator", { username = username })
end

function requestGladiatorList()
    sendClientCommand("ZMNotif", "getGladiatorList", {})
end

function requestGladiator()
    sendClientCommand("ZMNotif", "resetGladiator", {})
end

function openGladiatorMenu()
    showGladiatorUI()
end

-- === Server Events Handler ===
local function OnServerCommand(module, command, tablePlayer, args)
    if module ~= "ZMAlert" then return end

    local player = getPlayer()

    if command == "joined" then
        ISChat.addServerMessage("Someone has entered the extraction zone.", false)

    elseif command == "reqAirdropSuccess" then
        player:Say(tablePlayer.msg1 .. " has successfully sent the request.")

    elseif command == "PlayerRegisteredNotif" then
        ISChat.addServerMessage("[Airdrop] " .. tablePlayer.msg2 .. "/" .. tablePlayer.msg3 .. " players have requested the airdrop launch.", false)

    elseif command == "reqAirdropFailed" then
        player:Say(tablePlayer.msg1 .. ": already sent a request.")
        player:Say(tablePlayer.msg2 .. "/" .. tablePlayer.msg3 .. " players have requested the airdrop launch.")

    elseif command == "airdropLocation" then
        ISChat.addServerMessage("[Air Drop] Airdrop location: X=" .. tablePlayer.x .. " Y=" .. tablePlayer.y .. " Z=" .. tablePlayer.z, false)

    elseif command == "airdropSpawned" then
        ISChat.addServerMessage("[Air Drop] Someone is near the airdrop.", false)

    elseif command == "airdropCD" then
        ISChat.addServerMessage("[Air Drop] Airdrop in cooldown. Wait " .. tablePlayer.cooldownAirdrop .. " minutes.", false)

    elseif command == "airdropNotCD" then
        ISChat.addServerMessage("[Air Drop] No cooldown. You can request airdrop now.", false)

    -- === Gladiator Mode Handling ===
    elseif command == "gladiatorUpdate" then
        ISChat.addServerMessage("[Gladiator] " .. tablePlayer.count .. "/" .. tablePlayer.needed .. " players in queue.", false)
        if GladiatorUIInstance then
            GladiatorUIInstance:updateList(tablePlayer.list or {})
        end

    elseif command == "gladiatorCountdown" then
        ISChat.addServerMessage("[Gladiator] Starting soon", false)

    elseif command == "gladiatorCancelled" then
        ISChat.addServerMessage("[Gladiator] Countdown cancelled. Not enough players.", false)

    elseif command == "gladiatorAlreadyRegistered" then
        player:Say(tablePlayer.name .. " is already registered.")

    elseif command == "gladiatorNotRegistered" then
        player:Say(tablePlayer.name .. " is not registered.")

    elseif command == "gladiatorFull" then
        player:Say("Gladiator queue is full. Maximum players reached.")
        
    elseif command == "gladiatorLocked" then
        getPlayer():Say("[Gladiator] Cannot join now. " .. (tablePlayer.reason or "Match is locked."))

    elseif command == "gladiatorStart" then
        ISChat.addServerMessage("[Gladiator] The battle begins now!", false)

        local localUsername = player:getUsername()
        if tablePlayer and tablePlayer.participants and type(tablePlayer.participants) == "table" then
            for i, name in ipairs(tablePlayer.participants) do
                if name == localUsername then
                    if CharacterManager and CharacterManager.instance and CharacterManager.instance.addFlag then
                        local flag = "gladiator_ready" .. tostring(i)
                        CharacterManager.instance:addFlag(flag)
                        print("[Gladiator] Added flag: " .. flag)
                    else
                        print("[Gladiator] CharacterManager not available!")
                    end
                    break
                end
            end
        end

    elseif command == "gladiatorWinner" then
        ISChat.addServerMessage("[Gladiator] We Have Winner Here!", false)
        if CharacterManager and CharacterManager.instance and CharacterManager.instance.addFlag then
            CharacterManager.instance:addFlag("gladiator_winner")
        else
            print("[Gladiator] CharacterManager not available!")
        end
    end
end

Events.OnServerCommand.Add(OnServerCommand)
