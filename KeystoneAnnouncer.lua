local _, NS = ...

local KeystoneAnnouncer = {}
KeystoneAnnouncer.__index = KeystoneAnnouncer

local Utils = NS.Utils

function KeystoneAnnouncer:New(eventObserver)
    local instance = setmetatable({}, KeystoneAnnouncer)

    instance.db = Utils:InitializeDB()

    -- Initialize saved vars
    if instance.db.isKeystoneOwner == nil then instance.db.isKeystoneOwner = false end
    if instance.db.keyPlacementTime == nil then instance.db.keyPlacementTime = 0 end

    eventObserver:RegisterEvent("CHAT_MSG_SYSTEM", instance, instance.OnSystemMessage)
    eventObserver:RegisterEvent("CHALLENGE_MODE_COMPLETED", instance, instance.OnChallengeCompleted)
    eventObserver:RegisterEvent("CHALLENGE_MODE_START", instance, instance.OnChallengeModeStart)
    
    eventObserver:RegisterEvent("CHALLENGE_MODE_KEYSTONE_RECEPTABLE_OPEN", instance, instance.OnReceptacleOpen)

    return instance
end

function KeystoneAnnouncer:OnReceptacleOpen()
    local config = Utils:GetConfig()
    if config.autoInsertKey == false then
        return 
    end

    C_Timer.After(0.1, function()
        
        local bag, slot = self:FindKeystoneBagAndSlot()
        
        if bag and slot then
            
            C_Container.PickupContainerItem(bag, slot)
            
            if CursorHasItem() then
                C_ChallengeMode.SlotKeystone()
                
            end
        else
        end
    end)
end

function KeystoneAnnouncer:FindKeystoneBagAndSlot()
    for bag = 0, 4 do
        for slot = 1, C_Container.GetContainerNumSlots(bag) do
            local info = C_Container.GetContainerItemInfo(bag, slot)
            if info and info.itemID then
                local itemLink = C_Container.GetContainerItemLink(bag, slot)
                if itemLink and itemLink:lower():match("keystone:") then
                    return bag, slot
                end
            end
        end
    end
    return nil, nil
end

function KeystoneAnnouncer:OnSystemMessage(msg)
    local globalString = CHALLENGE_MODE_KEYSTONE_DEPOSITED_SELF
    if globalString then
        local pattern = globalString:gsub("%%s", ".+"):gsub("%%d", "%d+")
        if msg:match(pattern) then
            self:MarkAsKeystoneOwner()
            return
        end
    end

    local msgLower = msg:lower()
    if (msgLower:find("keystone") or msgLower:find("placed")) and
       (msgLower:find("you") or msgLower:find("your")) then
        self:MarkAsKeystoneOwner()
        return
    end
end

function KeystoneAnnouncer:MarkAsKeystoneOwner()
    self.db.isKeystoneOwner = true
    self.db.keyPlacementTime = GetTime()
end

function KeystoneAnnouncer:OnChallengeModeStart()
    local now = GetTime()
    local timeSincePlacement = now - (self.db.keyPlacementTime or 0)

    if timeSincePlacement > 120 then
        self.db.isKeystoneOwner = false
    else
    end
end

function KeystoneAnnouncer:OnChallengeCompleted()
    if self.db.isKeystoneOwner then
        C_Timer.After(4.0, function()
            self:AnnounceNewKey()
        end)
    end
end

function KeystoneAnnouncer:AnnounceNewKey()
    local bag, slot = self:FindKeystoneBagAndSlot()
    local link = nil
    if bag and slot then
        link = C_Container.GetContainerItemLink(bag, slot)
    end
    
    local channel = IsInGroup(LE_PARTY_CATEGORY_INSTANCE) and "INSTANCE_CHAT" or "PARTY"

    if link then
        SendChatMessage("[NMT] New key: " .. link, channel)
    else
        local level = C_MythicPlus.GetOwnedKeystoneLevel()
        local mapID = C_MythicPlus.GetOwnedKeystoneMapID()

        if level and mapID then
            local name = C_ChallengeMode.GetMapUIInfo(mapID)
            SendChatMessage(string.format("[NMT] New key: %s +%d", name or "Unknown", level), channel)
        elseif level then
            SendChatMessage("[NMT] New key level: +" .. level, channel)
        end
    end

    self:Reset()
end

function KeystoneAnnouncer:Reset()
    self.db.isKeystoneOwner = false
    self.db.keyPlacementTime = 0
end


NS.KeystoneAnnouncer = KeystoneAnnouncer