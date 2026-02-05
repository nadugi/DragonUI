--[[
================================================================================
DragonUI Options - Profiles
================================================================================
AceDBOptions profile management integration.
Based on ElvUI_OptionsUI pattern.
================================================================================
]]

-- Access the main DragonUI addon
local addon = DragonUI
if not addon then return end

-- ============================================================================
-- PROFILES OPTIONS
-- ============================================================================

-- This function should be called after addon.db is initialized
function addon:GetProfileOptions()
    if not self.db then
        return nil
    end
    
    -- Get standard profile options from AceDBOptions
    local profileOptions = LibStub("AceDBOptions-3.0"):GetOptionsTable(self.db)
    
    -- Customize the options
    profileOptions.name = "Profiles"
    profileOptions.desc = "Manage UI settings profiles."
    profileOptions.order = 99
    
    -- Modify profile selector text if it exists
    if profileOptions.args and profileOptions.args.profile then
        profileOptions.args.profile.name = "Active Profile"
        profileOptions.args.profile.desc = "Choose the profile to use for your settings."
    end
    
    -- Add reload warning
    profileOptions.args.reload_warning = {
        type = 'description',
        name = "\n|cffFFD700It's recommended to reload the UI after switching profiles.|r",
        order = 15
    }
    
    -- Add reload button
    profileOptions.args.reload_execute = {
        type = 'execute',
        name = "Reload UI",
        func = function()
            ReloadUI()
        end,
        order = 16
    }
    
    return profileOptions
end

print("|cFF00FF00[DragonUI]|r Profiles options loaded")
