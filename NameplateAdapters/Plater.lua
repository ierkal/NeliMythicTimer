local _, NS = ...

NS.NameplateAdapters = NS.NameplateAdapters or {}
NS.NameplateAdapters.Plater = NS.Nameplates:MakeAdapter(
    "Plater",
    function() return _G.Plater ~= nil end,
    function(nameplate)
        -- Plater uses lowercase `unitFrame`; its healthbar lives at `.healthBar`.
        local uf = nameplate.unitFrame or nameplate.UnitFrame
        if uf and uf.healthBar then return uf.healthBar end
        return nameplate
    end
)
