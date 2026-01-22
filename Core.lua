local addonName, NS = ...

-- Helper function for Debug Prints
function NS:DebugPrint(...)
    local db = NS.Utils:GetDB()
    if db and db.debugMode then
        print(...)
    end
end

-- Slash Command Handler
SLASH_NELIMYTHICTIMER1 = "/nmt"
SlashCmdList["NELIMYTHICTIMER"] = function(msg)
    msg = msg:lower()
    local command, rest = msg:match("^(%S*)%s*(.-)$")
    
    if command == "debug" then
        local db = NS.Utils:InitializeDB()
        db.debugMode = not db.debugMode
        local state = db.debugMode and "|cff00ff00ENABLED|r" or "|cffff0000DISABLED|r"
        print("|cff00ff00[NeliMythicTimer]|r Debug Mode: " .. state)
    elseif command == "config" or command == "options" then
        if NS.SettingsCategory and Settings and Settings.OpenToCategory then
             Settings.OpenToCategory(NS.SettingsCategory:GetID())
        elseif Settings and Settings.OpenToCategory then
             Settings.OpenToCategory("NeliMythicTimer")
        else
             InterfaceOptionsFrame_OpenToCategory("NeliMythicTimer")
        end
    elseif command == "demo" then
        if NS.UIManagerInstance then
            NS.UIManagerInstance:ToggleTestMode()
        end
    else
        print("|cff00ff00[NeliMythicTimer]|r Commands:")
        print("  /nmt config - Open options")
        print("  /nmt demo - Toggle demo mode")
    end
end

local function Initialize()
    local eventObserver = NS.EventObserver:New()
    local dataManager = NS.DungeonDataManager:New()

    local deathTracker = NS.DeathTracker:New(eventObserver, dataManager)
    local timerEngine = NS.TimerEngine:New(dataManager, deathTracker)
    local keystoneAnnouncer = NS.KeystoneAnnouncer:New(eventObserver)
    
    -- Store UIManager instance (PullTracker removed)
    NS.UIManagerInstance = NS.UIManager:New(eventObserver, dataManager, timerEngine, deathTracker)

    -- Initialize Config
    local config = NS.Config:New(NS.UIManagerInstance)

end

local loader = CreateFrame("Frame")
loader:RegisterEvent("ADDON_LOADED")
loader:SetScript("OnEvent", function(self, event, name)
    if name == addonName then
        Initialize()
        self:UnregisterEvent("ADDON_LOADED")
    end
end)