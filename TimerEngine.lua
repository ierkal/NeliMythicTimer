local _, NS = ...

local TimerEngine = {}
TimerEngine.__index = TimerEngine

local Constants = NS.Constants
local TIMER_ID = Constants.TIMER_ID 

function TimerEngine:New(dataManager, deathTracker, eventObserver)
    local instance = setmetatable({}, TimerEngine)
    instance.dataManager = dataManager
    instance.deathTracker = deathTracker
    instance.eventObserver = eventObserver
    
    if eventObserver then
        eventObserver:RegisterEvent("CHALLENGE_MODE_COMPLETED", instance, instance.OnChallengeModeComplete)
    end

    instance:Reset()
    return instance
end

function TimerEngine:Reset()
    self.totalDuration = 0
    self.running = false
    self.frozenElapsed = nil 
    self.lastKnownElapsed = 0 
end

function TimerEngine:StartTimer(duration)
    self.totalDuration = duration
    self.running = true
    self.frozenElapsed = nil
    self.lastKnownElapsed = 0
end

function TimerEngine:ResumeTimer(totalDuration)
    self.totalDuration = totalDuration or 0
    self.running = true
    self.frozenElapsed = nil
end

function TimerEngine:StopTimer()
    if self.running then
        -- Try to get the live API time
        local apiTime = self:GetAPITime()

        -- If API is 0 (dungeon already reset), use our cached 'lastKnownElapsed'
        if apiTime <= 0 and self.lastKnownElapsed > 0 then
            self.frozenElapsed = self.lastKnownElapsed
        else
            self.frozenElapsed = apiTime
        end

        self.running = false
    end
end

function TimerEngine:ForceFrozenTime(seconds)
    self.running = false
    self.frozenElapsed = seconds
    self.lastKnownElapsed = seconds 
end

function TimerEngine:GetAPITime()
    local getTimer = GetWorldElapsedTime or (C_Timer and C_Timer.GetWorldElapsedTime)
    if getTimer then
        local _, elapsed = getTimer(TIMER_ID)
        if elapsed and elapsed > 0 then
            return elapsed
        end
    end
    return 0
end

function TimerEngine:GetTimeState()
    local elapsed
    
    if self.frozenElapsed then
        elapsed = self.frozenElapsed
    elseif self.running then
        elapsed = self:GetAPITime()
        
        -- [CRITICAL FIX]
        -- If we are "running" but API returns 0 (e.g., depleted instant reset), 
        -- ignore the 0 and return the last valid time we saw.
        if elapsed > 0 then
            self.lastKnownElapsed = elapsed
        elseif self.lastKnownElapsed > 0 then
            elapsed = self.lastKnownElapsed
        end
    else
        elapsed = 0
    end

    local remaining = self.totalDuration - elapsed
    return elapsed, remaining, self.totalDuration
end

function TimerEngine:OnChallengeModeComplete()
    -- 1. Try Official Blizzard Report
    local mapID, level, time = C_ChallengeMode.GetCompletionInfo()

    if time and time > 0 then
        self:ForceFrozenTime(time / 1000)
    else
        -- 2. Fallback
        if self.running then
            self:StopTimer()
        end
    end
end

function TimerEngine:IsActive()
    return self.running
end

function TimerEngine:GetThresholds()
    if self.totalDuration == 0 then return 0, 0 end
    return self.totalDuration * Constants.THRESHOLD_TWO_CHEST, self.totalDuration * Constants.THRESHOLD_THREE_CHEST
end

NS.TimerEngine = TimerEngine