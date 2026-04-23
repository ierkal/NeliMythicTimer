local _, NS = ...

local TooltipAugment = {}

local Utils = NS.Utils
local issecretvalue = issecretvalue or function() return false end

function TooltipAugment:Init()
    if not TooltipDataProcessor or not Enum or not Enum.TooltipDataType then return end
    TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Unit, function(tooltip, data)
        self:OnTooltipSetUnit(tooltip, data)
    end)
end

function TooltipAugment:OnTooltipSetUnit(tooltip, data)
    local config = Utils:GetConfig()
    if config.showTooltipForces == false then return end
    if not Utils:IsInMythicPlus() then return end

    local info = NS.PullTracker:GetUnitForcesInfo("mouseover")
    if not info or info.pctStr == nil then return end

    local c = (config.colors and config.colors.pullPreviewText) or { r = 0, g = 1, b = 0, a = 1 }

    -- AddLine a placeholder, then rewrite the resulting FontString via
    -- SetFormattedText. This keeps label and value on the same line (AddDoubleLine
    -- would right-align the value with a big gap) and lets SecretValue pctStr
    -- flow through Blizzard's C-side formatter without Lua-side concat/taint.
    tooltip:AddLine(" ")
    local tipName = tooltip:GetName()
    local fs = tipName and _G[tipName .. "TextLeft" .. tooltip:NumLines()]
    if fs then
        if pcall(fs.SetFormattedText, fs, "[NMT] +%s%%", info.pctStr) then
            fs:SetTextColor(c.r, c.g, c.b, c.a or 1)
        end
    end
    tooltip:Show()
end

NS.TooltipAugment = TooltipAugment
