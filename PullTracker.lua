local _, NS = ...

-- PullTracker reads per-unit forces via C_ScenarioInfo.GetUnitCriteriaProgressValues.
-- In Midnight M+ these return SecretValues. From tainted (addon) code we can
-- pass them through to SetText/SetFormattedText/AddDoubleLine, but any
-- arithmetic taints — including SecretValue+SecretValue. So we cannot produce
-- a summed numeric preview for multi-mob pulls.
--
-- Single-mob pulls get a pass-through "+V(P%)" suffix; anything larger gets
-- only the ghost bar (no text), since we can't display a meaningful total.
local PullTracker = {}

function PullTracker:GetUnitForcesInfo(unitToken)
    if not unitToken or not UnitExists(unitToken) then return nil end
    if not C_ScenarioInfo or not C_ScenarioInfo.GetUnitCriteriaProgressValues then return nil end
    local ok, value, percent, pctStr = pcall(C_ScenarioInfo.GetUnitCriteriaProgressValues, unitToken)
    if not ok or pctStr == nil then return nil end
    return { value = value, percent = percent, pctStr = pctStr }
end

local function IsHostileEngaged(unit)
    return UnitExists(unit)
       and not UnitIsDead(unit)
       and UnitCanAttack("player", unit)
       and UnitAffectingCombat(unit)
end

-- Returns:
--   unit     : { value, pctStr } of the single engaged mob, or nil when
--              pull is empty OR has more than one mob (no meaningful text then).
--   mobCount : plain int of ALL engaged forces mobs.
function PullTracker:GetPullPreview(dungeonTotal)
    local result = { unit = nil, mobCount = 0 }
    local firstInfo = nil

    for i = 1, 40 do
        local unit = "nameplate" .. i
        if IsHostileEngaged(unit) then
            local info = self:GetUnitForcesInfo(unit)
            if info and info.value ~= nil then
                result.mobCount = result.mobCount + 1
                if not firstInfo then firstInfo = info end
            end
        end
    end

    if result.mobCount == 1 then
        result.unit = { value = firstInfo.value, pctStr = firstInfo.pctStr }
    end

    return result
end

NS.PullTracker = PullTracker
