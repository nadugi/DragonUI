local addon = select(2,...);

-- =================================================================
-- DRAGONUI GAME MENU BUTTON MODULE (WOW 3.3.5A)
-- =================================================================

-- Local variables for WoW 3.3.5a compatibility
local CreateFrame = CreateFrame
local GameMenuFrame = GameMenuFrame
local HideUIPanel = HideUIPanel

-- Button state
local dragonUIButton = nil
local buttonAdded = false
local buttonPositioned = false -- New flag to prevent multiple repositioning

-- List of all game menu buttons in order of appearance (WoW 3.3.5a)
local GAME_MENU_BUTTONS = {
    "GameMenuButtonHelp",
    "GameMenuButtonWhatsNew", 
    "GameMenuButtonStore",
    "GameMenuButtonOptions",
    "GameMenuButtonUIOptions", 
    "GameMenuButtonKeybindings",
    "GameMenuButtonMacros",
    "GameMenuButtonAddons",
    "GameMenuButtonLogout",
    "GameMenuButtonQuit",
    "GameMenuButtonContinue"
}

-- Function to find the correct position for the DragonUI button
local function FindInsertPosition()
    -- ALWAYS insert after the "Return to Game" (Continue) button at the end of the menu
    local afterButton = _G["GameMenuButtonContinue"]
    
    -- If Continue doesn't exist, insert after Quit
    if not afterButton then
        afterButton = _G["GameMenuButtonQuit"]
    end
    
    -- If Quit doesn't exist either, insert after Logout
    if not afterButton then
        afterButton = _G["GameMenuButtonLogout"]
    end
    
    return afterButton, nil -- No beforeButton since it goes at the end
end

-- Function to position the DragonUI button conservatively
local function PositionDragonUIButton()
    if not dragonUIButton then return end
    
    -- IMPORTANT: Only position once to prevent offset accumulation
    if buttonPositioned then 
        return 
    end
    
    local afterButton, beforeButton = FindInsertPosition()
    
    if not afterButton then
        -- Fallback: position at the end of the menu
        dragonUIButton:ClearAllPoints()
        dragonUIButton:SetPoint("TOP", GameMenuFrame, "TOP", 0, -200)
        buttonPositioned = true
        return
    end
    
    -- Position ONLY the DragonUI button immediately after the reference button
    dragonUIButton:ClearAllPoints()
    dragonUIButton:SetPoint("TOP", afterButton, "BOTTOM", 0, -1)
    
    -- MINIMALLY adjust the GameMenuFrame height ONLY once
    local buttonHeight = dragonUIButton:GetHeight() or 16
    local spacing = 1
    local currentHeight = GameMenuFrame:GetHeight()
    GameMenuFrame:SetHeight(currentHeight + buttonHeight + spacing)
    
    -- Since it's at the end of the menu, we don't need to move other buttons
    
    -- Mark as positioned to prevent future executions
    buttonPositioned = true
end

-- Function to open the DragonUI configuration interface
local function OpenDragonUIConfig()
    -- Close game menu first
    HideUIPanel(GameMenuFrame)
    
    -- Use ToggleOptionsUI which handles LoadOnDemand addon loading
    if addon and addon.ToggleOptionsUI then
        addon:ToggleOptionsUI()
        return
    end
    
    -- Fallback: Try slash command
    if SlashCmdList and SlashCmdList["DRAGONUI"] then
        SlashCmdList["DRAGONUI"]("config")
        return
    end
    
    print("|cFFFF0000[DragonUI]|r Unable to open configuration")
end

