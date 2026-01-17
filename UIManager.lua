local _, NS = ...

local UIManager = {}
UIManager.__index = UIManager

local Constants = NS.Constants
local Utils = NS.Utils
local DisplayFormatter = NS.DisplayFormatter

-- Shorthand references
local FONT_FACE = Constants.FONT_FACE
local FONT_FLAG = Constants.FONT_FLAG
local BAR_TEXTURE = Constants.BAR_TEXTURE
local SIZE_HEADER = Constants.SIZE_HEADER
local SIZE_TIMER = Constants.SIZE_TIMER
local SIZE_UPGRADE = Constants.SIZE_UPGRADE
local SIZE_DEATH = Constants.SIZE_DEATH
local SIZE_AFFIX = Constants.SIZE_AFFIX
local SIZE_BAR_TEXT = Constants.SIZE_BAR_TEXT
local SIZE_BOSS_LIST = Constants.SIZE_BOSS_LIST

function UIManager:New(eventObserver, dataManager, timerEngine, deathTracker, pullTracker)
    local instance = setmetatable({}, UIManager)

    instance.dataManager = dataManager
    instance.timerEngine = timerEngine
    instance.deathTracker = deathTracker
    instance.pullTracker = pullTracker
    instance.bossKillTimes = {}
    instance.bossListFrames = {}
    instance.blizzardUIHidden = false
    instance.isCompleted = false
    instance.testMode = false
    
    -- Snapshot variables
    instance.finalEnemyPercent = nil
    instance.finalEnemyText = nil
    
    instance.activeKeyLevel = 0
    instance.showDeathInPanel = false
    instance.syncTicker = nil
    instance.isCountingDown = false
    instance.countdownTime = 0
    
    instance:SetupTooltipHooks()
    instance:BuildInterface()
    instance.mainFrame:Hide()

    instance.mainFrame:SetScript("OnUpdate", function(self, elapsed)
        instance:OnUpdate(elapsed)
    end)

    local db = Utils:InitializeDB()
    if not db.bossKillTimes then
        db.bossKillTimes = {}
    end
    
    -- Initialize scale from DB
    local config = Utils:GetConfig()
    if config.scale then
        instance:ApplyScale(config.scale)
    end

    eventObserver:RegisterEvent("CHALLENGE_MODE_START", instance, instance.OnChallengeModeStart)
    eventObserver:RegisterEvent("CHALLENGE_MODE_COMPLETED", instance, instance.OnChallengeModeEnd)
    
    eventObserver:RegisterEvent("CHALLENGE_MODE_RESET", instance, function()
        instance:HidePanel()
    end)
    
    eventObserver:RegisterEvent("PLAYER_ENTERING_WORLD", instance, instance.OnZoneChange)
    eventObserver:RegisterEvent("ZONE_CHANGED_NEW_AREA", instance, instance.OnZoneChange)
    eventObserver:RegisterEvent("START_TIMER", instance, instance.OnStartTimer)
    eventObserver:RegisterEvent("NAME_PLATE_UNIT_ADDED", instance, instance.OnNamePlateAdded)
    eventObserver:RegisterEvent("NAME_PLATE_UNIT_REMOVED", instance, instance.OnNamePlateRemoved)
    eventObserver:RegisterEvent("SCENARIO_CRITERIA_UPDATE", instance, instance.OnScenarioCriteriaUpdate)
    
    instance:CheckActiveRun()

    return instance
end

function UIManager:IsInActiveRun()
    local _, _, difficultyID = GetInstanceInfo()
    local mapID = C_ChallengeMode.GetActiveChallengeMapID()
    
    return (difficultyID == 8) and (mapID ~= nil and mapID > 0)
end
function UIManager:ApplyScale(scale)
    if self.mainFrame then
        self.mainFrame:SetScale(scale or 1.0)
    end
end
function UIManager:RefreshConfig()
    local config = Utils:GetConfig()
    
    -- Apply Scale
    self:ApplyScale(config.scale)
    
    -- If in demo mode, update the demo visuals
    if self.testMode then
        self:UpdateDemoDisplay(config)
    else
        -- Otherwise update real data
        self:UpdateScenarioInfo(0)
    end
    
    -- Update existing nameplates
    local plates = C_NamePlate.GetNamePlates()
    for _, plate in ipairs(plates) do
         if plate.UnitFrame then
             self:UpdateNameplateForces(plate.UnitFrame)
         end
    end
