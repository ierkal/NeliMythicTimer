local _, NS = ...

local KeystoneAnnouncer = {}
KeystoneAnnouncer.__index = KeystoneAnnouncer

local Utils = NS.Utils

function KeystoneAnnouncer:New(eventObserver)
    local instance = setmetatable({}, KeystoneAnnouncer)

    -- We only need the config for autoInsertKey check, no internal DB needed for this anymore
    
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

-- Removed OnSystemMessage
-- Removed MarkAsKeystoneOwner
-- Removed OnChallengeModeStart
-- Removed OnChallengeCompleted
-- Removed AnnounceNewKey
-- Removed Reset

NS.KeystoneAnnouncer = KeystoneAnnouncer