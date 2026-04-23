local _, NS = ...

NS.NameplateAdapters = NS.NameplateAdapters or {}
NS.NameplateAdapters.Blizzard = NS.Nameplates:MakeAdapter(
    "Blizzard",
    function() return true end,
    function(nameplate)
        if nameplate.UnitFrame and nameplate.UnitFrame.healthBar then
            return nameplate.UnitFrame.healthBar
        end
        return nameplate
    end
)
