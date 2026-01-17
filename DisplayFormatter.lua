local _, NS = ...

-- ===================================
-- DisplayFormatter Module
-- Handles text/data formatting for UI
-- ===================================

local DisplayFormatter = {}
local Utils = NS.Utils
local Constants = NS.Constants

-- === ENEMY FORCES DISPLAY ===
function DisplayFormatter:FormatEnemyForces(rawKilled, totalCount, config)
    local killedPercent = (rawKilled / totalCount) * 100
    
    local parts = {}
    if config.showEnemyCount then
        table.insert(parts, string.format("%d/%d", rawKilled, totalCount))
    end
    if config.showEnemyPercent then
        table.insert(parts, string.format("%.2f%%", killedPercent))
    end
    
    local displayText = table.concat(parts, " - ")
    if displayText == "" then
        displayText = string.format("%.2f%%", killedPercent)
    end
    
    return displayText, killedPercent
end

-- Removed FormatPullProgress

function DisplayFormatter:FormatCompletedEnemyForces(dungeonTotal, config)
    local parts = {}
    if config.showEnemyCount then
        table.insert(parts, string.format("%d/%d", dungeonTotal, dungeonTotal))
    end
    if config.showEnemyPercent then
        table.insert(parts, "100.00%")
    end
    
    local displayText = table.concat(parts, " - ")
    if displayText == "" then
        displayText = "100.00%"
    end
    
    return displayText
end

-- === BOSS DISPLAY ===
function DisplayFormatter:FormatBossLine(bossName, isCompleted, killTime, config)
    if not isCompleted then
        return Utils:WhiteText(bossName)
    end
    
    if config.showBossKillTimes and killTime then
        local timeStr = (killTime == -1) and "--:--" or Utils:FormatTime(killTime)
        return Utils:GreenText(string.format("[%s] %s", timeStr, bossName))
    else
        return Utils:GreenText(bossName)
    end
end

-- === TIMER DISPLAY ===
function DisplayFormatter:FormatTimerText(currentTime, totalTime, keyLevel)
    local timerColor = (currentTime > totalTime) and "|cffff0000" or "|cffffffff"
    return string.format("(+%d) %s%s / %s|r", 
        keyLevel, 
        timerColor, 
        Utils:FormatTime(currentTime), 
        Utils:FormatTime(totalTime))
end

function DisplayFormatter:FormatUpgradeText(remainingForTwo, remainingForThree)
    local colorTwo = (remainingForTwo > 0) and "|cffffff00" or "|cff808080"
    local colorThree = (remainingForThree > 0) and "|cffffff00" or "|cff808080"
    
    return string.format("%s%s|r  %s%s|r",
        colorThree, Utils:FormatTime(math.max(0, remainingForThree)),
        colorTwo, Utils:FormatTime(math.max(0, remainingForTwo)))
end

-- === DEATH DISPLAY ===
function DisplayFormatter:FormatDeathText(deathCount, timePenalty)
    if deathCount > 0 then
        return string.format("|cffffffff%d Deaths|r |cffff0000(-%ds)|r", deathCount, timePenalty)
    else
        return "|cffffffff0 Deaths|r"
    end
end

-- === AFFIX DISPLAY ===
function DisplayFormatter:FormatAffixText(affixes)
    local affixString = ""
    for i, affix in ipairs(affixes) do
        if i == 1 then
            affixString = affix
        else
            affixString = affixString .. ", " .. affix
        end
    end
    return affixString
end

-- === DEMO DATA ===
function DisplayFormatter:GetDemoEnemyData()
    return {
        killedPercent = 12.0,
        totalCount = 300,
        rawKilled = 36,
        -- Removed pull info from demo data
    }
end

function DisplayFormatter:GetDemoBosses()
    return {
        { name = "First Boss", time = "12:40", completed = true },
        { name = "Second Boss", completed = false },
        { name = "Third Boss", completed = false },
    }
end

NS.DisplayFormatter = DisplayFormatter