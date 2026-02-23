--[[
================================================================================
DragonUI Options - General
================================================================================
Editor mode button, keybind mode button, and other general UI controls.
Based on ElvUI_OptionsUI pattern.
================================================================================
]]

-- Access the main DragonUI addon
local addon = DragonUI
if not addon then return end
local L = addon.L
local LO = addon.LO

-- ============================================================================
-- ADD GENERAL OPTIONS TO addon.Options.args
-- ============================================================================

-- Editor Mode Button
addon.Options.args.toggle_editor_mode = {
    type = 'execute',
    name = function()
        if addon.EditorMode then
            local success, isActive = pcall(function()
                return addon.EditorMode:IsActive()
            end)
            if success and isActive then
                return "|cffFF6347" .. LO["Exit Editor Mode"] .. "|r"
            end
        end
        return "|cff00FF00" .. LO["Move UI Elements"] .. "|r"
    end,
    desc = "Unlock UI elements to move them with your mouse. A button will appear to exit this mode.",
    func = function()
        GameTooltip:Hide()
        LibStub("AceConfigDialog-3.0"):Close("DragonUI")
        if addon.EditorMode then
            addon.EditorMode:Toggle()
        end
    end,
    disabled = false,
    order = 0
}

-- Keybinding Mode Button
addon.Options.args.toggle_keybind_mode = {
    type = 'execute',
    name = function()
        if LibStub and LibStub("LibKeyBound-1.0", true) and LibStub("LibKeyBound-1.0"):IsShown() then
            return "|cffFF6347" .. LO["KeyBind Mode Active"] .. "|r"
        else
            return "|cff00FF00" .. LO["KeyBind Mode"] .. "|r"
        end
    end,
    desc = LO["Toggle keybinding mode. Hover over action buttons and press keys to bind them instantly. Press ESC to clear bindings."],
    func = function()
        GameTooltip:Hide()
        LibStub("AceConfigDialog-3.0"):Close("DragonUI")
        
        if addon.KeyBindingModule and LibStub and LibStub("LibKeyBound-1.0", true) then
            local LibKeyBound = LibStub("LibKeyBound-1.0")
            LibKeyBound:Toggle()
        else
            print("|cFFFF0000[DragonUI]|r KeyBinding module not available")
        end
    end,
    disabled = function()
        return not (addon.KeyBindingModule and addon.KeyBindingModule.enabled)
    end,
    order = 0.3
}

-- Visual Separator
addon.Options.args.editor_separator = {
    type = 'header',
    name = ' ',
    order = 0.5
}
