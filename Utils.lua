local _, NS = ...

local Utils = {}

-- === DEFAULTS (Publicly Accessible) ===
Utils.DEFAULTS = {
    autoInsertKey = true,
    showBossKillTimes = true,
    showEnemyPercent = true,
    showEnemyCount = true,
    scale = 1.0,
    colors = {
        -- Header Info
        dungeonName = {r=1, g=1, b=1, a=1}, -- Default: White
        keyLevel = {r=1, g=1, b=1, a=1},       -- Default: White
        
        -- Timer
        timerText = {r=1, g=1, b=1, a=1},
        timerOvertime = {r=1, g=0, b=0, a=1},
        
        -- Upgrades
        upgradeTwo = {r=1, g=1, b=0, a=1},
        upgradeThree = {r=1, g=1, b=0, a=1},
        upgradeDepleted = {r=0.5, g=0.5, b=0.5, a=1},
        
        -- Enemy Forces
        enemyBar = {r=0.45, g=0.0, b=0.85, a=1},
        enemyText = {r=1, g=1, b=1, a=1},
        enemyTextComplete = {r=0, g=1, b=0, a=1},
        
        -- Bosses
        bossAlive = {r=1, g=1, b=1, a=1},
        bossDead = {r=0, g=1, b=0, a=1},
        
        -- Misc
        deathText = {r=1, g=1, b=1, a=1},
        deathPenalty = {r=1, g=0, b=0, a=1},
        affixText = {r=0.5, g=0.5, b=0.5, a=1},
    }
}

-- === DATABASE MANAGEMENT ===
function Utils:InitializeDB()
    if not _G["NeliMythicTimerDB"] then
        _G["NeliMythicTimerDB"] = {}
    end
    
    local db = _G["NeliMythicTimerDB"]
    if not db.config then db.config = {} end

    -- Recursive merge for defaults
    local function MergeDefaults(src, dst)
        for k, v in pairs(src) do
            if type(v) == "table" then
                if dst[k] == nil then dst[k] = {} end
                MergeDefaults(v, dst[k])
            elseif dst[k] == nil then
                dst[k] = v
            end
        end
    end
    
    MergeDefaults(self.DEFAULTS, db.config)
    
    return db
end

function Utils:GetDB()
    return self:InitializeDB()
end

function Utils:GetConfig()
    return self:InitializeDB().config
end

-- === COLOR HELPERS ===
function Utils:RGBToHex(r, g, b)
    if not r then return "|cffffffff" end -- Fallback
    if type(r) == "table" then
        g = r.g
        b = r.b
        r = r.r
    end
    return string.format("|cff%02x%02x%02x", (r or 1) * 255, (g or 1) * 255, (b or 1) * 255)
end

function Utils:ColorString(text, colorTable)
    if not colorTable then return text end
    local hex = self:RGBToHex(colorTable)
    return hex .. text .. "|r"
end

-- === NPC ID EXTRACTION ===
function Utils:GetNPCIDFromGUID(guid)
    if not guid then return nil end
    local _, _, _, _, _, npcID = strsplit("-", guid)
    return tonumber(npcID)
end

-- === TIME FORMATTING ===
function Utils:FormatTime(seconds)
    local m = math.floor(seconds / 60)
    local s = math.floor(seconds % 60)
    return string.format("%d:%02d", m, s)
end

-- === UNIT CHECKS ===
function Utils:IsPlayer(unit)
    return unit and UnitIsPlayer(unit)
end

function Utils:IsInMythicPlus()
    local _, _, difficultyID = GetInstanceInfo()
    return difficultyID == 8
end

function Utils:IsInPartyInstance()
    local _, instanceType = GetInstanceInfo()
    return instanceType == "party"
end

NS.Utils = Utils