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

-- [SMART POSITIONING]
local function GetSmartDefaultOffset()
    local xOffset = -70
    if MultiBarRight and MultiBarRight:IsShown() then xOffset = xOffset - 85 end
    if MultiBarLeft and MultiBarLeft:IsShown() then xOffset = xOffset - 85 end
    return xOffset
end

function UIManager:New(eventObserver, dataManager, timerEngine, deathTracker)
    local instance = setmetatable({}, UIManager)

    instance.dataManager = dataManager
    instance.timerEngine = timerEngine
    instance.deathTracker = deathTracker
    
    instance.bossKillTimes = {}
    instance.bossListFrames = {}
    instance.blizzardUIHidden = false
    instance.isCompleted = false
    instance.testMode = false
    instance.activeKeyLevel = 0
    instance.showDeathInPanel = false
    instance.cachedDungeonTotal = 0

    instance:BuildInterface()
    instance.mainFrame:Hide()

    instance.mainFrame:SetScript("OnUpdate", function(self, elapsed)
        instance:OnUpdate(elapsed)
    end)
    
    instance:RefreshConfig()

    eventObserver:RegisterEvent("CHALLENGE_MODE_START", instance, instance.OnChallengeModeStart)
    eventObserver:RegisterEvent("CHALLENGE_MODE_COMPLETED", instance, instance.OnChallengeModeEnd)
    eventObserver:RegisterEvent("CHALLENGE_MODE_RESET", instance, function() instance:HidePanel() end)
    eventObserver:RegisterEvent("PLAYER_ENTERING_WORLD", instance, instance.OnZoneChange)
    eventObserver:RegisterEvent("ZONE_CHANGED_NEW_AREA", instance, instance.OnZoneChange)
    eventObserver:RegisterEvent("START_TIMER", instance, instance.OnStartTimer)
    eventObserver:RegisterEvent("SCENARIO_CRITERIA_UPDATE", instance, instance.OnScenarioCriteriaUpdate)
    
    instance:CheckActiveRun()
    
    NS.UIManagerInstance = instance
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
    self:ApplyScale(config.scale)
    self:RestorePosition()

    if config.colors then
        local cBar = config.colors.enemyBar
        if cBar then self.mainFrame.enemyBar:SetStatusBarColor(cBar.r, cBar.g, cBar.b, cBar.a) end
        
        local cName = config.colors.dungeonName
        if cName then self.mainFrame.dungeonName:SetTextColor(cName.r, cName.g, cName.b, cName.a) end
    end
    
    if self.testMode then
        self:UpdateDemoDisplay(config)
    else
        self:UpdateScenarioInfo(0)
    end
end

-- [NEW] Dynamic Layout Engine
function UIManager:UpdateLayout()
    local lastFrame = self.mainFrame.upgradeText
    local smallGap = -5
    local largeGap = -5
    
    -- Determine what SHOULD be visible
    local showDeath = (self.showDeathInPanel or self.testMode)
    local hasAffix = (self.mainFrame.affixText:GetText() ~= "")
    
    -- 1. Death Text
    if showDeath then
        self.mainFrame.deathText:ClearAllPoints()
        self.mainFrame.deathText:SetPoint("TOPRIGHT", lastFrame, "BOTTOMRIGHT", 0, smallGap)
        lastFrame = self.mainFrame.deathText
    end
    
    -- 2. Affix Text
    if hasAffix then
        self.mainFrame.affixText:ClearAllPoints()
        self.mainFrame.affixText:SetPoint("TOPRIGHT", lastFrame, "BOTTOMRIGHT", 0, smallGap)
        lastFrame = self.mainFrame.affixText
    end
    
    -- 3. Enemy Bar (Anchors to whatever was last)
    self.mainFrame.enemyBarContainer:ClearAllPoints()
    -- If no affixes/deaths, we might want a slightly smaller gap than -20, but -20 usually looks good for separation
    self.mainFrame.enemyBarContainer:SetPoint("TOPRIGHT", lastFrame, "BOTTOMRIGHT", 0, largeGap)
end

