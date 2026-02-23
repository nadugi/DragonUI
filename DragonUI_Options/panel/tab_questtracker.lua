--[[
================================================================================
DragonUI Options Panel - Quest Tracker Tab
================================================================================
Quest tracker position and behavior.
================================================================================
]]

local addon = DragonUI
if not addon then return end

local L = addon.L
local LO = addon.LO
local C = addon.PanelControls
local Panel = addon.OptionsPanel

-- ============================================================================
-- QUEST TRACKER TAB BUILDER
-- ============================================================================

local anchorValues = {
    TOPRIGHT    = LO["Top Right"],
    TOPLEFT     = LO["Top Left"],
    BOTTOMRIGHT = LO["Bottom Right"],
    BOTTOMLEFT  = LO["Bottom Left"],
    CENTER      = LO["Center"],
}

local function RefreshQT()
    if addon.RefreshQuestTracker then addon.RefreshQuestTracker() end
end

local function BuildQuesttrackerTab(scroll)
    local section = C:AddSection(scroll, LO["Quest Tracker"])

    C:AddDescription(section, LO["Position and display settings for the objective tracker."])

    C:AddToggle(section, {
        label = LO["Show Header Background"],
        desc = LO["Show/hide the decorative header background texture."],
        getFunc = function()
            return C:GetDBValue("questtracker.show_header") ~= false
        end,
        setFunc = function(val)
            C:SetDBValue("questtracker.show_header", val)
            RefreshQT()
        end,
    })

    C:AddDropdown(section, {
        label = LO["Anchor Point"],
        desc = LO["Screen anchor point for the quest tracker."],
        dbPath = "questtracker.anchor",
        values = anchorValues,
        callback = RefreshQT,
    })

    C:AddSlider(section, {
        label = LO["X Position"],
        dbPath = "questtracker.x",
        min = -500, max = 500, step = 1,
        width = 200,
        callback = RefreshQT,
    })

    C:AddSlider(section, {
        label = "Y Position",
        dbPath = "questtracker.y",
        min = -500, max = 500, step = 1,
        width = 200,
        callback = RefreshQT,
    })

    C:AddButton(section, {
        label = LO["Reset Position"],
        width = 160,
        callback = function()
            C:SetDBValue("questtracker.anchor", "TOPRIGHT")
            C:SetDBValue("questtracker.x", -140)
            C:SetDBValue("questtracker.y", -255)
            RefreshQT()
            -- Refresh tab to update controls
            Panel:SelectTab("questtracker")
        end,
    })
end

-- Register the tab
Panel:RegisterTab("questtracker", LO["Quest Tracker"], BuildQuesttrackerTab, 10)
