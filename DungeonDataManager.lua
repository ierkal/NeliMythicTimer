local _, NS = ...

local DungeonDataManager = {}
DungeonDataManager.__index = DungeonDataManager

function DungeonDataManager:New()
    local instance = setmetatable({}, DungeonDataManager)
    
    -- Hardcoded forces values
    instance.forcesData = {
        
    }
    
    return instance
end

-- Automatically get the list of Map IDs for the current season
function DungeonDataManager:GetSeasonMaps()
    return C_ChallengeMode.GetMapTable()
end

function DungeonDataManager:GetDungeonForces()
    -- Always use Blizzard's totalQuantity for consistency with quantityString
    local _, _, numCriteria = C_Scenario.GetStepInfo()
    for i = 1, (numCriteria or 0) do
        local info = C_ScenarioInfo.GetCriteriaInfo(i)
        if info and info.isWeightedProgress and info.totalQuantity > 0 then
            return info.totalQuantity
        end
    end

    return 0
end

function DungeonDataManager:GetMapInfo()
    local mapID = C_ChallengeMode.GetActiveChallengeMapID()
    if not mapID then return nil end

    local name, _, timeLimit = C_ChallengeMode.GetMapUIInfo(mapID)
    -- Fixed: Accessing .forces property here as well
    local forces = (self.forcesData[mapID] and self.forcesData[mapID].forces) or 0
    
    return {
        name = name or "Unknown Dungeon",
        time = timeLimit or 1800,
        mapID = mapID,
        forces = forces
    }
end

function DungeonDataManager:GetActiveKeystoneLevel()
    local level = C_ChallengeMode.GetActiveKeystoneInfo()
    return level or 0
end

function DungeonDataManager:GetAffixes()
    -- GetActiveKeystoneInfo returns: level, affixIDs (table), charged
    local level, affixIDs = C_ChallengeMode.GetActiveKeystoneInfo()
    local affixes = {}

    if affixIDs and type(affixIDs) == "table" then
        for _, affixID in ipairs(affixIDs) do
            -- Usage: local name, description, filedataid = C_ChallengeMode.GetAffixInfo(affixID)
            local name = C_ChallengeMode.GetAffixInfo(affixID)
            if name then
                table.insert(affixes, name)
            end
        end
    end
    
    return affixes
end

NS.DungeonDataManager = DungeonDataManager