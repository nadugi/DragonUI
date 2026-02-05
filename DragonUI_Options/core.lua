--[[
================================================================================
DragonUI Options - Core
================================================================================
This file provides the options registration system and initialization.
Based on ElvUI_OptionsUI pattern - accesses DragonUI addon via global.
================================================================================
]]

-- Access the main DragonUI addon (exposed globally in DragonUI/core.lua)
local addon = DragonUI
if not addon then
    print("|cFFFF0000[DragonUI_Options]|r Error: DragonUI addon not found!")
    return
end

-- ============================================================================
-- STATIC POPUP FOR RELOAD
-- ============================================================================

StaticPopupDialogs["DRAGONUI_RELOAD_UI"] = {
    text = "Changing this setting requires a UI reload to apply correctly.",
    button1 = "Reload UI",
    button2 = "Not Now",
    OnAccept = function()
        ReloadUI()
    end,
    timeout = 0,
    whileDead = 1,
    hideOnEscape = 1,
    preferredIndex = 3
}

-- ============================================================================
-- REGISTRATION FUNCTION (for backwards compatibility with option files)
-- ============================================================================

-- Register an options group directly to addon.Options.args
function addon:RegisterOptionsGroup(name, optionsTable, order)
    if not addon.Options then
        addon.Options = { type = "group", name = "DragonUI", args = {} }
    end
    
    addon.Options.args[name] = optionsTable
    if order then
        addon.Options.args[name].order = order
    end
end

-- ============================================================================
-- UTILITY FUNCTIONS FOR OPTIONS (available to all option files)
-- ============================================================================