function UIManager:UpdateDemoDisplay(config)
    self.mainFrame.dungeonName:SetText("Demo Dungeon")
    self.mainFrame.timerText:SetText(DisplayFormatter:FormatTimerText(1554, 1800, 10, config))
    self.mainFrame.deathText:SetText(DisplayFormatter:FormatDeathText(0, 0, config))
    self.mainFrame.affixText:SetText(DisplayFormatter:FormatAffixText({"Affix1", "Affix2"}, config))
    self.mainFrame.upgradeText:SetText(DisplayFormatter:FormatUpgradeText(100, 300, config))
    
    local demoData = DisplayFormatter:GetDemoEnemyData()
    local displayText, _ = DisplayFormatter:FormatEnemyForces(demoData.rawKilled, demoData.totalCount, config)
    self.mainFrame.enemyText:SetText(displayText)
    self.mainFrame.enemyBar:SetValue(demoData.killedPercent)

    for _, frame in pairs(self.bossListFrames) do frame:Hide() end
    local demoBosses = DisplayFormatter:GetDemoBosses()
    
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
        
        local text = DisplayFormatter:FormatBossLine(data.name, data.completed, 760, config)
        line:SetText(text)
        line:Show()
    end
end

function UIManager:ToggleTestMode()
    if not self.testMode and self:IsInActiveRun() then
        print("|cffff0000[NMT] Cannot enable Demo Mode while in an active Mythic+ run!|r")
        return
    end

    self.testMode = not self.testMode
    
    -- [UPDATE] Trigger Layout Update because Test Mode forces Death/Affix visibility
    self:UpdateLayout()

    if self.testMode then
        self.mainFrame:Show()
        self:SetGameplayVisibility(true)
        self:HideBlizzardUI()
        self:RefreshConfig()
        print("|cff00ff00[NMT]|r Demo Mode Enabled.")
    else
        self.mainFrame:Hide()
        self:FullReset(true)
        self:RestoreBlizzardUI()
        print("|cff00ff00[NMT]|r Demo Mode Disabled.")
    end
end

function UIManager:UpdateEnemyForces(info, config)
    local dungeonTotal = self.cachedDungeonTotal
    if dungeonTotal <= 0 then dungeonTotal = info.totalQuantity or 0 end
    if dungeonTotal <= 0 then return end

    local rawKilled = 0
    if info.quantityString then
        rawKilled = tonumber(string.match(info.quantityString, "(%d+)")) or 0
    end

    local displayText, percent = DisplayFormatter:FormatEnemyForces(rawKilled, dungeonTotal, config)
    self.mainFrame.enemyText:SetText(displayText)
    self.mainFrame.enemyBar:SetValue(percent)
end

function UIManager:UpdateCompletedEnemyForces(dungeonTotal, config)
    local displayText = DisplayFormatter:FormatCompletedEnemyForces(dungeonTotal, config)
    self.mainFrame.enemyText:SetText(displayText)
    self.mainFrame.enemyBar:SetValue(100)
end

function UIManager:UpdateBossLine(bossIndex, bossName, isCompleted, currentElapsed, config)
    local db = Utils:GetDB()
    local killTimeRaw = db.bossKillTimes[bossName]
    
    if isCompleted and not killTimeRaw then
        killTimeRaw = currentElapsed
        if killTimeRaw <= 0 then killTimeRaw = -1 end
        db.bossKillTimes[bossName] = killTimeRaw
    end

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

function UIManager:AttemptCacheDungeonData()
    if self.cachedDungeonTotal > 0 then return end 
    local _, _, numCriteria = C_Scenario.GetStepInfo()
    for i = 1, (numCriteria or 0) do
        local info = C_ScenarioInfo.GetCriteriaInfo(i)
        if info and info.isWeightedProgress and info.totalQuantity and info.totalQuantity > 0 then
            self.cachedDungeonTotal = info.totalQuantity
            return
        end
    end
end

function UIManager:UpdateScenarioInfo(elapsed)
    if self.testMode then return end
    if self.cachedDungeonTotal == 0 then self:AttemptCacheDungeonData() end
    
    local config = Utils:GetConfig()

    if self.isCompleted then
        if self.cachedDungeonTotal > 0 then
             self:UpdateCompletedEnemyForces(self.cachedDungeonTotal, config)
        else
             self.mainFrame.enemyText:SetText("100%")
             self.mainFrame.enemyBar:SetValue(100)
        end
        return 
    end

    local _, _, numCriteria = C_Scenario.GetStepInfo()
    local numCompleted = 0

    for i = 1, (numCriteria or 0) do
        local info = C_ScenarioInfo.GetCriteriaInfo(i)
        if info and info.completed then
            numCompleted = numCompleted + 1
        end
    end

    if numCriteria and numCriteria > 0 and numCompleted == numCriteria then
        if self.timerEngine:IsActive() then
            local completionInfo = C_ChallengeMode.GetChallengeCompletionInfo()
            if completionInfo and completionInfo.time and completionInfo.time > 0 then
                self.timerEngine:ForceFrozenTime(completionInfo.time / 1000)
            else
                self.timerEngine:StopTimer()
            end
        end
    end

    local currentElapsed, _, _ = self.timerEngine:GetTimeState()
    local bossIndex = 0

    for i = 1, (numCriteria or 0) do
        local info = C_ScenarioInfo.GetCriteriaInfo(i)
        if info then
            if info.isWeightedProgress then
                self:UpdateEnemyForces(info, config)
            elseif info.description and info.description ~= "" then
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

