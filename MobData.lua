local _, NS = ...

NS.MobData = {}

function NS.MobData:GetMobValue(npcID)
    -- Use MDT (Mythic Dungeon Tools) for mob force values
    if MDT and MDT.GetEnemyForces then
        local mdtValue = MDT:GetEnemyForces(npcID)
        if mdtValue and mdtValue > 0 then
            return mdtValue
        end
    end

    return 0
end
