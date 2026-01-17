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
end

function TimerEngine:StartTimer(duration)
    self.totalDuration = duration
    self.running = true
    self.frozenElapsed = nil
end

-- Simply enables the timer. We don't need to pass 'elapsed' anymore.
function TimerEngine:ResumeTimer(totalDuration)
    self.totalDuration = totalDuration or 0
    self.running = true
    self.frozenElapsed = nil
end

function TimerEngine:StopTimer()
    if self.running then
        -- Freeze on the last known API time so the UI doesn't zero out
        self.frozenElapsed = self:GetAPITime()
        self.running = false
    end
end

-- Allows UIManager to overwrite the time (e.g. with official completion time)
function TimerEngine:ForceFrozenTime(seconds)
    self.running = false
    self.frozenElapsed = seconds
end

-- [CORE LOGIC] Directly asks Blizzard for the time. No local math.
function TimerEngine:GetAPITime()
    if GetWorldElapsedTime then
        local _, elapsed = GetWorldElapsedTime(TIMER_ID)
        if elapsed and elapsed > 0 then
            return elapsed
        end
    end
    return 0
end

function TimerEngine:GetTimeState()
    local elapsed
    
    if self.frozenElapsed then
        -- If frozen (run over), return the static final time
        elapsed = self.frozenElapsed
    elseif self.running then
        -- If running, ALWAYS ask Blizzard. Never calculate locally.
        elapsed = self:GetAPITime()
    else
        elapsed = 0
    end

    local remaining = self.totalDuration - elapsed
    return elapsed, remaining, self.totalDuration
end

function TimerEngine:OnChallengeModeComplete()
    if self.running then
        self:StopTimer()
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