end

-- New function to draw the static demo information
function UIManager:UpdateDemoDisplay(config)
    -- 1. Static Header Info
    self.mainFrame.dungeonName:SetText("Demo Dungeon +10")
    self.mainFrame.timerText:SetText("(+10) |cffffffff23:54 / 30:00|r")
    self.mainFrame.deathText:SetText("|cffffffff0 Deaths|r")
    self.mainFrame.affixText:SetText("Affix1, Affix2, Affix3")
    
    -- 2. Enemy Forces Demo (12% value)
    local killedPercent = 12.0
    local totalCount = 300
    local rawKilled = 36 -- 12% of 300
    
    local parts = {}
    if config.showEnemyCount then 
        table.insert(parts, string.format("%d/%d", rawKilled, totalCount)) 
    end
    if config.showEnemyPercent then 
        table.insert(parts, string.format("%.1f%%", killedPercent)) 
    end
    
    local displayText = table.concat(parts, " - ")
    if displayText == "" then displayText = "12.00%" end

    -- Ghost Bar Logic for Demo
    if config.showPullProgress then
        local pullPercent = 5.0
        if config.showEnemyPercent then
            displayText = displayText .. string.format(" |cff00ff00+ %.1f%%|r", pullPercent)
        elseif config.showEnemyCount then
             displayText = displayText .. string.format(" |cff00ff00+ %d|r", 15)
        end
        self.mainFrame.ghostBar:SetValue(killedPercent + pullPercent)
        self.mainFrame.ghostBar:Show()
    else
        self.mainFrame.ghostBar:Hide()
    end
    
    self.mainFrame.enemyText:SetText(displayText)
    self.mainFrame.enemyBar:SetValue(killedPercent)

    -- 3. Boss List Demo
    -- Hide all current boss frames first
    for _, frame in pairs(self.bossListFrames) do frame:Hide() end
        
        local demoBosses = {
            { name = "First Boss", time = "12:40", completed = true },
            { name = "Second Boss", completed = false },
            { name = "Third Boss", completed = false },
        }
        
        for i, data in ipairs(demoBosses) do
            local line = self.bossListFrames[i]
            if not line then
                line = self.mainFrame.bossContainer:CreateFontString(nil, "OVERLAY")
                line:SetFont(FONT_FACE, SIZE_BOSS_LIST, FONT_FLAG) 
                line:SetJustifyH("RIGHT")
                self.bossListFrames[i] = line
            end
            line:ClearAllPoints()
            line:SetPoint("TOPRIGHT", self.mainFrame.bossContainer, "TOPRIGHT", 0, -((i - 1) * 20))
            
            local displayText = data.name
            if data.completed then
                if config.showBossKillTimes then
                    displayText = string.format("|cff00ff00[%s] %s|r", data.time, data.name)
                else
                    displayText = string.format("|cff00ff00%s|r", data.name)
                end
            else
                displayText = string.format("|cffffffff%s|r", data.name)
            end
            
            line:SetText(displayText)
            line:Show()
        end
    end
-- Update ToggleTestMode to trigger the refresh
function UIManager:ToggleTestMode()
    -- Only block if trying to ENABLE demo mode while in a real run
    if not self.testMode and self:IsInActiveRun() then
        print("|cffff0000[NMT] Cannot enable Demo Mode while in an active Mythic+ run!|r")
        return
    end

    self.testMode = not self.testMode
    if self.testMode then
        self.mainFrame:Show()
        self:SetGameplayVisibility(true)
        self:HideBlizzardUI()
        self:RefreshConfig()
        print("|cff00ff00[NMT]|r Demo Mode Enabled.")
    else
        -- Clean reset when disabling
        self.mainFrame:Hide()
        self:FullReset(true)
        self:RestoreBlizzardUI()
        print("|cff00ff00[NMT]|r Demo Mode Disabled.")
    end
end

