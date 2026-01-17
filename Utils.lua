local _, NS = ...

local Utils = {}

-- === DATABASE MANAGEMENT ===
function Utils:InitializeDB()
    if not _G["NeliMythicTimerDB"] then
        _G["NeliMythicTimerDB"] = {}
    end
    return _G["NeliMythicTimerDB"]
end

function Utils:GetDB()
    return _G["NeliMythicTimerDB"] or {}
end

function Utils:GetConfig()
    local db = self:GetDB()
    return db.config or {}
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

-- === COLOR HELPERS ===
function Utils:ColorText(text, r, g, b)
    local hex = string.format("%02x%02x%02x", r * 255, g * 255, b * 255)
    return string.format("|cff%s%s|r", hex, text)
end

function Utils:GreenText(text)
    return "|cff00ff00" .. text .. "|r"
end

function Utils:RedText(text)
    return "|cffff0000" .. text .. "|r"
end

function Utils:WhiteText(text)
    return "|cffffffff" .. text .. "|r"
end

function Utils:YellowText(text)
    return "|cffffff00" .. text .. "|r"
end

function Utils:GrayText(text)
    return "|cff808080" .. text .. "|r"
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
