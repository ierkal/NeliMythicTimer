local addonName, NS = ...

local Config = {}
Config.__index = Config

local Utils = NS.Utils

function Config:New(uiManager)
    local instance = setmetatable({}, Config)
    instance.uiManager = uiManager
    Utils:InitializeDB() 
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

    local lblGeneral = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    lblGeneral:SetPoint("TOPLEFT", 16, offsetY)
    lblGeneral:SetText("General Options")
    offsetY = offsetY - 25
    CreateCheckbox("Automatically insert Keystone", "autoInsertKey", panel)

    offsetY = offsetY - 10
    local lblData = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    lblData:SetPoint("TOPLEFT", 16, offsetY)
    lblData:SetText("Data & Display Options")
    offsetY = offsetY - 25
    CreateCheckbox("Show Boss Defeated Times", "showBossKillTimes", panel)
    CreateCheckbox("Show Enemy Forces Percent (%)", "showEnemyPercent", panel)
    CreateCheckbox("Show Enemy Forces Count (Absolute)", "showEnemyCount", panel)

    offsetY = offsetY - 20
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
    
    self.panel = panel

    local colorPanel = CreateFrame("Frame", "NeliMythicTimerColorPanel", UIParent)
    colorPanel.name = "Colors"
    colorPanel.parent = panel.name
    colorPanel:Hide()
    self:BuildColorControls(colorPanel)

    if Settings and Settings.RegisterCanvasLayoutCategory then
        local category = Settings.RegisterCanvasLayoutCategory(panel, panel.name)
        Settings.RegisterAddOnCategory(category)
        NS.SettingsCategory = category 
        local subcategory = Settings.RegisterCanvasLayoutSubcategory(category, colorPanel, "Colors")
    else
        InterfaceOptions_AddCategory(panel)
        InterfaceOptions_AddCategory(colorPanel)
    end
end

function Config:BuildColorControls(panel)
    local ui = self.uiManager
    local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, -16)
    title:SetText("Color Settings")
    
    local offsetY = -50
    local col1X = 16
    local col2X = 300

    local function CreateColorPicker(label, key, x, y)
        local f = CreateFrame("Button", nil, panel)
        f:SetSize(180, 24)
        f:SetPoint("TOPLEFT", x, y)
        
        f.swatch = f:CreateTexture(nil, "OVERLAY")
        f.swatch:SetSize(20, 20)
        f.swatch:SetPoint("LEFT", 2, 0)
        
        local c = _G["NeliMythicTimerDB"].config.colors[key]
        if not c then c = {r=1, g=1, b=1, a=1} end
        
        f.swatch:SetColorTexture(c.r, c.g, c.b, 1)
        
        f.label = f:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
        f.label:SetPoint("LEFT", f.swatch, "RIGHT", 8, 0)
        f.label:SetText(label)
        
        f:SetScript("OnClick", function()
            local info = {
                r = c.r, g = c.g, b = c.b, opacity = 1.0, hasOpacity = false,
                swatchFunc = function()
                    local r, g, b = ColorPickerFrame:GetColorRGB()
                    c.r, c.g, c.b = r, g, b
                    f.swatch:SetColorTexture(r, g, b, 1)
                    if ui then ui:RefreshConfig() end
                end,
                cancelFunc = function(restore)
                    c.r, c.g, c.b = restore.r, restore.g, restore.b
                    f.swatch:SetColorTexture(c.r, c.g, c.b, 1)
                    if ui then ui:RefreshConfig() end
                end
            }
            ColorPickerFrame:SetupColorPickerAndShow(info)
        end)

        local btnReset = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
        btnReset:SetSize(50, 20)
        btnReset:SetPoint("LEFT", f, "RIGHT", 5, 0)
        btnReset:SetText("Reset")
        btnReset:SetScript("OnClick", function()
            local defaultColor = Utils.DEFAULTS.colors[key]
            if defaultColor then
                c.r, c.g, c.b = defaultColor.r, defaultColor.g, defaultColor.b
                f.swatch:SetColorTexture(c.r, c.g, c.b, 1)
                if ui then ui:RefreshConfig() end
            end
        end)
        
        return y - 30
    end

    -- Column 1: Header & Timer
    offsetY = CreateColorPicker("Dungeon Name", "dungeonName", col1X, offsetY)
    offsetY = CreateColorPicker("Key Level Text (+10)", "keyLevel", col1X, offsetY)
    offsetY = offsetY - 10
    offsetY = CreateColorPicker("Timer Text (Normal)", "timerText", col1X, offsetY)
    offsetY = CreateColorPicker("Timer Text (Overtime)", "timerOvertime", col1X, offsetY)
    offsetY = offsetY - 10
    offsetY = CreateColorPicker("Upgrade (2 Chests)", "upgradeTwo", col1X, offsetY)
    offsetY = CreateColorPicker("Upgrade (3 Chests)", "upgradeThree", col1X, offsetY)
    offsetY = CreateColorPicker("Upgrade (Depleted)", "upgradeDepleted", col1X, offsetY)
    
    -- Reset Y for Column 2
    offsetY = -50
    
    -- Column 2: Enemy, Boss, Misc
    offsetY = CreateColorPicker("Enemy Bar Color", "enemyBar", col2X, offsetY)
    offsetY = CreateColorPicker("Enemy Text (Incomplete)", "enemyText", col2X, offsetY)
    offsetY = CreateColorPicker("Enemy Text (Complete)", "enemyTextComplete", col2X, offsetY)
    offsetY = offsetY - 10
    offsetY = CreateColorPicker("Boss Name (Alive)", "bossAlive", col2X, offsetY)
    offsetY = CreateColorPicker("Boss Name (Dead)", "bossDead", col2X, offsetY)
    offsetY = offsetY - 10
    offsetY = CreateColorPicker("Death Counter", "deathText", col2X, offsetY)
    offsetY = CreateColorPicker("Death Penalty Time", "deathPenalty", col2X, offsetY)
    offsetY = CreateColorPicker("Affixes", "affixText", col2X, offsetY)
end

NS.Config = Config