local _, NS = ...

NS.NameplateAdapters = NS.NameplateAdapters or {}
NS.NameplateAdapters.Platynator = NS.Nameplates:MakeAdapter(
    "Platynator",
    function() return _G.Platynator ~= nil end,
    function(nameplate)
        if nameplate.UnitFrame and nameplate.UnitFrame.healthBar then
            return nameplate.UnitFrame.healthBar
        end
        return nameplate
    end
)