-- Main function to create the DragonUI button
local function CreateDragonUIButton()
    -- Check that it hasn't been created already
    if dragonUIButton or buttonAdded then 
        return true 
    end
    
    -- Check that GameMenuFrame is available
    if not GameMenuFrame then 
        return false 
    end
    
    -- Create the button with appropriate template for WoW 3.3.5a
    dragonUIButton = CreateFrame("Button", "DragonUIGameMenuButton", GameMenuFrame, "GameMenuButtonTemplate")
    
    -- Set the button text
    dragonUIButton:SetText("DragonUI")
    
    -- Set the width to match other buttons
    dragonUIButton:SetWidth(144) -- Standard width for game menu buttons in 3.3.5a
    
    -- Apply Dragonflight-style blue colors
    local fontString = dragonUIButton:GetFontString()
    if fontString then
        -- Dragonflight blue text color: RGB(100, 180, 255) 
        fontString:SetTextColor(0.39, 0.71, 1.0, 1.0)
        
        -- Soft blue shadow effect
        fontString:SetShadowColor(0.2, 0.4, 0.8, 0.8)
        fontString:SetShadowOffset(1, -1)
        
        -- Smaller font
        fontString:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")
    end
    
    -- Set hover/pressed colors with smaller font
    if dragonUIButton.SetNormalFontObject then
        dragonUIButton:SetNormalFontObject("GameFontNormal")
        dragonUIButton:SetHighlightFontObject("GameFontHighlight") 
    end
    
    -- Try to color the button background (3.3.5a compatible)
    local normalTexture = dragonUIButton:GetNormalTexture()
    if normalTexture then
        -- Soft blue tint for the background: RGB(50, 100, 200) with alpha 0.8
        normalTexture:SetVertexColor(0.2, 0.4, 0.8, 0.8)
    end
    
    local highlightTexture = dragonUIButton:GetHighlightTexture()
    if highlightTexture then
        -- Brighter blue tint on hover: RGB(80, 140, 255) with alpha 0.9
        highlightTexture:SetVertexColor(0.31, 0.55, 1.0, 0.9)
    end
    
    -- Set up additional visual effects for hover
    dragonUIButton:SetScript("OnEnter", function(self)
        local fontString = self:GetFontString()
        if fontString then
            -- Brighter color on hover: RGB(150, 200, 255)
            fontString:SetTextColor(0.59, 0.78, 1.0, 1.0)
        end
    end)
    
    dragonUIButton:SetScript("OnLeave", function(self)
        local fontString = self:GetFontString()
        if fontString then
            -- Revert to normal color: RGB(100, 180, 255)
            fontString:SetTextColor(0.39, 0.71, 1.0, 1.0)
        end
    end)
    
    -- Set the click handler
    dragonUIButton:SetScript("OnClick", function(self, button)
        if button == "LeftButton" then
            OpenDragonUIConfig()
        end
    end)
    
    -- Position only the DragonUI button
    PositionDragonUIButton()
    
    buttonAdded = true

    return true
end

-- Function to attempt creating the button with retries
local function TryCreateButton()
    local attempts = 0
    local maxAttempts = 5
    
    local function attempt()
        attempts = attempts + 1
        
        if CreateDragonUIButton() then
            return -- Success
        end
        
        if attempts < maxAttempts then
            -- Retry after delay
            addon:After(0.5, attempt)
        else
           
        end
    end
    
    attempt()
end

-- Event frame to handle initialization
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_LOGIN")

eventFrame:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" and arg1 == "DragonUI" then
        -- Try to add the button after DragonUI loads
        TryCreateButton()
        
    elseif event == "PLAYER_LOGIN" then
        -- Second attempt after login
        addon:After(1.0, function()
            if not buttonAdded then
                TryCreateButton()
            end
        end)
        
        self:UnregisterEvent("PLAYER_LOGIN")
    end
end)

-- Phase 2: hooksecurefunc instead of direct .Show override to avoid taint
hooksecurefunc(GameMenuFrame, "Show", function(self)
    -- Try to create the button if it doesn't exist
    if not buttonAdded then
        CreateDragonUIButton()
    elseif dragonUIButton then
        -- If it already exists, ensure it's visible but DO NOT reposition
        dragonUIButton:Show()
        -- Commented out to prevent accumulation bug: PositionDragonUIButton()
    end
end)

