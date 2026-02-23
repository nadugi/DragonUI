--[[
================================================================================
DragonUI Options - Action Bars
================================================================================
Options for main action bars, scales, positions, and button appearance.
Based on ElvUI_OptionsUI pattern.
================================================================================
]]

-- Access the main DragonUI addon
local addon = DragonUI
if not addon then return end

local L = addon.L
local LO = addon.LO

-- ============================================================================
-- ACTION BARS OPTIONS GROUP
-- ============================================================================

local actionbarsOptions = {
    type = 'group',
    name = LO["Action Bars"],
    order = 1,
    args = {
        -- ====================================================================
        -- SCALES
        -- ====================================================================
        scales = {
            type = 'group',
            name = LO["Action Bar Scales"],
            inline = true,
            order = 1,
            args = {
                scale_actionbar = {
                    type = 'range',
                    name = LO["Main Bar Scale"],
                    desc = LO["Scale for main action bar"],
                    min = 0.5,
                    max = 2.0,
                    step = 0.1,
                    get = function()
                        return addon.db.profile.mainbars.scale_actionbar
                    end,
                    set = function(info, value)
                        addon.db.profile.mainbars.scale_actionbar = value
                        if addon.RefreshMainbars then
                            addon.RefreshMainbars()
                        end
                    end,
                    order = 1
                },
                scale_rightbar = {
                    type = 'range',
                    name = LO["Right Bar Scale"],
                    desc = LO["Scale for right action bar (MultiBarRight)"],
                    min = 0.5,
                    max = 2.0,
                    step = 0.1,
                    get = function()
                        return addon.db.profile.mainbars.scale_rightbar
                    end,
                    set = function(info, value)
                        addon.db.profile.mainbars.scale_rightbar = value
                        if addon.RefreshMainbars then
                            addon.RefreshMainbars()
                        end
                    end,
                    order = 2
                },
                scale_leftbar = {
                    type = 'range',
                    name = LO["Left Bar Scale"],
                    desc = LO["Scale for left action bar (MultiBarLeft)"],
                    min = 0.5,
                    max = 2.0,
                    step = 0.1,
                    get = function()
                        return addon.db.profile.mainbars.scale_leftbar
                    end,
                    set = function(info, value)
                        addon.db.profile.mainbars.scale_leftbar = value
                        if addon.RefreshMainbars then
                            addon.RefreshMainbars()
                        end
                    end,
                    order = 3
                },
                scale_bottomleft = {
                    type = 'range',
                    name = LO["Bottom Left Bar Scale"],
                    desc = LO["Scale for bottom left action bar (MultiBarBottomLeft)"],
                    min = 0.5,
                    max = 2.0,
                    step = 0.1,
                    get = function()
                        return addon.db.profile.mainbars.scale_bottomleft
                    end,
                    set = function(info, value)
                        addon.db.profile.mainbars.scale_bottomleft = value
                        if addon.RefreshMainbars then
                            addon.RefreshMainbars()
                        end
                    end,
                    order = 4
                },
                scale_bottomright = {
                    type = 'range',
                    name = LO["Bottom Right Bar Scale"],
                    desc = LO["Scale for bottom right action bar (MultiBarBottomRight)"],
                    min = 0.5,
                    max = 2.0,
                    step = 0.1,
                    get = function()
                        return addon.db.profile.mainbars.scale_bottomright
                    end,
                    set = function(info, value)
                        addon.db.profile.mainbars.scale_bottomright = value
                        if addon.RefreshMainbars then
                            addon.RefreshMainbars()
                        end
                    end,
                    order = 5
                },
                reset_scales = {
                    type = 'execute',
                    name = LO["Reset All Scales"],
                    desc = LO["Reset all action bar scales to their default values (0.9)"],
                    func = function()
                        addon.db.profile.mainbars.scale_actionbar = 0.9
                        addon.db.profile.mainbars.scale_rightbar = 0.9
                        addon.db.profile.mainbars.scale_leftbar = 0.9
                        addon.db.profile.mainbars.scale_bottomleft = 0.9
                        addon.db.profile.mainbars.scale_bottomright = 0.9
                        
                        if addon.RefreshMainbars then
                            addon.RefreshMainbars()
                        end
                        
                        print("|cFF00FF00[DragonUI]|r " .. LO["All action bar scales reset to default values (0.9)"])
                        StaticPopup_Show("DRAGONUI_RELOAD_UI")
                    end,
                    order = 6
                }
            }
        },

        -- ====================================================================
        -- POSITIONS
        -- ====================================================================
        positions = {
            type = 'group',
            name = LO["Action Bar Positions"],
            inline = true,
            order = 2,
            args = {
                editor_mode_desc = {
                    type = 'description',
                    name = "|cffFFD700Tip:|r Use the |cff00FF00Move UI Elements|r button above to reposition action bars with your mouse.",
                    order = 1
                },
                left_horizontal = {
                    type = 'toggle',
                    name = LO["Left Bar Horizontal"],
                    desc = LO["Make the left secondary bar horizontal instead of vertical"],
                    get = function()
                        return addon.db.profile.mainbars.left.horizontal
                    end,
                    set = function(_, value)
                        addon.db.profile.mainbars.left.horizontal = value
                        addon.db.profile.mainbars.left.columns = value and 12 or 1
                        if addon.RefreshMainbarsSystem then
                            addon.RefreshMainbarsSystem()
                        end
                    end,
                    order = 2
                },
                right_horizontal = {
                    type = 'toggle',
                    name = LO["Right Bar Horizontal"],
                    desc = LO["Make the right secondary bar horizontal instead of vertical"],
                    get = function()
                        return addon.db.profile.mainbars.right.horizontal
                    end,
                    set = function(_, value)
                        addon.db.profile.mainbars.right.horizontal = value
                        addon.db.profile.mainbars.right.columns = value and 12 or 1
                        if addon.RefreshMainbarsSystem then
                            addon.RefreshMainbarsSystem()
                        end
                    end,
                    order = 3
                }
            }
        },

        -- ====================================================================
        -- BUTTON APPEARANCE
        -- ====================================================================
        buttons = {
            type = 'group',
            name = LO["Button Appearance"],
            inline = true,
            order = 3,
            args = {
                only_actionbackground = {
                    type = 'toggle',
                    name = LO["Main Bar Only Background"],
                    desc = LO["If checked, only the main action bar buttons will have a background. If unchecked, all action bar buttons will have a background."],
                    get = function()
                        return addon.db.profile.buttons.only_actionbackground
                    end,
                    set = function(info, value)
                        addon.db.profile.buttons.only_actionbackground = value
                        if addon.RefreshButtons then
                            addon.RefreshButtons()
                        end
                    end,
                    order = 1
                },
                hide_main_bar_background = {
                    type = 'toggle',
                    name = LO["Hide Main Bar Background"],
                    desc = LO["Hide the background texture of the main action bar (makes it completely transparent)"] .. "|cFFFF0000Requires UI reload|r",
                    get = function()
                        return addon.db.profile.buttons.hide_main_bar_background
                    end,
                    set = function(info, value)
                        addon.db.profile.buttons.hide_main_bar_background = value
                        if addon.RefreshMainbars then
                            addon.RefreshMainbars()
                        end
                        StaticPopup_Show("DRAGONUI_RELOAD_UI")
                    end,
                    order = 1.5
                },
                count = {
                    type = 'group',
                    name = LO["Count Text"],
                    inline = true,
                    order = 2,
                    args = {
                        show = {
                            type = 'toggle',
                            name = LO["Show Count"],
                            get = function()
                                return addon.db.profile.buttons.count.show
                            end,
                            set = function(info, value)
                                addon.db.profile.buttons.count.show = value
                                if addon.RefreshButtons then
                                    addon.RefreshButtons()
                                end
                            end,
                            order = 1
                        }
                    }
                },
                hotkey = {
                    type = 'group',
                    name = LO["Hotkey Text"],
                    inline = true,
                    order = 4,
                    args = {
                        show = {
                            type = 'toggle',
                            name = LO["Show Hotkey"],
                            get = function()
                                return addon.db.profile.buttons.hotkey.show
                            end,
                            set = function(info, value)
                                addon.db.profile.buttons.hotkey.show = value
                                if addon.RefreshButtons then
                                    addon.RefreshButtons()
                                end
                            end,
                            order = 1
                        },
                        range = {
                            type = 'toggle',
                            name = LO["Range Indicator"],
                            desc = LO["Show small range indicator point on buttons"],
                            get = function()
                                return addon.db.profile.buttons.hotkey.range
                            end,
                            set = function(info, value)
                                addon.db.profile.buttons.hotkey.range = value
                                if addon.RefreshButtons then
                                    addon.RefreshButtons()
                                end
                            end,
                            order = 2
                        }
                    }
                },
                macros = {
                    type = 'group',
                    name = LO["Macro Text"],
                    inline = true,
                    order = 5,
                    args = {
                        show = {
                            type = 'toggle',
                            name = LO["Show Macro Names"],
                            get = function()
                                return addon.db.profile.buttons.macros.show
                            end,
                            set = function(info, value)
                                addon.db.profile.buttons.macros.show = value
                                if addon.RefreshButtons then
                                    addon.RefreshButtons()
                                end
                            end,
                            order = 1
                        }
                    }
                },
                pages = {
                    type = 'group',
                    name = LO["Page Numbers"],
                    inline = true,
                    order = 6,
                    args = {
                        show = {
                            type = 'toggle',
                            name = LO["Show Pages"],
                            get = function()
                                return addon.db.profile.buttons.pages.show
                            end,
                            set = function(info, value)
                                addon.db.profile.buttons.pages.show = value
                                StaticPopup_Show("DRAGONUI_RELOAD_UI")
                            end,
                            order = 1
                        }
                    }
                },
                cooldown = {
                    type = 'group',
                    name = LO["Cooldown Text"],
                    inline = true,
                    order = 7,
                    args = {
                        min_duration = {
                            type = 'range',
                            name = LO["Min Duration"],
                            desc = LO["Minimum duration for text triggering"],
                            min = 1,
                            max = 10,
                            step = 1,
                            get = function()
                                return addon.db.profile.buttons.cooldown.min_duration
                            end,
                            set = function(info, value)
                                addon.db.profile.buttons.cooldown.min_duration = value
                                if addon.RefreshCooldowns then
                                    addon.RefreshCooldowns()
                                end
                            end,
                            order = 2
                        },
                        color = {
                            type = 'color',
                            name = LO["Text Color"],
                            desc = LO["Cooldown text color"],
                            get = function()
                                local c = addon.db.profile.buttons.cooldown.color
                                return c[1], c[2], c[3], c[4]
                            end,
                            set = function(info, r, g, b, a)
                                addon.db.profile.buttons.cooldown.color = {r, g, b, a}
                                if addon.RefreshCooldowns then
                                    addon.RefreshCooldowns()
                                end
                            end,
                            hasAlpha = true,
                            order = 3
                        },
                        font_size = {
                            type = 'range',
                            name = LO["Font Size"],
                            desc = LO["Size of cooldown text"],
                            min = 8,
                            max = 24,
                            step = 1,
                            get = function()
                                return addon.db.profile.buttons.cooldown.font_size
                            end,
                            set = function(info, value)
                                addon.db.profile.buttons.cooldown.font_size = value
                                if addon.RefreshCooldowns then
                                    addon.RefreshCooldowns()
                                end
                            end,
                            order = 4
                        }
                    }
                },
                macros_color = {
                    type = 'color',
                    name = LO["Macro Text Color"],
                    desc = LO["Color for macro text"],
                    get = function()
                        local c = addon.db.profile.buttons.macros.color
                        return c[1], c[2], c[3], c[4]
                    end,
                    set = function(info, r, g, b, a)
                        addon.db.profile.buttons.macros.color = {r, g, b, a}
                        if addon.RefreshButtons then
                            addon.RefreshButtons()
                        end
                    end,
                    hasAlpha = true,
                    order = 8
                },
                hotkey_shadow = {
                    type = 'color',
                    name = LO["Hotkey Shadow Color"],
                    desc = LO["Shadow color for hotkey text"],
                    get = function()
                        local c = addon.db.profile.buttons.hotkey.shadow
                        return c[1], c[2], c[3], c[4]
                    end,
                    set = function(info, r, g, b, a)
                        addon.db.profile.buttons.hotkey.shadow = {r, g, b, a}
                        if addon.RefreshButtons then
                            addon.RefreshButtons()
                        end
                    end,
                    hasAlpha = true,
                    order = 9
                },
                border_color = {
                    type = 'color',
                    name = LO["Border Color"],
                    desc = LO["Border color for buttons"],
                    get = function()
                        local c = addon.db.profile.buttons.border_color
                        return c[1], c[2], c[3], c[4]
                    end,
                    set = function(info, r, g, b, a)
                        addon.db.profile.buttons.border_color = {r, g, b, a}
                        if addon.RefreshButtons then
                            addon.RefreshButtons()
                        end
                    end,
                    hasAlpha = true,
                    order = 10
                }
            }
        }
    }
}

-- ============================================================================
-- REGISTER OPTIONS
-- ============================================================================

addon:RegisterOptionsGroup("actionbars", actionbarsOptions)
