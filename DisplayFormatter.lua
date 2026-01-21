local _, NS = ...

local DisplayFormatter = {}
local Utils = NS.Utils

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
    
    -- Check completion for color
    local color = config.colors.enemyText
    if killedPercent >= 100 then
        color = config.colors.enemyTextComplete
    end
    
    return Utils:ColorString(displayText, color), killedPercent
end

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
    
    return Utils:ColorString(displayText, config.colors.enemyTextComplete)
end

-- === BOSS DISPLAY ===
function DisplayFormatter:FormatBossLine(bossName, isCompleted, killTime, config)
    if not isCompleted then
        return Utils:ColorString(bossName, config.colors.bossAlive)
    end
    
    local deadColor = config.colors.bossDead
    if config.showBossKillTimes and killTime then
        local timeStr = (killTime == -1) and "--:--" or Utils:FormatTime(killTime)
        return Utils:ColorString(string.format("[%s] %s", timeStr, bossName), deadColor)
    else
        return Utils:ColorString(bossName, deadColor)
    end
end

-- === TIMER DISPLAY ===
function DisplayFormatter:FormatTimerText(currentTime, totalTime, keyLevel, config)
    local timerColor = (currentTime > totalTime) and config.colors.timerOvertime or config.colors.timerText
    local timerHex = Utils:RGBToHex(timerColor)
    
    local keyColor = config.colors.keyLevel or {r=1, g=1, b=1}
    local keyHex = Utils:RGBToHex(keyColor)
    
    return string.format("%s(+%d)|r %s%s / %s|r", 
        keyHex,
        keyLevel, 
        timerHex, 
        Utils:FormatTime(currentTime), 
        Utils:FormatTime(totalTime))
end

function DisplayFormatter:FormatUpgradeText(remainingForTwo, remainingForThree, config)
    local colorTwo = (remainingForTwo > 0) and Utils:RGBToHex(config.colors.upgradeTwo) or Utils:RGBToHex(config.colors.upgradeDepleted)
    local colorThree = (remainingForThree > 0) and Utils:RGBToHex(config.colors.upgradeThree) or Utils:RGBToHex(config.colors.upgradeDepleted)
    
    return string.format("%s%s|r  %s%s|r",
        colorThree, Utils:FormatTime(math.max(0, remainingForThree)),
        colorTwo, Utils:FormatTime(math.max(0, remainingForTwo)))
end

-- === DEATH DISPLAY ===
function DisplayFormatter:FormatDeathText(deathCount, timePenalty, config)
    local txtColor = Utils:RGBToHex(config.colors.deathText)
    local penaltyColor = Utils:RGBToHex(config.colors.deathPenalty)
    
    if deathCount > 0 then
        return string.format("%s%d Deaths|r %s(-%ds)|r", txtColor, deathCount, penaltyColor, timePenalty)
    else
        return string.format("%s0 Deaths|r", txtColor)
    end
end

-- === AFFIX DISPLAY ===
function DisplayFormatter:FormatAffixText(affixes, config)
    local affixString = table.concat(affixes, ", ")
    return Utils:ColorString(affixString, config.colors.affixText)
end

-- === DEMO DATA ===
function DisplayFormatter:GetDemoEnemyData()
    return {
        killedPercent = 12.0,
        totalCount = 300,
        rawKilled = 36,
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