function UIManager:SetupTooltipHooks()
    TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Unit, function(tooltip)
        -- Config Check
        local config = Utils:GetConfig()
        if not config.showTooltipPercent then return end

        local _, unit = tooltip:GetUnit()
        if not unit or UnitIsPlayer(unit) then return end
        local guid = UnitGUID(unit)
        local npcID = Utils:GetNPCIDFromGUID(guid)
        if npcID then
            local mobValue = NS.MobData:GetMobValue(npcID)
            if mobValue > 0 then
                local percent = self:RawCountToPercent(mobValue)
                tooltip:AddLine(" ")
                tooltip:AddLine(string.format("|cff00ff00[NMT] + %.2f%%|r", percent))
            end
        end
    end)
end

function UIManager:OnNamePlateAdded(unit)
    local plate = C_NamePlate.GetNamePlateForUnit(unit)
    if plate and plate.UnitFrame then
        self:UpdateNameplateForces(plate.UnitFrame)
    end
end

function UIManager:OnNamePlateRemoved(unit)
    local plate = C_NamePlate.GetNamePlateForUnit(unit)
    if plate and plate.UnitFrame and plate.UnitFrame.NeliForceText then
        plate.UnitFrame.NeliForceText:Hide()
    end
end

-- === HELPER METHODS FOR SCENARIO UPDATE ===
function UIManager:UpdateEnemyForces(info, config)
    local dungeonTotal = info.totalQuantity or 0
    if dungeonTotal <= 0 then return end
    
    local rawKilled = 0
    if info.quantityString then
        rawKilled = tonumber(string.match(info.quantityString, "(%d+)")) or 0
    end

    local killedPercent = (rawKilled / dungeonTotal) * 100
    local pullCount = self.pullTracker:GetCurrentPullCount()
    local pullPercent = (pullCount / dungeonTotal) * 100

    -- Set color based on completion
    if killedPercent >= 100 then
        self.mainFrame.enemyText:SetTextColor(0, 1, 0)
    else
        self.mainFrame.enemyText:SetTextColor(1, 1, 1)
    end

    -- Format display text
    local displayText, _ = DisplayFormatter:FormatEnemyForces(rawKilled, dungeonTotal, config)
    
    -- Add pull progress if enabled
    if config.showPullProgress and pullCount > 0 then
        local pullText, _ = DisplayFormatter:FormatPullProgress(pullCount, dungeonTotal, config)
        displayText = displayText .. pullText
        self.mainFrame.ghostBar:SetValue(killedPercent + pullPercent)
        self.mainFrame.ghostBar:Show()
    else
        self.mainFrame.ghostBar:Hide()
    end
    
    self.mainFrame.enemyText:SetText(displayText)
    self.mainFrame.enemyBar:SetValue(killedPercent)
end

function UIManager:UpdateCompletedEnemyForces(config)
    local displayText = DisplayFormatter:FormatCompletedEnemyForces(300, config) -- Using placeholder
    self.mainFrame.enemyText:SetText(displayText)
    self.mainFrame.enemyBar:SetValue(100)
    self.mainFrame.ghostBar:Hide()
end

function UIManager:UpdateBossLine(bossIndex, bossName, isCompleted, currentElapsed, config)
    local db = Utils:GetDB()
    local killTimeRaw = db.bossKillTimes[bossName]
    
    -- Record kill if API says completed but we don't have it yet
    if isCompleted and not killTimeRaw then
        killTimeRaw = currentElapsed
        if killTimeRaw <= 0 then killTimeRaw = -1 end
        db.bossKillTimes[bossName] = killTimeRaw
    end

    -- Determine completion: API OR internal database
    local isBossDead = (isCompleted == true) or (killTimeRaw ~= nil)

    local line = self.bossListFrames[bossIndex]
    if not line then
        line = self.mainFrame.bossContainer:CreateFontString(nil, "OVERLAY")
        line:SetFont(FONT_FACE, SIZE_BOSS_LIST, FONT_FLAG) 
        line:SetJustifyH("RIGHT")
        self.bossListFrames[bossIndex] = line
    end

    line:ClearAllPoints()
    line:SetPoint("TOPRIGHT", self.mainFrame.bossContainer, "TOPRIGHT", 0, -((bossIndex - 1) * 20))
    
    local displayText = DisplayFormatter:FormatBossLine(bossName, isBossDead, killTimeRaw, config)
    line:SetText(displayText)
    line:Show()
end

