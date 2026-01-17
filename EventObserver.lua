local _, NS = ...

local EventObserver = {}
EventObserver.__index = EventObserver

function EventObserver:New()
    local instance = setmetatable({}, EventObserver)
    instance.events = {}
    instance.frame = CreateFrame("Frame")
    instance.frame:SetScript("OnEvent", function(_, event, ...)
        instance:OnEventTriggered(event, ...)
    end)
    return instance
end

function EventObserver:RegisterEvent(event, target, func)
    if not self.events[event] then
        self.events[event] = {}
        self.frame:RegisterEvent(event)
    end
    
    -- Safety check: ensure func is not nil before adding to table
    if func then
        table.insert(self.events[event], { target = target, func = func })
    else
    end
end

function EventObserver:OnEventTriggered(event, ...)
    if self.events[event] then
        for _, registration in ipairs(self.events[event]) do
            -- [FIX] Safety check before calling the function
            if type(registration.func) == "function" then
                registration.func(registration.target, ...)
            else
            end
        end
    end
end

NS.EventObserver = EventObserver