function UIManager:BuildInterface()
    local f = CreateFrame("Frame", "NeliMythicHUD", UIParent)
    f:SetSize(285, 300)
    
    f:SetMovable(true)
    f:SetClampedToScreen(true)
    f:SetUserPlaced(false) 
    
    f.dragTex = f:CreateTexture(nil, "ARTWORK")
    f.dragTex:SetAllPoints()
    f.dragTex:SetColorTexture(0, 0, 0, 0.6) 
    f.dragTex:Hide()

    f:SetScript("OnMouseDown", function(self, button)
        if self.isUnlocked and button == "LeftButton" then
            self:StartMoving()
        end
    end)
    f:SetScript("OnMouseUp", function(self, button)
        if self.isUnlocked and button == "LeftButton" then
            self:StopMovingOrSizing()
            self.owner:SavePosition() 
        end
    end)

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

    -- [DYNAMIC ELEMENTS]
    -- Note: Initial anchors are set here, but UpdateLayout will override them instantly
    f.deathText = f:CreateFontString(nil, "OVERLAY")
    f.deathText:SetFont(FONT_FACE, SIZE_DEATH, FONT_FLAG)
    f.deathText:SetPoint("TOPRIGHT", f.upgradeText, "BOTTOMRIGHT", 0, -5)
    f.deathText:SetJustifyH("RIGHT")

    f.deathHitbox = CreateFrame("Frame", nil, f) 
    f.deathHitbox:SetHeight(SIZE_DEATH + 4)
    f.deathHitbox:SetWidth(150)
    f.deathHitbox:SetPoint("RIGHT", f.deathText, "RIGHT", -40, 0)

    f.affixText = f:CreateFontString(nil, "OVERLAY")
    f.affixText:SetFont(FONT_FACE, SIZE_AFFIX, FONT_FLAG)
    f.affixText:SetPoint("TOPRIGHT", f.deathText, "BOTTOMRIGHT", 0, -5)
    f.affixText:SetJustifyH("RIGHT")

    f.enemyBarContainer = CreateFrame("Frame", nil, f)
    f.enemyBarContainer:SetSize(270, 16)
    f.enemyBarContainer:SetPoint("TOPRIGHT", f.affixText, "BOTTOMRIGHT", 0, 0)
    
    f.enemyBarBG = f.enemyBarContainer:CreateTexture(nil, "BACKGROUND")
    f.enemyBarBG:SetAllPoints(f.enemyBarContainer)
    f.enemyBarBG:SetColorTexture(0, 0, 0, 1)

    f.enemyBar = CreateFrame("StatusBar", nil, f.enemyBarContainer)
    f.enemyBar:SetPoint("TOPLEFT", f.enemyBarContainer, "TOPLEFT", 0, 0)
    f.enemyBar:SetPoint("BOTTOMRIGHT", f.enemyBarContainer, "BOTTOMRIGHT", 0, 0)
    f.enemyBar:SetStatusBarTexture(BAR_TEXTURE)
    f.enemyBar:SetMinMaxValues(0, 100)

    f.enemyText = f.enemyBar:CreateFontString(nil, "OVERLAY")
    f.enemyText:SetFont(FONT_FACE, SIZE_BAR_TEXT, FONT_FLAG)
    f.enemyText:SetPoint("CENTER", f.enemyBar, "CENTER")

    f.bossContainer = CreateFrame("Frame", nil, f)
    f.bossContainer:SetSize(230, 200)
    f.bossContainer:SetPoint("TOPRIGHT", f.enemyBar, "BOTTOMRIGHT", 0, -15)

    self.mainFrame = f
    self.mainFrame.owner = self 
    
    self:RestorePosition()
    self:UpdateLayout() -- Ensure initial state is correct
end

function UIManager:SavePosition()
    local point, _, relativePoint, x, y = self.mainFrame:GetPoint()
    local config = Utils:GetConfig()
    config.position = { 
        point = point, 
        relativePoint = relativePoint, 
        x = x, 
        y = y 
    }
