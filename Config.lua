local addonName, NS = ...

local Config = {}
Config.__index = Config

local Utils = NS.Utils

local DEFAULTS = {
    autoInsertKey = true,
    showBossKillTimes = true,
    showEnemyPercent = true,
    showEnemyCount = true,
    scale = 1.0
}

function Config:New(uiManager)
    local instance = setmetatable({}, Config)
    instance.uiManager = uiManager
    
    local globalDB = Utils:InitializeDB()
    if not globalDB.config then globalDB.config = {} end
    
    local db = globalDB.config
    -- cleanup old keys if necessary or just ignore them
    for k, v in pairs(DEFAULTS) do
        if db[k] == nil then db[k] = v end
    end

    instance:BuildPanel()
    return instance
end

function Config:BuildPanel()
    local panel = CreateFrame("Frame", "NeliMythicTimerConfigPanel", UIParent)
    panel.name = "NeliMythicTimer"
    panel:Hide()
    
    local ui = self.uiManager
    local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, -16)
    title:SetText("NeliMythicTimer Options")

    local offsetY = -50

    local function CreateCheckbox(label, key, parent)
        local cb = CreateFrame("CheckButton", nil, parent, "InterfaceOptionsCheckButtonTemplate")
        cb:SetPoint("TOPLEFT", 16, offsetY)
        cb.Text:SetText(label)
        cb:SetChecked(_G["NeliMythicTimerDB"].config[key])
        cb:SetScript("OnClick", function(btn)
            _G["NeliMythicTimerDB"].config[key] = btn:GetChecked()
            if ui then ui:RefreshConfig() end
        end)
        offsetY = offsetY - 30
        return cb
    end

    -- General Options
    local lblGeneral = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    lblGeneral:SetPoint("TOPLEFT", 16, offsetY)
    lblGeneral:SetText("General Options")
    offsetY = offsetY - 25
    
    CreateCheckbox("Automatically insert Keystone", "autoInsertKey", panel)
    -- Removed Tooltip and Nameplate checkboxes

    offsetY = offsetY - 10

    -- Data Options
    local lblData = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    lblData:SetPoint("TOPLEFT", 16, offsetY)
    lblData:SetText("Data & Display Options")
    offsetY = offsetY - 25
    
    CreateCheckbox("Show Boss Defeated Times", "showBossKillTimes", panel)
    -- Removed Show Current Pull Progress (Ghost Bar) checkbox
    CreateCheckbox("Show Enemy Forces Percent (%)", "showEnemyPercent", panel)
    CreateCheckbox("Show Enemy Forces Count (Absolute)", "showEnemyCount", panel)

    offsetY = offsetY - 20

    -- Scale Slider
    local slider = CreateFrame("Slider", "NMT_ScaleSlider", panel, "OptionsSliderTemplate")
    slider:SetPoint("TOPLEFT", 20, offsetY)
    slider:SetMinMaxValues(0.5, 2.0)
    slider:SetValue(_G["NeliMythicTimerDB"].config.scale)
    slider:SetWidth(200)
    _G[slider:GetName() .. "Text"]:SetText("UI Scale: " .. string.format("%.1f", _G["NeliMythicTimerDB"].config.scale))
    slider:SetScript("OnValueChanged", function(_, value)
        value = math.floor(value * 10 + 0.5) / 10
        _G["NeliMythicTimerDB"].config.scale = value
        _G[slider:GetName() .. "Text"]:SetText("UI Scale: " .. string.format("%.1f", value))
        if ui then ui:ApplyScale(value) end
    end)

    offsetY = offsetY - 50

    -- Action Buttons
    local btnReload = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    btnReload:SetSize(120, 25) 
    btnReload:SetPoint("TOPLEFT", 16, offsetY)
    btnReload:SetText("Reload UI")
    btnReload:SetScript("OnClick", C_UI.Reload)

    local btnDemo = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    btnDemo:SetSize(150, 25) 
    btnDemo:SetPoint("LEFT", btnReload, "RIGHT", 10, 0)
    btnDemo:SetText("Toggle Demo Mode")
    btnDemo:SetScript("OnClick", function() if ui then ui:ToggleTestMode() end end)

    if Settings and Settings.RegisterCanvasLayoutCategory then
        local category = Settings.RegisterCanvasLayoutCategory(panel, panel.name)
        Settings.RegisterAddOnCategory(category)
        NS.SettingsCategory = category 
    else
        InterfaceOptions_AddCategory(panel)
    end
    
    self.panel = panel
end

NS.Config = Config