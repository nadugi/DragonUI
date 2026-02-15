--[[
================================================================================
DragonUI Options - Modules
================================================================================
Module enable/disable toggles for all DragonUI systems.
Based on ElvUI_OptionsUI pattern.
================================================================================
]]

-- Access the main DragonUI addon
local addon = DragonUI
if not addon then return end

-- ============================================================================
-- ADD MODULES OPTIONS TO addon.Options.args
-- ============================================================================

addon.Options.args.modules = {
    type = 'group',
    name = "Modules",
    desc = "Enable or disable specific DragonUI modules",
    order = 0.6,
    args = {
        description = {
            type = 'description',
            name = "|cffFFD700Module Control|r\n\nEnable or disable specific DragonUI modules. When disabled, the original Blizzard UI will be shown instead.",
            order = 1
        },

        -- ====================================================================
        -- CAST BARS SECTION
        -- ====================================================================
        castbars_header = {
            type = 'header',
            name = "Cast Bars",
            order = 10
        },

        player_castbar_enabled = {
            type = 'toggle',
            name = "Player Castbar",
            desc = "Enable DragonUI player castbar. When disabled, shows default Blizzard castbar.",
            get = function()
                return addon.db.profile.castbar.enabled
            end,
            set = function(info, val)
                addon.db.profile.castbar.enabled = val
                if addon.RefreshCastbar then
                    addon.RefreshCastbar()
                end
            end,
            order = 11
        },

        target_castbar_enabled = {
            type = 'toggle',
            name = "Target Castbar",
            desc = "Enable DragonUI target castbar. When disabled, shows default Blizzard castbar.",
            get = function()
                if not addon.db.profile.castbar.target then
                    return true
                end
                local value = addon.db.profile.castbar.target.enabled
                if value == nil then
                    return true
                end
                return value == true
            end,
            set = function(info, val)
                if not addon.db.profile.castbar.target then
                    addon.db.profile.castbar.target = {}
                end
                addon.db.profile.castbar.target.enabled = val
                if addon.RefreshTargetCastbar then
                    addon.RefreshTargetCastbar()
                end
            end,
            order = 12
        },

        focus_castbar_enabled = {
            type = 'toggle',
            name = "Focus Castbar",
            desc = "Enable DragonUI focus castbar. When disabled, shows default Blizzard castbar.",
            get = function()
                return addon.db.profile.castbar.focus.enabled
            end,
            set = function(info, value)
                addon.db.profile.castbar.focus.enabled = value
                if addon.RefreshFocusCastbar then
                    addon.RefreshFocusCastbar()
                end
            end,
            order = 13
        },

        -- ====================================================================
        -- OTHER MODULES SECTION
        -- ====================================================================
        other_modules_header = {
            type = 'header',
            name = "Other Modules",
            order = 20
        },

        -- Unified Action Bars System
        actionbars_system_enabled = {
            type = 'toggle',
            name = "Action Bars System",
            desc = "Enable the complete DragonUI action bars system. This controls: Main action bars, vehicle interface, stance/shapeshift bars, pet action bars, multicast bars (totems/possess), button styling, and hide Blizzard elements. When disabled, all action bar related features will use default Blizzard interface.",
            get = function()
                local modules = addon.db.profile.modules
                if not modules then
                    return false
                end
                return (modules.mainbars and modules.mainbars.enabled) and
                       (modules.vehicle and modules.vehicle.enabled) and
                       (modules.stance and modules.stance.enabled) and
                       (modules.petbar and modules.petbar.enabled) and
                       (modules.multicast and modules.multicast.enabled) and
                       (modules.buttons and modules.buttons.enabled) and
                       (modules.noop and modules.noop.enabled)
            end,
            set = function(info, val)
                if not addon.db.profile.modules then
                    addon.db.profile.modules = {}
                end
                local moduleNames = {"mainbars", "vehicle", "stance", "petbar", "multicast", "buttons", "noop"}
                for _, moduleName in ipairs(moduleNames) do
                    if not addon.db.profile.modules[moduleName] then
                        addon.db.profile.modules[moduleName] = {}
                    end
                    addon.db.profile.modules[moduleName].enabled = val
                end
                StaticPopup_Show("DRAGONUI_RELOAD_UI")
            end,
            order = 21
        },

        -- Micro Menu & Bags
        micromenu_enabled = {
            type = 'toggle',
            name = "Micro Menu & Bags",
            desc = "Apply DragonUI micro menu and bags system styling and positioning. Includes character button, spellbook, talents, etc. and bag management. When disabled, these elements will use default Blizzard positioning and styling.",
            get = function()
                return addon.db.profile.modules and addon.db.profile.modules.micromenu and
                       addon.db.profile.modules.micromenu.enabled
            end,
            set = function(info, val)
                if not addon.db.profile.modules then
                    addon.db.profile.modules = {}
                end
                if not addon.db.profile.modules.micromenu then
                    addon.db.profile.modules.micromenu = {}
                end
                addon.db.profile.modules.micromenu.enabled = val
                StaticPopup_Show("DRAGONUI_RELOAD_UI")
            end,
            order = 22
        },

        -- Cooldown Timers
        cooldowns_enabled = {
            type = 'toggle',
            name = "Cooldown Timers",
            desc = "Show cooldown timers on action buttons. When disabled, cooldown timers will be hidden and the system will be completely deactivated.",
            get = function()
                return addon.db.profile.modules and addon.db.profile.modules.cooldowns and
                       addon.db.profile.modules.cooldowns.enabled
            end,
            set = function(info, val)
                if not addon.db.profile.modules then
                    addon.db.profile.modules = {}
                end
                if not addon.db.profile.modules.cooldowns then
                    addon.db.profile.modules.cooldowns = {}
                end
                addon.db.profile.modules.cooldowns.enabled = val
                if addon.RefreshCooldownSystem then
                    addon.RefreshCooldownSystem()
                end
            end,
            order = 23
        },

        -- Minimap System
        minimap_enabled = {
            type = 'toggle',
            name = "Minimap System",
            desc = "Enable DragonUI minimap enhancements including custom styling, positioning, tracking icons, and calendar. When disabled, uses default Blizzard minimap appearance and positioning.",
            get = function()
                return addon.db.profile.modules and addon.db.profile.modules.minimap and
                       addon.db.profile.modules.minimap.enabled
            end,
            set = function(info, val)
                if not addon.db.profile.modules then
                    addon.db.profile.modules = {}
                end
                if not addon.db.profile.modules.minimap then
                    addon.db.profile.modules.minimap = {}
                end
                addon.db.profile.modules.minimap.enabled = val
                StaticPopup_Show("DRAGONUI_RELOAD_UI")
            end,
            order = 24
        },

        -- Buff Frame System
        buffs_enabled = {
            type = 'toggle',
            name = "Buff Frame System",
            desc = "Enable DragonUI buff frame with custom styling, positioning, and toggle button functionality. When disabled, uses default Blizzard buff frame appearance and positioning.",
            get = function()
                return addon.db.profile.modules and addon.db.profile.modules.buffs and
                       addon.db.profile.modules.buffs.enabled
            end,
            set = function(info, val)
                if not addon.db.profile.modules then
                    addon.db.profile.modules = {}
                end
                if not addon.db.profile.modules.buffs then
                    addon.db.profile.modules.buffs = {}
                end
                addon.db.profile.modules.buffs.enabled = val
                if addon.BuffFrameModule then
                    addon.BuffFrameModule:Toggle(val)
                end
                StaticPopup_Show("DRAGONUI_RELOAD_UI")
            end,
            order = 25
        },

        -- ====================================================================
        -- ENHANCEMENTS SECTION - New DragonUI Features
        -- ====================================================================
        enhancements_header = {
            type = 'header',
            name = "Enhancements",
            order = 50
        },

        enhancements_description = {
            type = 'description',
            name = "|cffFFD700Visual enhancements|r that add Dragonflight-style polish to the UI.\n",
            order = 51
        },

        -- Dark Mode
        darkmode_enabled = {
            type = 'toggle',
            name = "Dark Mode",
            desc = "Apply darker tinted textures to all UI chrome: action bars, unit frames, minimap, bags, micro menu, and more.",
            width = "full",
            get = function()
                return addon.db.profile.modules and addon.db.profile.modules.darkmode and
                       addon.db.profile.modules.darkmode.enabled
            end,
            set = function(info, val)
                if not addon.db.profile.modules then addon.db.profile.modules = {} end
                if not addon.db.profile.modules.darkmode then addon.db.profile.modules.darkmode = {} end
                addon.db.profile.modules.darkmode.enabled = val
                if val then
                    if addon.ApplyDarkMode then addon.ApplyDarkMode() end
                else
                    if addon.RestoreDarkMode then addon.RestoreDarkMode() end
                end
            end,
            order = 52
        },

        darkmode_intensity = {
            type = 'select',
            name = "Dark Mode Intensity",
            desc = "Choose how dark the UI chrome should be.",
            values = {
                [1] = "Light (subtle)",
                [2] = "Medium (balanced)",
                [3] = "Dark (maximum)",
            },
            get = function()
                local config = addon.db.profile.modules and addon.db.profile.modules.darkmode
                return config and config.intensity_preset or 2
            end,
            set = function(info, val)
                if not addon.db.profile.modules then addon.db.profile.modules = {} end
                if not addon.db.profile.modules.darkmode then addon.db.profile.modules.darkmode = {} end
                addon.db.profile.modules.darkmode.intensity_preset = val
                if addon.RefreshDarkMode then addon.RefreshDarkMode() end
            end,
            disabled = function()
                return not (addon.db.profile.modules and addon.db.profile.modules.darkmode and
                            addon.db.profile.modules.darkmode.enabled)
            end,
            order = 53
        },

        -- Range Indicator
        range_indicator_enabled = {
            type = 'toggle',
            name = "Range Indicator",
            desc = "Tint action button icons when target is out of range (red), not enough mana (blue), or unusable (gray).",
            width = "full",
            get = function()
                return addon.db.profile.buttons and addon.db.profile.buttons.range_indicator and
                       addon.db.profile.buttons.range_indicator.enabled
            end,
            set = function(info, val)
                if not addon.db.profile.buttons then addon.db.profile.buttons = {} end
                if not addon.db.profile.buttons.range_indicator then addon.db.profile.buttons.range_indicator = {} end
                addon.db.profile.buttons.range_indicator.enabled = val
            end,
            order = 54
        },

        -- Item Quality Borders
        itemquality_enabled = {
            type = 'toggle',
            name = "Item Quality Borders",
            desc = "Show colored glow borders on action buttons containing items, colored by item quality (green = uncommon, blue = rare, purple = epic, etc.).",
            width = "full",
            get = function()
                return addon.db.profile.modules and addon.db.profile.modules.itemquality and
                       addon.db.profile.modules.itemquality.enabled
            end,
            set = function(info, val)
                if not addon.db.profile.modules then addon.db.profile.modules = {} end
                if not addon.db.profile.modules.itemquality then addon.db.profile.modules.itemquality = {} end
                addon.db.profile.modules.itemquality.enabled = val
                if val then
                    if addon.ApplyItemQualitySystem then addon.ApplyItemQualitySystem() end
                else
                    if addon.RestoreItemQualitySystem then addon.RestoreItemQualitySystem() end
                end
            end,
            order = 55
        },

        itemquality_minquality = {
            type = 'select',
            name = "Minimum Quality",
            desc = "Only show colored borders for items at or above this quality level.",
            values = {
                [0] = "|cff9d9d9dPoor|r",
                [1] = "|cffffffffCommon|r",
                [2] = "|cff1eff00Uncommon|r",
                [3] = "|cff0070ddRare|r",
                [4] = "|cffa335eeEpic|r",
                [5] = "|cffff8000Legendary|r",
            },
            get = function()
                local config = addon.db.profile.modules and addon.db.profile.modules.itemquality
                return config and config.min_quality or 2
            end,
            set = function(info, val)
                if not addon.db.profile.modules then addon.db.profile.modules = {} end
                if not addon.db.profile.modules.itemquality then addon.db.profile.modules.itemquality = {} end
                addon.db.profile.modules.itemquality.min_quality = val
                if addon.UpdateAllQualityBorders then addon.UpdateAllQualityBorders() end
            end,
            disabled = function()
                return not (addon.db.profile.modules and addon.db.profile.modules.itemquality and
                            addon.db.profile.modules.itemquality.enabled)
            end,
            order = 56
        },

        -- Enhanced Tooltips
        tooltip_header = {
            type = 'header',
            name = "Enhanced Tooltips",
            order = 60
        },

        tooltip_enabled = {
            type = 'toggle',
            name = "Enable Enhanced Tooltips",
            desc = "Improve GameTooltip with class-colored borders, class-colored names, target-of-target info, and styled health bars.",
            width = "full",
            get = function()
                return addon.db.profile.modules and addon.db.profile.modules.tooltip and
                       addon.db.profile.modules.tooltip.enabled
            end,
            set = function(info, val)
                if not addon.db.profile.modules then addon.db.profile.modules = {} end
                if not addon.db.profile.modules.tooltip then addon.db.profile.modules.tooltip = {} end
                addon.db.profile.modules.tooltip.enabled = val
                if val then
                    if addon.ApplyTooltipSystem then addon.ApplyTooltipSystem() end
                else
                    if addon.RestoreTooltipSystem then addon.RestoreTooltipSystem() end
                end
            end,
            order = 61
        },

        tooltip_class_border = {
            type = 'toggle',
            name = "Class-Colored Border",
            desc = "Color the tooltip border by the unit's class (players) or reaction (NPCs).",
            get = function()
                local config = addon.db.profile.modules and addon.db.profile.modules.tooltip
                return config and config.class_colored_border ~= false
            end,
            set = function(info, val)
                if not addon.db.profile.modules then addon.db.profile.modules = {} end
                if not addon.db.profile.modules.tooltip then addon.db.profile.modules.tooltip = {} end
                addon.db.profile.modules.tooltip.class_colored_border = val
            end,
            disabled = function()
                return not (addon.db.profile.modules and addon.db.profile.modules.tooltip and
                            addon.db.profile.modules.tooltip.enabled)
            end,
            order = 62
        },

        tooltip_class_name = {
            type = 'toggle',
            name = "Class-Colored Name",
            desc = "Color the unit name text in the tooltip by class color (players only).",
            get = function()
                local config = addon.db.profile.modules and addon.db.profile.modules.tooltip
                return config and config.class_colored_name ~= false
            end,
            set = function(info, val)
                if not addon.db.profile.modules then addon.db.profile.modules = {} end
                if not addon.db.profile.modules.tooltip then addon.db.profile.modules.tooltip = {} end
                addon.db.profile.modules.tooltip.class_colored_name = val
            end,
            disabled = function()
                return not (addon.db.profile.modules and addon.db.profile.modules.tooltip and
                            addon.db.profile.modules.tooltip.enabled)
            end,
            order = 63
        },

        tooltip_target_of_target = {
            type = 'toggle',
            name = "Target of Target",
            desc = "Add a 'Targeting: <name>' line to the tooltip showing who the unit is targeting.",
            get = function()
                local config = addon.db.profile.modules and addon.db.profile.modules.tooltip
                return config and config.target_of_target ~= false
            end,
            set = function(info, val)
                if not addon.db.profile.modules then addon.db.profile.modules = {} end
                if not addon.db.profile.modules.tooltip then addon.db.profile.modules.tooltip = {} end
                addon.db.profile.modules.tooltip.target_of_target = val
            end,
            disabled = function()
                return not (addon.db.profile.modules and addon.db.profile.modules.tooltip and
                            addon.db.profile.modules.tooltip.enabled)
            end,
            order = 64
        },

        tooltip_health_bar = {
            type = 'toggle',
            name = "Styled Health Bar",
            desc = "Restyle the tooltip health bar with class/reaction colors.",
            get = function()
                local config = addon.db.profile.modules and addon.db.profile.modules.tooltip
                return config and config.health_bar ~= false
            end,
            set = function(info, val)
                if not addon.db.profile.modules then addon.db.profile.modules = {} end
                if not addon.db.profile.modules.tooltip then addon.db.profile.modules.tooltip = {} end
                addon.db.profile.modules.tooltip.health_bar = val
            end,
            disabled = function()
                return not (addon.db.profile.modules and addon.db.profile.modules.tooltip and
                            addon.db.profile.modules.tooltip.enabled)
            end,
            order = 65
        },

        tooltip_anchor_cursor = {
            type = 'toggle',
            name = "Anchor to Cursor",
            desc = "Make the tooltip follow the cursor position instead of using the default anchor.",
            get = function()
                local config = addon.db.profile.modules and addon.db.profile.modules.tooltip
                return config and config.anchor_cursor
            end,
            set = function(info, val)
                if not addon.db.profile.modules then addon.db.profile.modules = {} end
                if not addon.db.profile.modules.tooltip then addon.db.profile.modules.tooltip = {} end
                addon.db.profile.modules.tooltip.anchor_cursor = val
            end,
            disabled = function()
                return not (addon.db.profile.modules and addon.db.profile.modules.tooltip and
                            addon.db.profile.modules.tooltip.enabled)
            end,
            order = 66
        },

        -- ====================================================================
        -- ADVANCED SECTION - All Registered Modules
        -- ====================================================================
        advanced_header = {
            type = 'header',
            name = "Advanced - Individual Module Control",
            order = 100
        },
        
        advanced_description = {
            type = 'description',
            name = "|cffFF6600Warning:|r These are individual module controls. The options above may control multiple modules at once. Changes here will be reflected above and vice versa.\n",
            order = 101
        },
    }
}