function UIManager:UpdateScenarioInfo(elapsed)
    if self.testMode then return end -- Don't update real info in demo mode

    local config = Utils:GetConfig()
    local _, _, numCriteria = C_Scenario.GetStepInfo()
    local numCompleted = 0

    -- Count completed criteria
    for i = 1, (numCriteria or 0) do
        local info = C_ScenarioInfo.GetCriteriaInfo(i)
        if info and info.completed then
            numCompleted = numCompleted + 1
        end
    end

    -- Check for completion
    if numCriteria and numCriteria > 0 and numCompleted == numCriteria then
        if self.timerEngine:IsActive() then
            local officialTime = C_ChallengeMode.GetCompletionInfo()
            if officialTime and officialTime > 0 then
                self.timerEngine:ForceFrozenTime(officialTime / 1000)
            else
                self.timerEngine:StopTimer()
            end
        end
        self.isCompleted = true
    end

    local currentElapsed, _, _ = self.timerEngine:GetTimeState()
    local bossIndex = 0

    -- Process each criterion
    for i = 1, (numCriteria or 0) do
        local info = C_ScenarioInfo.GetCriteriaInfo(i)
        if info then
            if info.isWeightedProgress then
                -- Enemy Forces
                if not self.isCompleted then
                    self:UpdateEnemyForces(info, config)
                else
                    self.mainFrame.ghostBar:Hide()
                end
            elseif info.description and info.description ~= "" then
                -- Boss
                bossIndex = bossIndex + 1
                self:UpdateBossLine(bossIndex, info.description, info.completed, currentElapsed, config)
            end
        end
    end
end

function UIManager:OnChallengeModeEnd()
    self.isCompleted = true
    self:UpdateScenarioInfo(0) 
    print("|cff00ff00[NMT] Run Completed!|r")
end

function UIManager:OnScenarioCriteriaUpdate()
    self:UpdateScenarioInfo(0)
end

function UIManager:GetDungeonForces()
    return self.dataManager:GetDungeonForces()
end

function UIManager:RawCountToPercent(rawCount)
    local dungeonForces = self:GetDungeonForces()
    if dungeonForces and dungeonForces > 0 then
        return (rawCount / dungeonForces) * 100
    end
    return 0
end

