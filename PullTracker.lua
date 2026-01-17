-- NeliMythicTimer/PullTracker.lua
local _, NS = ...

local PullTracker = {}
PullTracker.__index = PullTracker

local Constants = NS.Constants
local Utils = NS.Utils
local PULL_EVENTS = Constants.PULL_EVENTS

function PullTracker:New(eventObserver, dataManager)
    local instance = setmetatable({}, PullTracker)
    instance.dataManager = dataManager
    instance.activePullGUIDs = {} -- GUID = npcID
    instance.inBossEncounter = false

    eventObserver:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED", instance, instance.OnCombatLogEvent)
    eventObserver:RegisterEvent("PLAYER_REGEN_ENABLED", instance, instance.OnLeaveCombat)
    eventObserver:RegisterEvent("ENCOUNTER_START", instance, instance.OnEncounterStart)
    eventObserver:RegisterEvent("ENCOUNTER_END", instance, instance.OnEncounterEnd)

    return instance
end

function PullTracker:OnEncounterStart()
    self.inBossEncounter = true
end

function PullTracker:OnEncounterEnd()
    self.inBossEncounter = false
    wipe(self.activePullGUIDs)
end

function PullTracker:IsInBossEncounter()
    return self.inBossEncounter
end

function PullTracker:GetNPCID(guid)
    return Utils:GetNPCIDFromGUID(guid)
end

function PullTracker:OnLeaveCombat()
    wipe(self.activePullGUIDs)
end

function PullTracker:OnCombatLogEvent()
    local _, subEvent, _, sourceGUID, _, sourceFlags, _, destGUID, _, destFlags = CombatLogGetCurrentEventInfo()

    -- Remove mob from pull list when it dies
    if subEvent == "UNIT_DIED" then
        if self.activePullGUIDs[destGUID] then
            self.activePullGUIDs[destGUID] = nil
        end
        return
    end

    -- Track pulls from party <-> mob interactions
    if PULL_EVENTS[subEvent] then
        -- Party attacking mob
        if bit.band(sourceFlags, COMBATLOG_OBJECT_AFFILIATION_MINE) ~= 0 or bit.band(sourceFlags, COMBATLOG_OBJECT_AFFILIATION_PARTY) ~= 0 then
            self:AddUnitToPull(destGUID)
        end

        -- Mob attacking party
        if bit.band(destFlags, COMBATLOG_OBJECT_AFFILIATION_MINE) ~= 0 or bit.band(destFlags, COMBATLOG_OBJECT_AFFILIATION_PARTY) ~= 0 then
            self:AddUnitToPull(sourceGUID)
        end
    end
end

function PullTracker:AddUnitToPull(guid)
    if not guid or guid:find("Player") then
        return
    end

    if not self.activePullGUIDs[guid] then
        local npcID = self:GetNPCID(guid)
        if npcID then
            local value = NS.MobData:GetMobValue(npcID)
            if value and value > 0 then
                self.activePullGUIDs[guid] = npcID
            end
        end
    end
end

function PullTracker:GetCurrentPullCount()
    if not UnitAffectingCombat("player") then
        return 0
    end

    local pullCountSum = 0
    for guid, npcID in pairs(self.activePullGUIDs) do
        pullCountSum = pullCountSum + (NS.MobData:GetMobValue(npcID) or 0)
    end

    return pullCountSum
end

NS.PullTracker = PullTracker
