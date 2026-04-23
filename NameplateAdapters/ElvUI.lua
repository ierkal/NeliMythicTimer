local _, NS = ...

NS.NameplateAdapters = NS.NameplateAdapters or {}
NS.NameplateAdapters.ElvUI = NS.Nameplates:MakeAdapter(
    "ElvUI",
    function() return _G.ElvUI ~= nil end,
    function(nameplate)
        -- ElvUI: unitFrame.Health (its StatusBar)
        if nameplate.unitFrame and nameplate.unitFrame.Health then
            return nameplate.unitFrame.Health
        end
        if nameplate.UnitFrame and nameplate.UnitFrame.healthBar then
            return nameplate.UnitFrame.healthBar
        end
        return nameplate
    end
)