function UIManager:BuildInterface()
    local f = CreateFrame("Frame", "NeliMythicHUD", UIParent)
    f:SetSize(285, 300)
    f:SetPoint("RIGHT", -30, 20)

    f.dungeonName = f:CreateFontString(nil, "OVERLAY")
    f.dungeonName:SetFont(FONT_FACE, SIZE_HEADER, FONT_FLAG)
    f.dungeonName:SetPoint("TOPRIGHT", -10, -10)
    f.dungeonName:SetJustifyH("RIGHT")
    f.dungeonName:SetText("Waiting for Key...")

    f.timerText = f:CreateFontString(nil, "OVERLAY")
    f.timerText:SetFont(FONT_FACE, SIZE_TIMER, FONT_FLAG)
    f.timerText:SetPoint("TOPRIGHT", f.dungeonName, "BOTTOMRIGHT", 0, -5)
    f.timerText:SetJustifyH("RIGHT")

    f.upgradeText = f:CreateFontString(nil, "OVERLAY")
    f.upgradeText:SetFont(FONT_FACE, SIZE_UPGRADE, FONT_FLAG)
    f.upgradeText:SetPoint("TOPRIGHT", f.timerText, "BOTTOMRIGHT", 0, -2)
    f.upgradeText:SetJustifyH("RIGHT")
    f.upgradeText:SetTextColor(1, 1, 0, 1)

    f.deathText = f:CreateFontString(nil, "OVERLAY")
    f.deathText:SetFont(FONT_FACE, SIZE_DEATH, FONT_FLAG)
    f.deathText:SetPoint("TOPRIGHT", f.upgradeText, "BOTTOMRIGHT", 0, -5)
    f.deathText:SetJustifyH("RIGHT")

    f.deathHitbox = CreateFrame("Button", nil, f)
    f.deathHitbox:SetHeight(SIZE_DEATH + 4)
    f.deathHitbox:SetWidth(150)
    f.deathHitbox:SetPoint("RIGHT", f.deathText, "RIGHT", -40, 0)
    f.deathHitbox:EnableMouse(true)
    f.deathHitbox:SetScript("OnEnter", function(btn)
        local totalDeaths = self.deathTracker:GetDeathCount()
        if not totalDeaths or totalDeaths == 0 then return end
        local deaths = self.deathTracker:GetDeathBreakdown()
        GameTooltip:SetOwner(btn, "ANCHOR_LEFT")
        GameTooltip:AddLine("Deaths", 1, 1, 1)
        GameTooltip:AddLine(" ")
        if deaths and next(deaths) then
            for name, data in pairs(deaths) do
                local color = (CUSTOM_CLASS_COLORS or RAID_CLASS_COLORS)[data.class] or {r=1, g=1, b=1}
                GameTooltip:AddDoubleLine(name, tostring(data.count), color.r, color.g, color.b, 1, 0, 0)
            end
        end
        GameTooltip:Show()
    end)
    f.deathHitbox:SetScript("OnLeave", function() GameTooltip:Hide() end)

    f.affixText = f:CreateFontString(nil, "OVERLAY")
    f.affixText:SetFont(FONT_FACE, SIZE_AFFIX, FONT_FLAG)
    f.affixText:SetPoint("TOPRIGHT", f.deathText, "BOTTOMRIGHT", 0, -5)
    f.affixText:SetJustifyH("RIGHT")
    f.affixText:SetTextColor(0.5, 0.5, 0.5, 1)

    f.enemyBarContainer = CreateFrame("Frame", nil, f)
    f.enemyBarContainer:SetSize(270, 16)
    f.enemyBarContainer:SetPoint("TOPRIGHT", f.affixText, "BOTTOMRIGHT", 0, -20)
    
    f.enemyBarBG = f.enemyBarContainer:CreateTexture(nil, "BACKGROUND")
    f.enemyBarBG:SetAllPoints(f.enemyBarContainer)
    f.enemyBarBG:SetColorTexture(0, 0, 0, 1)

    f.ghostBar = CreateFrame("StatusBar", nil, f.enemyBarContainer)
    f.ghostBar:SetPoint("TOPLEFT", f.enemyBarContainer, "TOPLEFT", 0, 0)
    f.ghostBar:SetPoint("BOTTOMRIGHT", f.enemyBarContainer, "BOTTOMRIGHT", 0, 1)
    f.ghostBar:SetStatusBarTexture(BAR_TEXTURE)
    f.ghostBar:SetStatusBarColor(0, 1, 0, 0.4)
    f.ghostBar:SetMinMaxValues(0, 100)

    f.enemyBar = CreateFrame("StatusBar", nil, f.enemyBarContainer)
    f.enemyBar:SetPoint("TOPLEFT", f.enemyBarContainer, "TOPLEFT", 0, 0)
    f.enemyBar:SetPoint("BOTTOMRIGHT", f.enemyBarContainer, "BOTTOMRIGHT", 0, 0)
    f.enemyBar:SetStatusBarTexture(BAR_TEXTURE)
    f.enemyBar:SetStatusBarColor(0.45, 0, 0.85, 1)
    f.enemyBar:SetMinMaxValues(0, 100)

    f.enemyText = f.enemyBar:CreateFontString(nil, "OVERLAY")
    f.enemyText:SetFont(FONT_FACE, SIZE_BAR_TEXT, FONT_FLAG)
    f.enemyText:SetPoint("CENTER", f.enemyBar, "CENTER")
    f.enemyText:SetTextColor(1, 1, 1, 1)

    f.bossContainer = CreateFrame("Frame", nil, f)
    f.bossContainer:SetSize(230, 200)
    f.bossContainer:SetPoint("TOPRIGHT", f.enemyBar, "BOTTOMRIGHT", 0, -15)

    self.mainFrame = f
end

function UIManager:HideBlizzardUI()
    self.blizzardUIHidden = true
    if ObjectiveTrackerFrame then ObjectiveTrackerFrame:SetShown(false) end
    if ScenarioBlocksFrame then ScenarioBlocksFrame:SetShown(false) end
end

function UIManager:RestoreBlizzardUI()
    self.blizzardUIHidden = false
    if ObjectiveTrackerFrame then ObjectiveTrackerFrame:SetShown(true) end
    if ScenarioBlocksFrame then ScenarioBlocksFrame:SetShown(true) end
end