-- ============================================================================
-- DYNAMIC ADVANCED MODULE TOGGLES
-- ============================================================================
-- Generate toggles for ALL registered modules from ModuleRegistry.
-- Uses a lazy generation approach - creates options when first accessed.

local advancedOptionsGenerated = false

local function GenerateAdvancedModuleOptions()
    if advancedOptionsGenerated then return end
    
    local MR = addon.ModuleRegistry
    if not MR or not MR.loadOrder or #MR.loadOrder == 0 then 
        return 
    end
    
    advancedOptionsGenerated = true
    
    local orderBase = 110
    
    for i, moduleName in ipairs(MR.loadOrder) do
        local info = MR:GetInfo(moduleName)
        if info then
            local optionKey = "advanced_" .. moduleName
            
            addon.Options.args.modules.args[optionKey] = {
                type = 'toggle',
                name = info.displayName or moduleName,
                desc = (info.description and info.description ~= "") 
                    and info.description 
                    or ("Enable/disable the " .. (info.displayName or moduleName) .. " module."),
                get = function()
                    return MR:IsEnabled(moduleName)
                end,
                set = function(_, val)
                    -- Update database
                    if not addon.db.profile.modules then
                        addon.db.profile.modules = {}
                    end
                    if not addon.db.profile.modules[moduleName] then
                        addon.db.profile.modules[moduleName] = {}
                    end
                    addon.db.profile.modules[moduleName].enabled = val
                    
                    -- Show reload prompt
                    StaticPopup_Show("DRAGONUI_RELOAD_UI")
                end,
                order = orderBase + i
            }
        end
    end
    
    -- Force AceConfigRegistry to update the options
    if LibStub and LibStub("AceConfigRegistry-3.0", true) then
        LibStub("AceConfigRegistry-3.0"):NotifyChange("DragonUI")
    end
end

-- Hook into the modules group to generate options when accessed
-- This ensures modules have had time to register
local originalGet = addon.Options.args.modules.args.advanced_header.name
addon.Options.args.modules.args.advanced_header.name = function()
    GenerateAdvancedModuleOptions()
    return "Advanced - Individual Module Control"
end