end

function UIManager:ResetPosition()
    local config = Utils:GetConfig()
    config.position = nil 
    self:RestorePosition() 
    print("|cff00ff00[NMT]|r Frame position reset to default.")
end

function UIManager:RestorePosition()
    if not self.mainFrame then return end
    
    local config = Utils:GetConfig()
    if config.position then
        self.mainFrame:ClearAllPoints()
        self.mainFrame:SetPoint(config.position.point, UIParent, config.position.relativePoint, config.position.x, config.position.y)
    else
        self.mainFrame:ClearAllPoints()
        local xOffset = GetSmartDefaultOffset()
        self.mainFrame:SetPoint("RIGHT", xOffset, 20)
    end
end

function UIManager:SetUnlocked(unlocked)
    self.mainFrame.isUnlocked = unlocked
    self.mainFrame:SetEnableMouse(unlocked)
    if unlocked then
        self.mainFrame:SetFrameStrata("DIALOG") 
        self.mainFrame.dragTex:Show()
        self.mainFrame:Show() 
        self.mainFrame.dungeonName:SetText("Drag to Move")
    else
        self.mainFrame:SetFrameStrata("MEDIUM") 
        self.mainFrame.dragTex:Hide()
        
        if not self.testMode and not self:IsInActiveRun() then 
            self.mainFrame:Hide() 
        else
            local mapInfo = self.dataManager:GetMapInfo()
            if mapInfo then self.mainFrame.dungeonName:SetText(mapInfo.name) end
        end
    end
end
local function ForceHideFrame(frame)
    if not frame then return end
    if frame.Hide then frame:Hide() end
    
    local mt = getmetatable(frame)
    if mt and mt.__index then
        if mt.__index.Hide then mt.__index.Hide(frame) end
        if mt.__index.SetAlpha then mt.__index.SetAlpha(frame, 0) end
    end
end

local function ForceShowFrame(frame)
    if not frame then return end
    local mt = getmetatable(frame)
    if mt and mt.__index then
        if mt.__index.Show then mt.__index.Show(frame) end
        if mt.__index.SetAlpha then mt.__index.SetAlpha(frame, 1) end
    end
    if frame.Show then frame:Show() end
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

    if ObjectiveTrackerFrame then ForceHideFrame(ObjectiveTrackerFrame) end
    if ScenarioBlocksFrame then ForceHideFrame(ScenarioBlocksFrame) end

    if C_AddOns.IsAddOnLoaded("!KalielsTracker") then
        local ktFrames = {
            _G["!KalielsTrackerFrame"],     
            _G["!KalielsTrackerFrameBackground"],
            _G["!KalielsTrackerScroll"],   
            _G["KT_ObjectiveTrackerFrame"],
            _G["KT_ScenarioObjectiveTracker"],
            _G["!KalielsTrackerHeaderButtons"] 
        }

        for _, frame in pairs(ktFrames) do
            ForceHideFrame(frame)
        end
    end
end

--- @param shouldHide boolean: True to hide the tracker, False to show it.
function UIManager:SetObjectiveTrackerState(shouldHide)
    
    if not shouldHide then
        if C_AddOns.IsAddOnLoaded("!KalielsTracker") then
            local ktFrames = {
                _G["!KalielsTrackerFrame"],
                _G["KT_ObjectiveTrackerFrame"],
                _G["KT_ScenarioObjectiveTracker"],
                _G["!KalielsTrackerScroll"],
                _G["!KalielsTrackerHeaderButtons"]
            }

            for _, frame in pairs(ktFrames) do
                ForceShowFrame(frame)
            end
            
            local KT = LibStub("MSA-AceAddon-3.0"):GetAddon("!KalielsTracker", true)
            if KT and KT.Update then KT:Update() end

        else
            if ObjectiveTrackerFrame then ForceShowFrame(ObjectiveTrackerFrame) end
        end
    end
end

function UIManager:HideKalielsTracker()
    self:SetObjectiveTrackerState(true)
end

function UIManager:ShowKalielsTracker()
    self:SetObjectiveTrackerState(false)
end
function UIManager:ShowPanel()
    self.mainFrame:Show()
    self:HideBlizzardUI()
    self:HideKalielsTracker()
end

function UIManager:HidePanel()
    if self.mainFrame.isUnlocked then return end
    self.mainFrame:Hide()
    self:RestoreBlizzardUI()
    self:ShowKalielsTracker()