function UIManager:EnforceBlizzardUIHidden()
    if not self.blizzardUIHidden then return end
    if ObjectiveTrackerFrame and ObjectiveTrackerFrame:IsShown() then ObjectiveTrackerFrame:SetShown(false) end
    if ScenarioBlocksFrame and ScenarioBlocksFrame:IsShown() then ScenarioBlocksFrame:SetShown(false) end
end

function UIManager:ShowPanel()
    self.mainFrame:Show()
    self:HideBlizzardUI()
end

function UIManager:HidePanel()
    self.mainFrame:Hide()
    self:RestoreBlizzardUI()
end

function UIManager:SetGameplayVisibility(show)
    self.mainFrame.upgradeText:SetShown(show)
    self.mainFrame.enemyBarContainer:SetShown(show)
    local showDeaths = show and self.showDeathInPanel
    self.mainFrame.deathText:SetShown(showDeaths)
    self.mainFrame.deathHitbox:SetShown(showDeaths)
    self.mainFrame.affixText:SetShown(show)
    self.mainFrame.bossContainer:SetShown(show)
end

function UIManager:UpdateRunConfig()
    local level = self.dataManager:GetActiveKeystoneLevel() or 0
    self.activeKeyLevel = level
    self.showDeathInPanel = (level > 3)
end

function UIManager:CheckActiveRun()
    local _, _, difficultyID = GetInstanceInfo()
    if difficultyID ~= 8 then self:HidePanel() return end
    
    local mapID = C_ChallengeMode.GetActiveChallengeMapID()
    if mapID then
        local mapInfo = self.dataManager:GetMapInfo()
        if mapInfo then
            self:UpdateRunConfig()
            self.mainFrame.dungeonName:SetText(mapInfo.name)
            
            local completionTime = C_ChallengeMode.GetCompletionInfo()
            if completionTime and completionTime > 0 then
                self.isCompleted = true
                self.timerEngine:ForceFrozenTime(completionTime / 1000)
                
                self:SetGameplayVisibility(true)
                self:UpdateScenarioInfo(0)
            else
                self.timerEngine:ResumeTimer(mapInfo.time) 
            end

            self:UpdateAffixes()
            self.deathTracker:UpdateDeathCount()
            self:ShowPanel()
        end
    end
end

function UIManager:FullReset(force)
    -- We use engine to check if we have time
    local currentTime = self.timerEngine:GetAPITime()
    
    if force or currentTime == 0 then
        self.isCompleted = false
        local db = Utils:GetDB()
        db.bossKillTimes = {}
        self.finalEnemyPercent = nil
        self.finalEnemyText = nil
        
        self.activeKeyLevel = 0
        self.showDeathInPanel = false
        self.deathTracker:Reset()
        self.timerEngine:Reset()
        
        if self.keystoneAnnouncer then self.keystoneAnnouncer:Reset() end
        for _, frame in pairs(self.bossListFrames) do frame:Hide() end

        if self.mainFrame then
            self.mainFrame.enemyText:SetText("")
            self.mainFrame.enemyBar:SetValue(0)
            self.mainFrame.ghostBar:Hide()
            self.mainFrame.timerText:SetText("")
            self.mainFrame.upgradeText:SetText("")
        end
    end
end

function UIManager:OnChallengeModeStart()
    self.testMode = false
    if self.syncTicker then self.syncTicker:Cancel() end
    local currentTime = self.timerEngine:GetAPITime()
    local level = C_ChallengeMode.GetActiveKeystoneInfo()

    if currentTime > 2 and level and level >= 2 then
        self:UpdateRunConfig()
        self:CheckActiveRun()
    else
        self:FullReset(true)
        self:UpdateRunConfig()
        self:UpdateUIAndShow()
    end
end

function UIManager:UpdateUIAndShow()
    local mapInfo = self.dataManager:GetMapInfo()
    if mapInfo then self.mainFrame.dungeonName:SetText(mapInfo.name) end
    self:UpdateAffixes()
    self:ShowPanel()
end

function UIManager:OnZoneChange()
    local _, instanceType = GetInstanceInfo()
    if self.syncTicker then self.syncTicker:Cancel() end
    
    if instanceType == "party" then
        local checkCount = 0
        local maxChecks = 20 
        self.syncTicker = C_Timer.NewTicker(0.2, function(timer)
            checkCount = checkCount + 1
            local level = C_ChallengeMode.GetActiveKeystoneInfo()
            if level and level > 0 then
                timer:Cancel()
                self:CheckActiveRun() 
                return
            end
            if checkCount >= maxChecks then
                timer:Cancel()
                self:FullReset(true)
                self:CheckActiveRun()
            end
        end)
    else 
        self:HidePanel() 
    end
