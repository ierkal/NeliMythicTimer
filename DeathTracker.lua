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
    
    -- DB Check
    local db = Utils:InitializeDB()
    
    -- We still keep the breakdown table for UI purposes (to see WHO died)
    if not db.deathBreakdown then 
        db.deathBreakdown = {} 
    end

    instance.deathBreakdown = db.deathBreakdown
    
    -- Register the API event for accurate counting
    eventObserver:RegisterEvent("CHALLENGE_MODE_DEATH_COUNT_UPDATED", instance, instance.UpdateDeathCount)
    
    -- Register Combat Log ONLY to record player names for the UI list
    --eventObserver:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED", instance, instance.OnCombatLogEvent)
    
    -- Initial update
    instance:UpdateDeathCount()
    
    return instance
end

function DeathTracker:Reset()
    self.deathCount = 0
    self.timePenalty = 0
    local db = Utils:GetDB()
    db.deathBreakdown = {}
    self.deathBreakdown = db.deathBreakdown
end

function DeathTracker:OnCombatLogEvent()
    local _, subEvent, _, _, _, _, _, _, destName = CombatLogGetCurrentEventInfo()
    
    -- Only use this to track NAMES for the tooltip. Do NOT increment the timer count here.
    if subEvent == "UNIT_DIED" then
        if destName and UnitIsPlayer(destName) then
            local _, classFilename = UnitClass(destName)
            
            if not self.deathBreakdown[destName] then
                self.deathBreakdown[destName] = { count = 0, class = classFilename }
            end
            self.deathBreakdown[destName].count = self.deathBreakdown[destName].count + 1
        end
    end
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

function DeathTracker:GetDeathBreakdown()
    return self.deathBreakdown
end

NS.DeathTracker = DeathTracker