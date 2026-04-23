local _, NS = ...

NS.NameplateAdapters = NS.NameplateAdapters or {}
NS.NameplateAdapters.ThreatPlates = NS.Nameplates:MakeAdapter(
    "ThreatPlates",
    function() return _G.TidyPlatesThreat ~= nil end,
    function(nameplate)
        -- ThreatPlates: TPFrame.visual.healthbar
        if nameplate.TPFrame and nameplate.TPFrame.visual and nameplate.TPFrame.visual.healthbar then
            return nameplate.TPFrame.visual.healthbar
        end
        if nameplate.UnitFrame and nameplate.UnitFrame.healthBar then
            return nameplate.UnitFrame.healthBar
        end
        return nameplate
    end
)