end

function UIManager:UpdateAffixes()
    local affixes = self.dataManager:GetAffixes()
    local affixString = DisplayFormatter:FormatAffixText(affixes)
    self.mainFrame.affixText:SetText(affixString)
    local offset = (affixString == "") and 0 or -20
    self.mainFrame.enemyBarContainer:ClearAllPoints()
    self.mainFrame.enemyBarContainer:SetPoint("TOPRIGHT", self.mainFrame.affixText, "BOTTOMRIGHT", 0, offset)
end

function UIManager:FormatTime(seconds)
    return Utils:FormatTime(seconds)
end

function UIManager:OnUpdate(elapsed)
    if self.testMode then return end -- Demo mode has static data

    local _, _, difficultyID = GetInstanceInfo()
    if difficultyID ~= 8 then self:HidePanel() return end
    self:EnforceBlizzardUIHidden()

    -- Check engine status
    local currentTime = self.timerEngine:GetAPITime()
    local isStarted = (currentTime > 0)
    local showPanel = (isStarted or self.isCompleted)
    self:SetGameplayVisibility(showPanel)
    
    if isStarted and self.activeKeyLevel == 0 then
        self:UpdateRunConfig()
    end

    if showPanel then
        -- Engine auto-fetches time, we just ensure it's "On"
        if not self.isCompleted and not self.timerEngine.running then
             local mapInfo = self.dataManager:GetMapInfo()
             if mapInfo then self.timerEngine:ResumeTimer(mapInfo.time) end
        end

        -- Blizzard's elapsed time already includes death penalty
        local current, remaining, total = self.timerEngine:GetTimeState()

        if total > 0 then
            self.mainFrame.timerText:SetText(DisplayFormatter:FormatTimerText(current, total, self.activeKeyLevel))

            local t2, t3 = self.timerEngine:GetThresholds()
            local r3, r2 = t3 - current, t2 - current
            self.mainFrame.upgradeText:SetText(DisplayFormatter:FormatUpgradeText(r2, r3))
        end

        self:UpdateScenarioInfo(elapsed)

        if self.mainFrame.deathText:IsShown() then
            local deathCount = self.deathTracker:GetDeathCount()
            local penalty = self.deathTracker:GetTotalTimePenalty()
            self.mainFrame.deathText:SetText(DisplayFormatter:FormatDeathText(deathCount, penalty))
        end
    else
        self.mainFrame.timerText:SetText(string.format("(+%d) Starting...", self.activeKeyLevel))
        self.mainFrame.upgradeText:SetText("")
    end
end

function UIManager:UpdateNameplateForces(frame)
    -- Config check
    local config = Utils:GetConfig()
    if not config.showNameplatePercent then 
        if frame.NeliForceText then frame.NeliForceText:Hide() end
        return 
    end

    local total = self:GetDungeonForces()
    if total == 0 then return end
    local unit = frame.unit
    if not unit then return end
    local guid = UnitGUID(unit)
    local npcID = Utils:GetNPCIDFromGUID(guid)
    if npcID then
        local mobValue = NS.MobData:GetMobValue(npcID)
        if mobValue > 0 then
            local forcePercent = self:RawCountToPercent(mobValue)
            if not frame.NeliForceText then
                frame.NeliForceText = frame:CreateFontString(nil, "OVERLAY")
                frame.NeliForceText:SetFont(FONT_FACE, Constants.SIZE_NAMEPLATE, "OUTLINE")
                frame.NeliForceText:SetPoint("LEFT", frame.HealthBar or frame, "RIGHT", -5, -5)
                frame.NeliForceText:SetTextColor(1, 1, 1)
            end
            frame.NeliForceText:SetText(string.format("%.2f%%", forcePercent))
            frame.NeliForceText:Show()
        elseif frame.NeliForceText then
            frame.NeliForceText:Hide()
        end
    elseif frame.NeliForceText then
        frame.NeliForceText:Hide()
    end
end

NS.UIManager = UIManager