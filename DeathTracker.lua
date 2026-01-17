local _, NS = ...

local DeathTracker = {}
DeathTracker.__index = DeathTracker

local Utils = NS.Utils
local Constants = NS.Constants

function DeathTracker:New(eventObserver, dataManager)
    local instance = setmetatable({}, DeathTracker)
    
    instance.deathCount = 0
    instance.timePenalty = 0
    instance.dataManager = dataManager
    
    -- Register the API event for accurate counting
    -- No longer listening to COMBAT_LOG_EVENT_UNFILTERED
    eventObserver:RegisterEvent("CHALLENGE_MODE_DEATH_COUNT_UPDATED", instance, instance.UpdateDeathCount)
    
    -- Initial update
    instance:UpdateDeathCount()
    
    return instance
end

function DeathTracker:Reset()
    self.deathCount = 0
    self.timePenalty = 0
end

function DeathTracker:UpdateDeathCount()
    if C_ChallengeMode and C_ChallengeMode.GetDeathCount then
        -- This API is the single source of truth for the COUNT
        self.deathCount = C_ChallengeMode.GetDeathCount() or 0
        self:CalculatePenalty()
    end
end

function DeathTracker:CalculatePenalty()
    local level = C_ChallengeMode.GetActiveKeystoneInfo()
    local penaltyPerDeath = Constants.DEATH_PENALTY_STANDARD

    if level then
        if level < 4 then
            penaltyPerDeath = Constants.DEATH_PENALTY_NONE
        elseif level >= Constants.KEY_LEVEL_HIGH_PENALTY then
            penaltyPerDeath = Constants.DEATH_PENALTY_HIGH
        else
            penaltyPerDeath = Constants.DEATH_PENALTY_STANDARD
        end
    end

    self.timePenalty = self.deathCount * penaltyPerDeath
end

function DeathTracker:GetDeathCount()
    return self.deathCount
end

function DeathTracker:GetTotalTimePenalty()
    return self.timePenalty
end

NS.DeathTracker = DeathTracker