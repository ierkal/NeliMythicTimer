local _, NS = ...

local Nameplates = {}

local Constants = NS.Constants
local activeAdapter = nil

function Nameplates:Init()
    -- 2s delay gives other addons (Plater, ElvUI, etc.) time to register globals.
    C_Timer.After(2, function() self:DetectAdapter() end)
end

function Nameplates:DetectAdapter()
    local adapters = NS.NameplateAdapters or {}
    if adapters.Plater and adapters.Plater:IsAvailable() then
        activeAdapter = adapters.Plater
    elseif adapters.ElvUI and adapters.ElvUI:IsAvailable() then
        activeAdapter = adapters.ElvUI
    elseif adapters.Platynator and adapters.Platynator:IsAvailable() then
        activeAdapter = adapters.Platynator
    elseif adapters.RyoUI and adapters.RyoUI:IsAvailable() then
        activeAdapter = adapters.RyoUI
    elseif adapters.ThreatPlates and adapters.ThreatPlates:IsAvailable() then
        activeAdapter = adapters.ThreatPlates
    else
        activeAdapter = adapters.Blizzard
    end
    if activeAdapter and activeAdapter.Init then activeAdapter:Init() end
    self:RefreshAll()
end

function Nameplates:GetActiveAdapterName()
    if not activeAdapter then return "none" end
    return activeAdapter.name or "unknown"
end

function Nameplates:ShouldShow()
    local Utils = NS.Utils
    local config = Utils:GetConfig()
    if config.showNameplateForces == false then return false end
    if not Utils:IsInMythicPlus() then return false end
    return true
end

function Nameplates:OnNameplateAdded(unitToken)
    if not activeAdapter then return end
    if not self:ShouldShow() then
        if activeAdapter.OnNameplateRemoved then
            activeAdapter:OnNameplateRemoved(unitToken)
        end
        return
    end
    if activeAdapter.OnNameplateAdded then
        activeAdapter:OnNameplateAdded(unitToken)
    end
end

function Nameplates:OnNameplateRemoved(unitToken)
    if activeAdapter and activeAdapter.OnNameplateRemoved then
        activeAdapter:OnNameplateRemoved(unitToken)
    end
end

function Nameplates:RefreshAll()
    for i = 1, 40 do
        local unit = "nameplate" .. i
        if UnitExists(unit) then self:OnNameplateAdded(unit) end
    end
end

-- Shared helpers used by every adapter.

function Nameplates:ApplyOverlayText(fs, info)
    if not fs or not info then return end
    if pcall(fs.SetFormattedText, fs, "%s%%", info.pctStr) then return end
    if pcall(fs.SetText, fs, info.pctStr) then return end
    fs:SetText("")
end

function Nameplates:ApplyOverlayStyle(fs)
    local c = (NS.Utils:GetConfig().colors and NS.Utils:GetConfig().colors.pullPreviewText)
           or { r = 0, g = 1, b = 0, a = 1 }
    if not pcall(fs.SetFont, fs, Constants.FONT_FACE, 14, "OUTLINE") then
        fs:SetFont("Fonts\\FRIZQT__.TTF", 14, "OUTLINE")
    end
    fs:SetTextColor(c.r, c.g, c.b, c.a or 1)
end

-- Factory used by every adapter file. Each adapter supplies its own IsAvailable
-- predicate and an anchor resolver that returns the healthbar frame to parent to.
function Nameplates:MakeAdapter(name, isAvailable, getAnchor)
    local adapter = { name = name }
    local overlays = {}

    function adapter:IsAvailable() return isAvailable() end
    function adapter:Init() end

    function adapter:OnNameplateAdded(unitToken)
        if not self:IsAvailable() then return end
        local nameplate = C_NamePlate.GetNamePlateForUnit(unitToken)
        if not nameplate then return end
        local info = NS.PullTracker:GetUnitForcesInfo(unitToken)
        if not info then
            local fs = overlays[nameplate]
            if fs then fs:Hide() end
            return
        end

        local anchor = (getAnchor and getAnchor(nameplate)) or nameplate
        local fs = overlays[nameplate]
        -- Re-parent if the nameplate rebuilt its frames (ElvUI does this).
        if fs and fs:GetParent() ~= anchor then
            fs:Hide()
            fs = nil
            overlays[nameplate] = nil
        end
        if not fs then
            fs = anchor:CreateFontString(nil, "OVERLAY")
            overlays[nameplate] = fs
        end

        Nameplates:ApplyOverlayStyle(fs)
        fs:ClearAllPoints()
        fs:SetPoint("BOTTOM", anchor, "TOP", 0, 2)
        Nameplates:ApplyOverlayText(fs, info)
        fs:Show()
    end

    function adapter:OnNameplateRemoved(unitToken)
        local nameplate = C_NamePlate.GetNamePlateForUnit(unitToken)
        if nameplate and overlays[nameplate] then
            overlays[nameplate]:Hide()
        end
    end

    return adapter
end

local bootFrame = CreateFrame("Frame")
bootFrame:RegisterEvent("PLAYER_LOGIN")
bootFrame:SetScript("OnEvent", function(self)
    self:UnregisterEvent("PLAYER_LOGIN")
    local ef = CreateFrame("Frame")
    ef:RegisterEvent("NAME_PLATE_UNIT_ADDED")
    ef:RegisterEvent("NAME_PLATE_UNIT_REMOVED")
    ef:RegisterEvent("PLAYER_ENTERING_WORLD")
    ef:SetScript("OnEvent", function(_, event, ...)
        if event == "NAME_PLATE_UNIT_ADDED" then
            Nameplates:OnNameplateAdded(...)
        elseif event == "NAME_PLATE_UNIT_REMOVED" then
            Nameplates:OnNameplateRemoved(...)
        elseif event == "PLAYER_ENTERING_WORLD" then
            C_Timer.After(1, function() Nameplates:DetectAdapter() end)
        end
    end)

    -- Re-scan periodically to catch nameplates missed on first display and to
    -- keep overlay text fresh as forces values change (boss phases, etc).
    C_Timer.NewTicker(1.5, function()
        if Nameplates:ShouldShow() then Nameplates:RefreshAll() end
    end)
end)

NS.Nameplates = Nameplates
NS.NameplateAdapters = NS.NameplateAdapters or {}
