--[[
================================================================================
DragonUI Options - Minimap
================================================================================
Options for minimap customization, scale, tracking, and positioning.
Based on ElvUI_OptionsUI pattern.
================================================================================
]]

-- Access the main DragonUI addon
local addon = DragonUI
if not addon then return end

local L = addon.L
local LO = addon.LO

-- ============================================================================
-- MINIMAP OPTIONS GROUP
-- ============================================================================

local minimapOptions = {
    name = LO["Minimap"],
    type = "group",
    order = 10,
    args = {
        -- Basic Settings
        scale = {
            type = "range",
            name = LO["Scale"],
            min = 0.5,
            max = 2,
            step = 0.1,
            get = function()
                return addon.db.profile.minimap.scale
            end,
            set = function(_, val)
                addon.db.profile.minimap.scale = val
                if addon.MinimapModule then
                    addon.MinimapModule:UpdateSettings()
                end
            end,
            order = 1
        },
        border_alpha = {
            type = 'range',
            name = LO["Border Alpha"],
            desc = LO["Top border alpha (0 to hide)"],
            min = 0,
            max = 1,
            step = 0.1,
            get = function()
                return addon.db.profile.minimap.border_alpha
            end,
            set = function(info, value)
                addon.db.profile.minimap.border_alpha = value
                if MinimapBorderTop then
                    MinimapBorderTop:SetAlpha(value)
                end
            end,
            order = 2
        },

        addon_button_skin = {
            type = 'toggle',
            name = LO["Addon Button Skin"],
            desc = LO["Apply DragonUI border styling to addon icons (e.g., bag addons)"],
            get = function()
                return addon.db.profile.minimap.addon_button_skin
            end,
            set = function(info, value)
                addon.db.profile.minimap.addon_button_skin = value
                if addon.RefreshMinimap then
                    addon:RefreshMinimap()
                end
            end,
            order = 3
        },

        addon_button_fade = {
            type = 'toggle',
            name = LO["Addon Button Fade"],
            desc = LO["Addon icons fade out when not hovered"],
            get = function()
                return addon.db.profile.minimap.addon_button_fade
            end,
            set = function(info, value)
                addon.db.profile.minimap.addon_button_fade = value
                if addon.RefreshMinimap then
                    addon:RefreshMinimap()
                end
            end,
            order = 4
        },

        player_arrow_size = {
            type = 'range',
            name = LO["Player Arrow Size"],
            desc = LO["Size of the player arrow on the minimap"],
            min = 8,
            max = 50,
            step = 1,
            get = function()
                return addon.db.profile.minimap.player_arrow_size
            end,
            set = function(info, value)
                addon.db.profile.minimap.player_arrow_size = value
                if addon.MinimapModule then
                    addon.MinimapModule:UpdateSettings()
                end
            end,
            order = 5
        },

        -- Time & Calendar Section
        time_header = {
            type = 'header',
            name = LO["Time & Calendar"],
            order = 10
        },
        clock = {
            type = 'toggle',
            name = LO["Show Clock"],
            desc = LO["Show/hide the minimap clock"],
            get = function()
                return addon.db.profile.minimap.clock
            end,
            set = function(info, value)
                addon.db.profile.minimap.clock = value
                if addon.MinimapModule then
                    addon.MinimapModule:UpdateSettings()
                end
            end,
            order = 11
        },
        calendar = {
            type = 'toggle',
            name = LO["Show Calendar"],
            desc = LO["Show/hide the calendar frame"],
            get = function()
                return addon.db.profile.minimap.calendar
            end,
            set = function(info, value)
                addon.db.profile.minimap.calendar = value
                if GameTimeFrame then
                    if value then
                        GameTimeFrame:Show()
                    else
                        GameTimeFrame:Hide()
                    end
                end
            end,
            order = 12
        },
        clock_font_size = {
            type = 'range',
            name = LO["Clock Font Size"],
            desc = LO["Font size for the clock numbers on the minimap"],
            min = 8,
            max = 20,
            step = 1,
            get = function()
                return addon.db.profile.minimap.clock_font_size
            end,
            set = function(info, value)
                addon.db.profile.minimap.clock_font_size = value
                if addon.MinimapModule then
                    addon.MinimapModule:UpdateSettings()
                end
            end,
            order = 13
        },

        -- Display Settings Section
        display_header = {
            type = 'header',
            name = LO["Display Settings"],
            order = 20
        },
        tracking_icons = {
            type = "toggle",
            name = LO["Tracking Icons"],
            desc = LO["Show current tracking icons (old style)"],
            get = function()
                return addon.db.profile.minimap.tracking_icons
            end,
            set = function(_, val)
                addon.db.profile.minimap.tracking_icons = val
                if addon.MinimapModule then
                    addon.MinimapModule:UpdateTrackingIcon()
                end
            end,
            order = 21
        },
        zoom_buttons = {
            type = 'toggle',
            name = LO["Zoom Buttons"],
            desc = LO["Show zoom buttons (+/-)"],
            get = function()
                return addon.db.profile.minimap.zoom_buttons
            end,
            set = function(info, value)
                addon.db.profile.minimap.zoom_buttons = value
                if MinimapZoomIn and MinimapZoomOut then
                    if value then
                        MinimapZoomIn:Show()
                        MinimapZoomOut:Show()
                    else
                        MinimapZoomIn:Hide()
                        MinimapZoomOut:Hide()
                    end
                end
            end,
            order = 22
        },
        blip_skin = {
            type = 'toggle',
            name = LO["New Blip Style"],
            desc = LO["Use new DragonUI object icons on the minimap. When disabled, uses classic Blizzard icons."],
            get = function()
                return addon.db.profile.minimap.blip_skin
            end,
            set = function(info, value)
                addon.db.profile.minimap.blip_skin = value
                if addon.MinimapModule then
                    addon.MinimapModule:UpdateSettings()
                end
            end,
            order = 23
        },
        zonetext_font_size = {
            type = 'range',
            name = LO["Zone Text Size"],
            desc = LO["Zone text font size on top border"],
            min = 8,
            max = 20,
            step = 1,
            get = function()
                return addon.db.profile.minimap.zonetext_font_size
            end,
            set = function(info, value)
                addon.db.profile.minimap.zonetext_font_size = value
                if MinimapZoneText then
                    local font, _, flags = MinimapZoneText:GetFont()
                    MinimapZoneText:SetFont(font, value, flags)
                end
            end,
            order = 24
        },

        -- Position Section
        position_header = {
            type = 'header',
            name = LO["Position"],
            order = 30
        },
        position_reset = {
            type = 'execute',
            name = LO["Reset Position"],
            desc = LO["Reset minimap to default position (top-right corner)"],
            func = function()
                if not addon.db.profile.widgets then
                    addon.db.profile.widgets = {}
                end

                addon.db.profile.widgets.minimap = {
                    anchor = "TOPRIGHT",
                    posX = 0,
                    posY = 0
                }

                if addon.MinimapModule then
                    addon.MinimapModule:UpdateSettings()
                end

                print("|cFF00FF00[DragonUI]|r " .. LO["Minimap position reset to default"])
            end,
            order = 31
        }
    }
}

-- ============================================================================
-- REGISTER OPTIONS
-- ============================================================================

addon:RegisterOptionsGroup("minimap", minimapOptions)
