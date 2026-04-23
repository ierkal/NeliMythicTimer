local _, NS = ...

NS.NameplateAdapters = NS.NameplateAdapters or {}
NS.NameplateAdapters.RyoUI = NS.Nameplates:MakeAdapter(
    "RyoUI",
    function() return _G.RyoUI ~= nil end,
    function(nameplate)
        -- RyoUI: nameplate.healthbar (lowercase)
        if nameplate.healthbar then return nameplate.healthbar end
        if nameplate.UnitFrame and nameplate.UnitFrame.healthBar then
            return nameplate.UnitFrame.healthBar
        end
        return nameplate
    end
)