-- Create a toggle option with standard format
function addon:CreateToggleOption(info)
    return {
        type = 'toggle',
        name = info.name,
        desc = info.desc,
        order = info.order or 1,
        width = info.width or nil,
        get = function()
            if info.getFunc then
                return info.getFunc()
            elseif info.dbPath then
                local path = {strsplit(".", info.dbPath)}
                local value = addon.db.profile
                for _, key in ipairs(path) do
                    value = value and value[key]
                end
                return value
            end
            return false
        end,
        set = function(_, val)
            if info.setFunc then
                info.setFunc(val)
            elseif info.dbPath then
                local path = {strsplit(".", info.dbPath)}
                local target = addon.db.profile
                for i = 1, #path - 1 do
                    target = target[path[i]]
                end
                target[path[#path]] = val
            end
            if info.refresh then
                info.refresh()
            end
            if info.requiresReload then
                StaticPopup_Show("DRAGONUI_RELOAD_UI")
            end
        end,
        disabled = info.disabled
    }
end

-- Create a slider option with standard format
function addon:CreateSliderOption(info)
    return {
        type = 'range',
        name = info.name,
        desc = info.desc,
        order = info.order or 1,
        min = info.min or 0,
        max = info.max or 1,
        step = info.step or 0.01,
        isPercent = info.isPercent or false,
        width = info.width or nil,
        get = function()
            if info.getFunc then
                return info.getFunc()
            elseif info.dbPath then
                local path = {strsplit(".", info.dbPath)}
                local value = addon.db.profile
                for _, key in ipairs(path) do
                    value = value and value[key]
                end
                return value or info.default or 1
            end
            return info.default or 1
        end,
        set = function(_, val)
            if info.setFunc then
                info.setFunc(val)
            elseif info.dbPath then
                local path = {strsplit(".", info.dbPath)}
                local target = addon.db.profile
                for i = 1, #path - 1 do
                    target = target[path[i]]
                end
                target[path[#path]] = val
            end
            if info.refresh then
                info.refresh()
            end
        end
    }
end

-- Create a color picker option
function addon:CreateColorOption(info)
    return {
        type = 'color',
        name = info.name,
        desc = info.desc,
        order = info.order or 1,
        hasAlpha = info.hasAlpha or false,
        get = function()
            if info.getFunc then
                return info.getFunc()
            elseif info.dbPath then
                local path = {strsplit(".", info.dbPath)}
                local value = addon.db.profile
                for _, key in ipairs(path) do
                    value = value and value[key]
                end
                if value then
                    return value.r, value.g, value.b, value.a
                end
            end
            return 1, 1, 1, 1
        end,
        set = function(_, r, g, b, a)
            if info.setFunc then
                info.setFunc(r, g, b, a)
            elseif info.dbPath then
                local path = {strsplit(".", info.dbPath)}
                local target = addon.db.profile
                for i = 1, #path - 1 do
                    target = target[path[i]]
                end
                target[path[#path]] = { r = r, g = g, b = b, a = a }
            end
            if info.refresh then
                info.refresh()
            end
        end
    }
end

-- Create a select/dropdown option
function addon:CreateSelectOption(info)
    return {
        type = 'select',
        name = info.name,
        desc = info.desc,
        order = info.order or 1,
        values = info.values,
        style = info.style or "dropdown",
        get = function()
            if info.getFunc then
                return info.getFunc()
            elseif info.dbPath then
                local path = {strsplit(".", info.dbPath)}
                local value = addon.db.profile
                for _, key in ipairs(path) do
                    value = value and value[key]
                end
                return value
            end
            return info.default
        end,
        set = function(_, val)
            if info.setFunc then
                info.setFunc(val)
            elseif info.dbPath then
                local path = {strsplit(".", info.dbPath)}
                local target = addon.db.profile
                for i = 1, #path - 1 do
                    target = target[path[i]]
                end
                target[path[#path]] = val
            end
            if info.refresh then
                info.refresh()
            end
        end
    }
end

-- ============================================================================
-- WINDOW SIZE SETUP
-- ============================================================================

local function SetupWindowSize()
    local AceConfigDialog = LibStub("AceConfigDialog-3.0")
    if not AceConfigDialog then return end
    
    local userHasResized = false
    local defaultWidth, defaultHeight = 900, 600

    local function setupDragonUIWindowSize()
        local configFrame = AceConfigDialog.OpenFrames["DragonUI"]
        if configFrame and configFrame.frame then
            local statusWidth = configFrame.status.width
            local statusHeight = configFrame.status.height

            if statusWidth and statusHeight then
                if statusWidth ~= defaultWidth or statusHeight ~= defaultHeight then
                    userHasResized = true
                end
            end

            if not userHasResized then
                configFrame.frame:SetWidth(defaultWidth)
                configFrame.frame:SetHeight(defaultHeight)
                configFrame.frame:ClearAllPoints()
                configFrame.frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
                configFrame.status.width = defaultWidth
                configFrame.status.height = defaultHeight
            else
                configFrame.frame:ClearAllPoints()
                configFrame.frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
            end
        end
    end

    -- Hook the status table application
    local originalSetStatusTable = AceConfigDialog.SetStatusTable
    AceConfigDialog.SetStatusTable = function(self, appName, statusTable)
        local result = originalSetStatusTable(self, appName, statusTable)
        if appName == "DragonUI" then
            setupDragonUIWindowSize()
        end
        return result
    end

    -- Hook Open to set size immediately
    local originalOpen = AceConfigDialog.Open
    AceConfigDialog.Open = function(self, appName, ...)
        local result = originalOpen(self, appName, ...)
        if appName == "DragonUI" then
            userHasResized = false
            setupDragonUIWindowSize()
        end
        return result
    end
end

-- ============================================================================
-- INITIALIZE OPTIONS (called after all option files are loaded)
-- ============================================================================

function addon:InitializeOptions()
    -- Add profiles options
    local profilesOptions = LibStub("AceDBOptions-3.0"):GetOptionsTable(addon.db)
    addon.Options.args.profiles = profilesOptions
    addon.Options.args.profiles.order = 100
    
    -- Register with AceConfig
    LibStub("AceConfig-3.0"):RegisterOptionsTable("DragonUI", addon.Options)
    LibStub("AceConfigDialog-3.0"):AddToBlizOptions("DragonUI", "DragonUI")
    
    -- Setup window size hooks
    SetupWindowSize()
    
    addon.OptionsLoaded = true
    print("|cFF00FF00[DragonUI]|r Options initialized")
end

-- Initialize when this addon finishes loading
local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("ADDON_LOADED")
initFrame:SetScript("OnEvent", function(self, event, loadedAddon)
    if loadedAddon == "DragonUI_Options" then
        addon:InitializeOptions()
        self:UnregisterAllEvents()
    end
end)

print("|cFF00FF00[DragonUI]|r Options core loaded")