end

-- [UPDATED] Visibility now respects the "hasAffix" check for cleaner logic
function UIManager:SetGameplayVisibility(show)
    self.mainFrame.upgradeText:SetShown(show)
    self.mainFrame.enemyBarContainer:SetShown(show)
    
    local showDeath = (self.showDeathInPanel or self.testMode)
    local hasAffix = (self.mainFrame.affixText:GetText() ~= "")

    self.mainFrame.deathText:SetShown(show and showDeath)
    self.mainFrame.deathHitbox:SetShown(show and showDeath)
    self.mainFrame.affixText:SetShown(show and hasAffix)
    self.mainFrame.bossContainer:SetShown(show)
end

function UIManager:UpdateRunConfig()
    local level = self.dataManager:GetActiveKeystoneLevel() or 0
    self.activeKeyLevel = level
    self.showDeathInPanel = (level > 3)
    
    -- [UPDATE] Config changed, recalculate layout
    self:UpdateLayout()
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
            
            local completionInfo = C_ChallengeMode.GetChallengeCompletionInfo()
            if completionInfo and completionInfo.time and completionInfo.time > 0 then
                self.isCompleted = true
                self.timerEngine:ForceFrozenTime(completionInfo.time / 1000)
                
                self:SetGameplayVisibility(true)
                self:UpdateScenarioInfo(0)
            else
                self.timerEngine:ResumeTimer(mapInfo.time) 
                self:AttemptCacheDungeonData()
            end

            self:UpdateAffixes()
            self.deathTracker:UpdateDeathCount()
            self:ShowPanel()
        end
    end
end

function UIManager:FullReset(force)
    local currentTime = self.timerEngine:GetAPITime()
    
    if force or currentTime == 0 then
        self.isCompleted = false
        local db = Utils:GetDB()
        db.bossKillTimes = {}
        
        self.activeKeyLevel = 0
        self.showDeathInPanel = false
        self.deathTracker:Reset()
        self.timerEngine:Reset()
        self.cachedDungeonTotal = 0 
        for _, frame in pairs(self.bossListFrames) do frame:Hide() end

        if self.mainFrame then
            self.mainFrame.enemyText:SetText("")
            self.mainFrame.enemyBar:SetValue(0)
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
        self:AttemptCacheDungeonData()
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
    local config = Utils:GetConfig()
    local affixString = DisplayFormatter:FormatAffixText(affixes, config)
    self.mainFrame.affixText:SetText(affixString)
    
    -- [UPDATE] Layout needs to know if affix is empty
    self:UpdateLayout()
end

function UIManager:OnUpdate(elapsed)
    if self.mainFrame.isUnlocked then return end
    if self.testMode then return end

    local _, _, difficultyID = GetInstanceInfo()
    if difficultyID ~= 8 then self:HidePanel() return end
    self:EnforceBlizzardUIHidden()

    local currentTime = self.timerEngine:GetAPITime()
    local isStarted = (currentTime > 0)
    local showPanel = (isStarted or self.isCompleted)
    self:SetGameplayVisibility(showPanel)
    
    if isStarted and self.activeKeyLevel == 0 then
        self:UpdateRunConfig()
    end

    if showPanel then
        local config = Utils:GetConfig()
        
        if not self.isCompleted and not self.timerEngine.running then
             local mapInfo = self.dataManager:GetMapInfo()
             if mapInfo then self.timerEngine:ResumeTimer(mapInfo.time) end
        end

        local current, remaining, total = self.timerEngine:GetTimeState()

        if total > 0 then
            self.mainFrame.timerText:SetText(DisplayFormatter:FormatTimerText(current, total, self.activeKeyLevel, config))

            local t2, t3 = self.timerEngine:GetThresholds()
            local r3, r2 = t3 - current, t2 - current
            self.mainFrame.upgradeText:SetText(DisplayFormatter:FormatUpgradeText(r2, r3, config))
        end

        self:UpdateScenarioInfo(elapsed)

        if self.mainFrame.deathText:IsShown() then
            local deathCount = self.deathTracker:GetDeathCount()
            local penalty = self.deathTracker:GetTotalTimePenalty()
            self.mainFrame.deathText:SetText(DisplayFormatter:FormatDeathText(deathCount, penalty, config))
        end
    else
        self.mainFrame.timerText:SetText(string.format("(+%d) Starting...", self.activeKeyLevel))
        self.mainFrame.upgradeText:SetText("")
    end
end

NS.UIManager = UIManager