local addon = select(2, ...)
addon._dir = "Interface\\AddOns\\DragonUI\\assets\\"

-- ============================================================================
-- MODULE STATE TRACKING (AT FILE SCOPE - FOLLOWING ELVUI PATTERN)
-- ============================================================================
-- This module table is defined at file scope to be accessible from outside
-- the initialization function, following the pattern used by other DragonUI
-- modules (stance.lua, petbar.lua, vehicle.lua, etc.)

local MainbarsModule = {
    initialized = false,
    applied = false,
    originalStates = {},
    registeredEvents = {},
    hooks = {},
    stateDrivers = {},
    frames = {},
    eventFrames = {},
    originalScales = {},
    originalPositions = {},
    originalTextures = {},
    originalVisibility = {},
    actionBarFrames = nil
}
addon.MainbarsModule = MainbarsModule  -- Expose globally for external access

-- Register with ModuleRegistry (if available)
if addon.RegisterModule then
    addon:RegisterModule("mainbars", MainbarsModule, "Main Bars", "Main action bars, status bars, scaling and positioning")
end

-- ============================================================================
-- CONFIGURATION FUNCTIONS (ALWAYS AVAILABLE)
-- ============================================================================

-- Bar sizing constants (used by CalculateFrameSize, ArrangeActionBarButtons, and grid layout)
local ACTION_BUTTON_SIZE = 36  -- Default WoW 3.3.5a action button size
local ACTION_BUTTON_SPACING = 7  -- Spacing between buttons (matches actionbutton_setup)
-- Symmetric padding: half on each side of the button grid.
-- The NineSlice BorderArt resizes with the frame (anchored TOPLEFT/BOTTOMRIGHT),
-- so buttons just need small equal margins.  4 = 2px left + 2px right.
local DEFAULT_PADDING = 4

-- ============================================================================
-- GRID LAYOUT SYSTEM (ported from old contributor)
-- ============================================================================

-- Calculate frame size needed for a given row/column layout
local function CalculateFrameSize(rows, columns, widthPadding, heightPadding)
    widthPadding = widthPadding or DEFAULT_PADDING
    heightPadding = heightPadding or DEFAULT_PADDING
    local width = (ACTION_BUTTON_SIZE * columns) + (ACTION_BUTTON_SPACING * (columns - 1)) + widthPadding
    local height = (ACTION_BUTTON_SIZE * rows) + (ACTION_BUTTON_SPACING * (rows - 1)) + heightPadding
    return width, height
end

-- Arrange action bar buttons in a grid layout
-- buttonPrefix: e.g. "ActionButton", "MultiBarBottomLeftButton"
-- parentFrame: frame to resize (optional)
-- anchorFrame: frame to anchor button positions relative to
-- rows/columns: grid dimensions
-- buttonsShown: number of buttons to display (1-12)
-- widthPadding: total horizontal padding, split equally left/right (default 4 = 2px each side)
-- heightPadding: total vertical padding, split equally top/bottom
function addon.ArrangeActionBarButtons(buttonPrefix, parentFrame, anchorFrame, rows, columns, buttonsShown, widthPadding, heightPadding)
    if InCombatLockdown() then return end

    buttonsShown = math.max(1, math.min(12, buttonsShown or 12))
    rows = math.max(1, rows or 1)
    columns = math.max(1, columns or 12)
    widthPadding = widthPadding or DEFAULT_PADDING
    heightPadding = heightPadding or DEFAULT_PADDING

    -- Symmetric: half padding on each side
    local leftPad = math.floor(widthPadding / 2)
    local bottomPad = math.floor(heightPadding / 2)

    for index = 1, NUM_ACTIONBAR_BUTTONS do
        local button = _G[buttonPrefix .. index]
        if button then
            if index <= buttonsShown then
                -- Calculate grid position (0-based)
                local gridIndex = index - 1
                local row = math.floor(gridIndex / columns)
                local col = gridIndex % columns

                local x = leftPad + (col * (ACTION_BUTTON_SIZE + ACTION_BUTTON_SPACING))
                local y = bottomPad + (row * (ACTION_BUTTON_SIZE + ACTION_BUTTON_SPACING))

                button:ClearAllPoints()
                button:SetPoint('BOTTOMLEFT', anchorFrame, 'BOTTOMLEFT', x, y)
                button:Show()
            else
                -- Move off-screen and hide (like DragonflightUI)
                button:ClearAllPoints()
                button:SetPoint("CENTER", UIParent, "BOTTOM", 0, -666)
                button:Hide()
            end
        end
    end

    -- Resize parent frame to fit the VISIBLE layout (not max columns)
    if parentFrame and parentFrame.SetSize then
        local effectiveCols = math.min(columns, buttonsShown)
        local width, height = CalculateFrameSize(rows, effectiveCols, widthPadding, heightPadding)
        parentFrame:SetSize(width, height)
    end
end

local function GetModuleConfig()
    return addon:GetModuleConfig("mainbars")
end

local function IsModuleEnabled()
    return addon:IsModuleEnabled("mainbars")
end
-- ============================================================================
-- PET BAR FUNCTION (ALWAYS AVAILABLE)
-- ============================================================================

-- Update pet bar visibility and positioning
function addon.UpdatePetBarVisibility()
    if InCombatLockdown() then
        return
    end

    local petBar = PetActionBarFrame
    if not petBar then
        return
    end

    -- Check if player has a pet or is in a vehicle
    local hasPet = UnitExists("pet") and UnitIsVisible("pet")
    local inVehicle = UnitInVehicle("player")
    local hasVehicleActionBar = HasVehicleActionBar and HasVehicleActionBar()

    -- Show pet bar if player has a pet or relevant vehicle controls
    if hasPet or (inVehicle and hasVehicleActionBar) then
        if not petBar:IsShown() then
            petBar:Show()
        end

        -- Ensure proper positioning and scaling
        local db = addon.db and addon.db.profile and addon.db.profile.mainbars
        if db and db.scale_petbar then
            petBar:SetScale(db.scale_petbar)
        end

        -- Update pet action buttons
        for i = 1, NUM_PET_ACTION_SLOTS do
            local button = _G["PetActionButton" .. i]
            if button then
                button:Show()
            end
        end
    else
        -- Hide pet bar when no pet and not in vehicle
        if petBar:IsShown() then
            petBar:Hide()
        end
    end
end

-- ============================================================================
-- ONLY EXECUTE IF MODULE IS ENABLED
-- ============================================================================
-- ============================================================================
-- ONLY EXECUTE IF MODULE IS ENABLED
-- ============================================================================

-- Check if module is enabled when addon loads
local function InitializeMainbars()
    if not IsModuleEnabled() then
        return -- DO NOTHING if disabled
    end
    
    -- Check if already initialized
    if MainbarsModule.initialized then
        return
    end

    -- ============================================================================
    -- EVERYTHING BELOW ONLY RUNS IF MODULE IS ENABLED
    -- ============================================================================

    -- CORE COMPONENTS
    local config = addon.config;
    local event = addon.package;
    local do_action = addon.functions;
    local select = select;
    local pairs = pairs;
    local ipairs = ipairs;
    local format = string.format;
    local UIParent = UIParent;
    local hooksecurefunc = hooksecurefunc;
    local UnitFactionGroup = UnitFactionGroup;
    local _G = getfenv(0);

    -- constants
    local faction = UnitFactionGroup('player');
    local MainMenuBarMixin = {};
    addon.MainMenuBarMixin = MainMenuBarMixin;  -- Store globally for access
    local pUiMainBar = CreateFrame('Frame', 'pUiMainBar', UIParent, 'MainMenuBarUiTemplate');
    addon.pUiMainBar = pUiMainBar;  -- Store globally for access

    local pUiMainBarArt = CreateFrame('Frame', 'pUiMainBarArt', pUiMainBar);

    -- ACTION BAR SYSTEM
    addon.ActionBarFrames = {
        mainbar = nil,
        rightbar = nil,
        leftbar = nil,
        bottombarleft = nil,
        bottombarright = nil,
        repexpbar = nil
    }

    -- Set initial scale and properties
    pUiMainBar:SetScale(config.mainbars.scale_actionbar);
    pUiMainBarArt:SetFrameStrata('HIGH');
    pUiMainBarArt:SetFrameLevel(pUiMainBar:GetFrameLevel() + 4);
    pUiMainBarArt:SetAllPoints(pUiMainBar);
    -- CRITICAL: Disable mouse to avoid dead zone on icons
    pUiMainBarArt:EnableMouse(false);

    -- ============================================================================
    -- ALL THE MAINBARS FUNCTIONS (ONLY WHEN ENABLED)
    -- ============================================================================

    -- Use the global UpdateGryphonStyle function
    local UpdateGryphonStyle = addon.UpdateGryphonStyle

    -- ============================================================================
    -- ORIGINAL STATE STORAGE
    -- ============================================================================

    local function StoreOriginalMainbarStates()
        -- Store MainMenuBar state
        if MainMenuBar then
            MainbarsModule.originalStates.MainMenuBar = {
                parent = MainMenuBar:GetParent(),
                scale = MainMenuBar:GetScale(),
                points = {},
                mouseEnabled = MainMenuBar:IsMouseEnabled(),
                movable = MainMenuBar:IsMovable(),
                userPlaced = MainMenuBar:IsUserPlaced()
            }
            for i = 1, MainMenuBar:GetNumPoints() do
                local point, relativeTo, relativePoint, xOfs, yOfs = MainMenuBar:GetPoint(i)
                table.insert(MainbarsModule.originalStates.MainMenuBar.points,
                    {point, relativeTo, relativePoint, xOfs, yOfs})
            end
        end

        -- Store other action bars states
        local bars = {MultiBarRight, MultiBarLeft, MultiBarBottomLeft, MultiBarBottomRight, PetActionBarFrame}
        for _, bar in pairs(bars) do
            if bar then
                local name = bar:GetName()
                MainbarsModule.originalStates[name] = {
                    parent = bar:GetParent(),
                    scale = bar:GetScale(),
                    points = {},
                    mouseEnabled = bar:IsMouseEnabled(),
                    movable = bar:IsMovable(),
                    userPlaced = bar:IsUserPlaced()
                }
                for i = 1, bar:GetNumPoints() do
                    local point, relativeTo, relativePoint, xOfs, yOfs = bar:GetPoint(i)
                    table.insert(MainbarsModule.originalStates[name].points,
                        {point, relativeTo, relativePoint, xOfs, yOfs})
                end
            end
        end
    end

    -- ============================================================================
    -- RESTORE ORIGINAL STATE (When disabled)
    -- ============================================================================

    local function RestoreMainbarsSystem()
        if not MainbarsModule.applied then
            return
        end

        -- Hide DragonUI frames
        if MainbarsModule.frames.pUiMainBar then
            MainbarsModule.frames.pUiMainBar:Hide()
            MainbarsModule.frames.pUiMainBar = nil
        end
        if MainbarsModule.frames.pUiMainBarArt then
            MainbarsModule.frames.pUiMainBarArt:Hide()
            MainbarsModule.frames.pUiMainBarArt = nil
        end

        -- Clear ActionBarFrames
        if MainbarsModule.actionBarFrames then
            for name, frame in pairs(MainbarsModule.actionBarFrames) do
                if frame and frame.Hide then
                    frame:Hide()
                end
            end
            MainbarsModule.actionBarFrames = nil
            addon.ActionBarFrames = nil
        end

        -- Restore original states
        for frameName, state in pairs(MainbarsModule.originalStates) do
            local frame = _G[frameName]
            if frame and state then
                frame:SetParent(state.parent or UIParent)
                frame:SetScale(state.scale or 1.0)
                frame:ClearAllPoints()
                if state.points and #state.points > 0 then
                    for _, pointData in pairs(state.points) do
                        frame:SetPoint(pointData[1], pointData[2], pointData[3], pointData[4], pointData[5])
                    end
                else
                    -- Default positioning for action bars
                    if frameName == "MainMenuBar" then
                        frame:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, 0)
                    elseif frameName == "MultiBarRight" then
                        frame:SetPoint("RIGHT", UIParent, "RIGHT", -6, 0)
                    elseif frameName == "MultiBarLeft" then
                        frame:SetPoint("RIGHT", MultiBarRight, "LEFT", -6, 0)
                    elseif frameName == "MultiBarBottomLeft" then
                        frame:SetPoint("BOTTOMLEFT", ActionButton1, "TOPLEFT", 0, 6)
                    elseif frameName == "MultiBarBottomRight" then
                        frame:SetPoint("BOTTOMLEFT", MultiBarBottomLeftButton1, "TOPLEFT", 0, 6)
                    end
                end
                frame:EnableMouse(state.mouseEnabled ~= false)
                frame:SetMovable(state.movable ~= false)
                frame:SetUserPlaced(state.userPlaced == true)
            end
        end

        -- Show action bars
        local bars = {MainMenuBar, MultiBarRight, MultiBarLeft, MultiBarBottomLeft, MultiBarBottomRight}
        for _, bar in pairs(bars) do
            if bar then
                bar:Show()
            end
        end

        MainbarsModule.originalStates = {}
        MainbarsModule.applied = false

    end

    -- ============================================================================
    -- CORE MAINBAR FUNCTIONS (From working code)
    -- ============================================================================

   function MainMenuBarMixin:actionbutton_setup()
    -- Phase 3D: Defensive combat guard — secure frame operations must not run in combat
    if InCombatLockdown() then return end
    for _, obj in ipairs({MainMenuBar:GetChildren(), MainMenuBarArtFrame:GetChildren()}) do
        obj:SetParent(pUiMainBar)
    end

    for index = 1, NUM_ACTIONBAR_BUTTONS do
        pUiMainBar:SetFrameRef('ActionButton' .. index, _G['ActionButton' .. index])
    end

    -- Apply SetThreeSlice only if the background is NOT hidden
    local shouldHideBackground = addon.db and addon.db.profile and addon.db.profile.buttons and 
                                addon.db.profile.buttons.hide_main_bar_background
    
    -- Store divider textures for bar-size management
    addon.MainBarDividers = addon.MainBarDividers or {}

    if not shouldHideBackground then
        for index = 1, NUM_ACTIONBAR_BUTTONS - 1 do
            local ActionButtons = _G['ActionButton' .. index]
            do_action.SetThreeSlice(ActionButtons);
            -- Tag divider textures so update_main_bar_background skips them
            if pUiMainBar.divider_top then pUiMainBar.divider_top._isDragonUIDivider = true end
            if pUiMainBar.divider_mid then pUiMainBar.divider_mid._isDragonUIDivider = true end
            if pUiMainBar.divider_bottom then pUiMainBar.divider_bottom._isDragonUIDivider = true end
            -- Store reference to dividers created on pUiMainBar
            addon.MainBarDividers[index] = {
                top = pUiMainBar.divider_top,
                mid = pUiMainBar.divider_mid,
                bottom = pUiMainBar.divider_bottom,
            }
        end
    end

    for index = 2, NUM_ACTIONBAR_BUTTONS do
        local ActionButtons = _G['ActionButton' .. index]
        ActionButtons:SetParent(pUiMainBar)
        ActionButtons:SetClearPoint('LEFT', _G['ActionButton' .. (index - 1)], 'RIGHT', 7, 0)

        local BottomLeftButtons = _G['MultiBarBottomLeftButton' .. index]
        BottomLeftButtons:SetClearPoint('LEFT', _G['MultiBarBottomLeftButton' .. (index - 1)], 'RIGHT', 7, 0)

        local BottomRightButtons = _G['MultiBarBottomRightButton' .. index]
        BottomRightButtons:SetClearPoint('LEFT', _G['MultiBarBottomRightButton' .. (index - 1)], 'RIGHT', 7, 0)

        local BonusActionButtons = _G['BonusActionButton' .. index]
        BonusActionButtons:SetClearPoint('LEFT', _G['BonusActionButton' .. (index - 1)], 'RIGHT', 7, 0)
    end
end

    function MainMenuBarMixin:actionbar_art_setup()
        -- setup art frames - FIXED
        MainMenuBarArtFrame:SetParent(pUiMainBarArt)  -- Goes to the art container
        
        -- CRITICAL: Gryphons must go to pUiMainBarArt, NOT pUiMainBar
        for _, art in pairs({MainMenuBarLeftEndCap, MainMenuBarRightEndCap}) do
            art:SetParent(pUiMainBarArt)  -- To the correct art container
            art:SetDrawLayer('OVERLAY', 7)  -- Higher layer than ARTWORK
        end

        -- apply background settings
        self:update_main_bar_background()

        -- apply gryphon styling
        UpdateGryphonStyle()
    end

    function MainMenuBarMixin:update_main_bar_background()
    local alpha = (addon.db and addon.db.profile and addon.db.profile.buttons and
                      addon.db.profile.buttons.hide_main_bar_background) and 0 or 1

    -- handle button background textures
    for i = 1, NUM_ACTIONBAR_BUTTONS do
        local button = _G["ActionButton" .. i]
        if button then
            if button.NormalTexture then
                button.NormalTexture:SetAlpha(alpha)
            end
            
            -- Also hide textures applied by SetThreeSlice
            local regions = {button:GetRegions()}
            for j = 1, #regions do
                local region = regions[j]
                if region and region:GetObjectType() == "Texture" then
                    local drawLayer = region:GetDrawLayer()
                    -- Hide background and artwork textures that aren't icons
                    if (drawLayer == "BACKGROUND" or drawLayer == "ARTWORK") and region ~= button:GetNormalTexture() then
                        local texPath = region:GetTexture()
                        if texPath and not string.find(texPath, "ICON") and not string.find(texPath, "Interface\\Icons") then
                            region:SetAlpha(alpha)
                        end
                    end
                end
            end
        end
    end

    if pUiMainBar then
        -- hide loose textures within pUiMainBar (skip bar-size managed dividers)
        for i = 1, pUiMainBar:GetNumRegions() do
            local region = select(i, pUiMainBar:GetRegions())
            if region and region:GetObjectType() == "Texture" and not region._isDragonUIDivider then
                local texPath = region:GetTexture()
                if texPath and not string.find(texPath, "ICON") then
                    region:SetAlpha(alpha)
                end
            end
        end

        -- hide child frame textures with protection for UI elements
        for i = 1, pUiMainBar:GetNumChildren() do
            local child = select(i, pUiMainBar:GetChildren())
            local name = child and child:GetName()

            -- protect important UI elements from being hidden
            if child and name ~= "pUiMainBarArt" and not string.find(name or "", "ActionButton") and name ~=
                "MultiBarBottomLeft" and name ~= "MultiBarBottomRight" and name ~= "MicroButtonAndBagsBar" and
                not string.find(name or "", "MicroButton") and not string.find(name or "", "Bag") and name ~=
                "CharacterMicroButton" and name ~= "SpellbookMicroButton" and name ~= "TalentMicroButton" and name ~=
                "AchievementMicroButton" and name ~= "bagsFrame" and name ~= "MainMenuBarBackpackButton" and name ~=
                "QuestLogMicroButton" and name ~= "SocialsMicroButton" and name ~= "PVPMicroButton" and name ~=
                "LFGMicroButton" and name ~= "MainMenuMicroButton" and name ~= "HelpMicroButton" and name ~=
                "MainMenuExpBar" and name ~= "ReputationWatchBar" then

                for j = 1, child:GetNumRegions() do
                    local region = select(j, child:GetRegions())
                    if region and region:GetObjectType() == "Texture" then
                        region:SetAlpha(alpha)
                    end
                end
            end
        end
    end
end

    function MainMenuBarMixin:actionbar_setup()
        ActionButton1:SetParent(pUiMainBar)
        ActionButton1:SetClearPoint('BOTTOMLEFT', pUiMainBar, 2, 2)

        if config.buttons.pages.show then
            do_action.SetNumPagesButton(ActionBarUpButton, pUiMainBarArt, 'pageuparrow', 8)
            do_action.SetNumPagesButton(ActionBarDownButton, pUiMainBarArt, 'pagedownarrow', -14)

            MainMenuBarPageNumber:SetParent(pUiMainBarArt)
            MainMenuBarPageNumber:SetClearPoint('CENTER', ActionBarDownButton, -1, 12)
            local pagesFont = config.buttons.pages.font
            MainMenuBarPageNumber:SetFont(pagesFont[1], pagesFont[2], pagesFont[3])
            MainMenuBarPageNumber:SetShadowColor(0, 0, 0, 1)
            MainMenuBarPageNumber:SetShadowOffset(1.2, -1.2)
            MainMenuBarPageNumber:SetDrawLayer('OVERLAY', 7)
        else
            ActionBarUpButton:Hide();
            ActionBarDownButton:Hide();
            MainMenuBarPageNumber:Hide();
        end

        MultiBarBottomRight:EnableMouse(false)
        MultiBarRight:SetScale(config.mainbars.scale_rightbar)
        MultiBarLeft:SetScale(config.mainbars.scale_leftbar)
        if MultiBarBottomLeft then
            MultiBarBottomLeft:SetScale(config.mainbars.scale_bottomleft or 0.9)
        end
        if MultiBarBottomRight then
            MultiBarBottomRight:SetScale(config.mainbars.scale_bottomright or 0.9)
        end
    end

    -- Register event to update page number when action bar page changes
    event:RegisterEvents(function()
        MainMenuBarPageNumber:SetText(GetActionBarPage());
    end,
        'ACTIONBAR_PAGE_CHANGED'
    );

    -- Helper: position buttons for a left/right bar using chain anchoring.
    -- Position side bar (left/right) buttons in a grid layout using columns.
    -- Uses TOPLEFT origin so button 1 is at top-left (natural reading order).
    -- Columns controls layout: 1 = vertical, 12 = horizontal, anything between = grid.
    local function PositionSideBarButtons(barPrefix, barFrame, containerFrame, count, columns)
        if not barFrame then return end

        count   = math.max(1, math.min(12, count or 12))
        columns = math.max(1, math.min(12, columns or 1))

        -- Position visible buttons in a TOPLEFT grid
        for index = 1, NUM_ACTIONBAR_BUTTONS do
            local button = _G[barPrefix .. index]
            if button then
                if index <= count then
                    local gridIndex = index - 1
                    local row = math.floor(gridIndex / columns)
                    local col = gridIndex % columns
                    local x =  col * (ACTION_BUTTON_SIZE + ACTION_BUTTON_SPACING)
                    local y = -(row * (ACTION_BUTTON_SIZE + ACTION_BUTTON_SPACING))
                    button:ClearAllPoints()
                    button:SetPoint('TOPLEFT', barFrame, 'TOPLEFT', x, y)
                    button:Show()
                else
                    button:ClearAllPoints()
                    button:SetPoint("CENTER", UIParent, "BOTTOM", 0, -666)
                    button:Hide()
                end
            end
        end

        -- Anchor bar frame to container
        if containerFrame then
            barFrame:ClearAllPoints()
            barFrame:SetPoint("TOPLEFT", containerFrame, "TOPLEFT", 0, 0)
        end
    end

    function addon.PositionActionBars()
        if InCombatLockdown() then
            return
        end

        local db = addon.db and addon.db.profile and addon.db.profile.mainbars
        if not db then
            return
        end

        -- Right bar: grid layout using columns (horizontal = 12 cols, vertical = 1 col)
        if MultiBarRight then
            local containerFrame = addon.ActionBarFrames and addon.ActionBarFrames.rightbar
            local rightCfg = db.right or {}
            PositionSideBarButtons("MultiBarRightButton", MultiBarRight, containerFrame,
                rightCfg.buttons_shown or 12, rightCfg.columns or 1)
        end

        -- Left bar: grid layout using columns
        if MultiBarLeft then
            local containerFrame = addon.ActionBarFrames and addon.ActionBarFrames.leftbar
            local leftCfg = db.left or {}
            PositionSideBarButtons("MultiBarLeftButton", MultiBarLeft, containerFrame,
                leftCfg.buttons_shown or 12, leftCfg.columns or 1)
        end
    end

    -- Resize a container frame to a new size while keeping the bar anchored to it
    -- in the SAME screen position.  Uses GetCenter() before/after to compensate.
    local function ResizeContainerStable(container, newW, newH)
        if not container then return end
        local oldW, oldH = container:GetWidth(), container:GetHeight()
        if oldW == newW and oldH == newH then return end -- nothing to do

        -- Remember the visual center of the container in screen pixels
        local cx, cy = container:GetCenter()
        if not cx or not cy then
            -- Frame not yet shown; just resize without compensation
            container:SetSize(newW, newH)
            return
        end

        -- Resize
        container:SetSize(newW, newH)

        -- After resize the anchor point is the same but the visual center
        -- shifted because the frame grew/shrank around its anchor.  Read
        -- the NEW center and calculate the delta.
        local cx2, cy2 = container:GetCenter()
        if not cx2 or not cy2 then return end

        local dx = cx - cx2
        local dy = cy - cy2
        if math.abs(dx) < 0.5 and math.abs(dy) < 0.5 then return end

        -- Shift the anchor to cancel the visual movement
        local point, rel, relPoint, px, py = container:GetPoint(1)
        if point then
            container:SetPoint(point, rel, relPoint, (px or 0) + dx, (py or 0) + dy)
        end
    end

    -- Compute container (overlay) size for a bar with the given columns/count.
    -- No padding: buttons fill the container edge-to-edge.
    local function BarContainerSize(cols, count)
        cols  = math.max(1, cols or 1)
        count = math.max(1, count or 12)
        local effectiveCols = math.min(cols, count)
        local rows = math.ceil(count / cols)
        local w = effectiveCols * ACTION_BUTTON_SIZE + (effectiveCols - 1) * ACTION_BUTTON_SPACING
        local h = rows * ACTION_BUTTON_SIZE + (rows - 1) * ACTION_BUTTON_SPACING
        return w, h
    end

    -- Resize container (editor overlay) frames to match current bar dimensions.
    -- Called when entering editor mode AND after layout changes so overlays stay in sync.
    -- Uses ResizeContainerStable to avoid shifting bars on screen.
    function addon.UpdateOverlaySizes()
        local db = addon.db and addon.db.profile and addon.db.profile.mainbars
        if not db then return end

        -- Main bar container: match pUiMainBar (includes padding for NineSlice)
        if addon.ActionBarFrames.mainbar and addon.pUiMainBar then
            local w, h = addon.pUiMainBar:GetSize()
            ResizeContainerStable(addon.ActionBarFrames.mainbar, w, h)
        end

        -- Right bar container (columns-based grid)
        if addon.ActionBarFrames.rightbar then
            local cfg = db.right or {}
            local w, h = BarContainerSize(cfg.columns or 1, cfg.buttons_shown or 12)
            ResizeContainerStable(addon.ActionBarFrames.rightbar, w, h)
        end

        -- Left bar container (columns-based grid)
        if addon.ActionBarFrames.leftbar then
            local cfg = db.left or {}
            local w, h = BarContainerSize(cfg.columns or 1, cfg.buttons_shown or 12)
            ResizeContainerStable(addon.ActionBarFrames.leftbar, w, h)
        end

        -- Bottom left container
        if addon.ActionBarFrames.bottombarleft then
            local cfg = db.bottom_left or {}
            local w, h = BarContainerSize(cfg.columns or 12, cfg.buttons_shown or 12)
            ResizeContainerStable(addon.ActionBarFrames.bottombarleft, w, h)
        end

        -- Bottom right container
        if addon.ActionBarFrames.bottombarright then
            local cfg = db.bottom_right or {}
            local w, h = BarContainerSize(cfg.columns or 12, cfg.buttons_shown or 12)
            ResizeContainerStable(addon.ActionBarFrames.bottombarright, w, h)
        end
    end

    function MainMenuBarMixin:statusbar_setup()
        -- Setup pet bar initial configuration
        if PetActionBarFrame then
            -- Ensure pet bar uses correct scale from config
            local db = addon.db and addon.db.profile and addon.db.profile.mainbars
            if db and db.scale_petbar then
                PetActionBarFrame:SetScale(db.scale_petbar)
            elseif config.mainbars.scale_petbar then
                PetActionBarFrame:SetScale(config.mainbars.scale_petbar)
            end

            -- Enable mouse interaction
            PetActionBarFrame:EnableMouse(true)
        end

        -- Initial setup for XP/Rep bars with NEW style sizes
        if MainMenuExpBar then
            MainMenuExpBar:SetClearPoint('BOTTOM', UIParent, 0, 6)
            MainMenuExpBar:SetFrameLevel(1) -- Lower level for editor overlay visibility
            -- Set NEW style size immediately
            MainMenuExpBar:SetSize(537, 10)

            if MainMenuBarExpText then
                MainMenuBarExpText:SetParent(MainMenuExpBar)
                -- Text will be positioned later based on style
            end
        end

        -- Setup reputation bar with NEW style sizes
        if ReputationWatchBar then
            ReputationWatchBar:SetFrameLevel(1) -- Lower level for editor overlay visibility
            -- Set NEW style size immediately
            ReputationWatchBar:SetSize(537, 10)

            if ReputationWatchStatusBar then
                -- Set NEW style size for status bar too
                ReputationWatchStatusBar:SetSize(537, 10)

                -- CRITICAL: Configure reputation text properly from the start
                if ReputationWatchStatusBarText then
                    -- Ensure correct parent
                    ReputationWatchStatusBarText:SetParent(ReputationWatchStatusBar)
                    -- Set reasonable layering - not excessively high
                    ReputationWatchStatusBarText:SetDrawLayer("OVERLAY", 2)
                    -- Position for NEW style (offset +1)
                    ReputationWatchStatusBarText:SetClearPoint('CENTER', ReputationWatchStatusBar, 'CENTER', 0, 1)
                    -- IMPORTANT: Hide by default (only show on hover)
                    ReputationWatchStatusBarText:Hide()
                end
            end
        end
    end

    -- Connect XP/Rep bars to the editor system
    local function ConnectBarsToEditor()
        if not addon.ActionBarFrames.repexpbar then
            return
        end

        local mainMenuExpBar = MainMenuExpBar
        if mainMenuExpBar then
            mainMenuExpBar:SetParent(addon.ActionBarFrames.repexpbar)
            mainMenuExpBar:ClearAllPoints()
            mainMenuExpBar:SetSize(537, 10)
            mainMenuExpBar:SetFrameLevel(1)
            mainMenuExpBar:SetScale(0.9)
            mainMenuExpBar:SetFrameStrata("MEDIUM")

            -- CORRECT BEHAVIOR: Initial position
            mainMenuExpBar:SetPoint("CENTER", addon.ActionBarFrames.repexpbar, "CENTER", 0, 0)
        end

        local repWatchBar = ReputationWatchBar
        if repWatchBar then
            repWatchBar:SetParent(addon.ActionBarFrames.repexpbar)
            repWatchBar:ClearAllPoints()
            repWatchBar:SetSize(537, 10)
            repWatchBar:SetScale(0.9)
            repWatchBar:SetFrameLevel(1)
            repWatchBar:SetFrameStrata("MEDIUM")

            -- CORRECT BEHAVIOR: Rep goes on top, then UpdateBarPositions adjusts XP
            repWatchBar:SetPoint("CENTER", addon.ActionBarFrames.repexpbar, "CENTER", 0, 0)

            if ReputationWatchStatusBar then
                ReputationWatchStatusBar:SetSize(537, 10)

                if ReputationWatchStatusBarText then
                    ReputationWatchStatusBarText:SetParent(ReputationWatchStatusBar)
                    ReputationWatchStatusBarText:SetDrawLayer("OVERLAY", 2)
                    ReputationWatchStatusBarText:SetClearPoint('CENTER', ReputationWatchStatusBar, 'CENTER', 0, 1)
                    ReputationWatchStatusBarText:Hide()
                end
            end
        end
    end

    -- Force reputation text configuration (ensures text is properly configured but hidden by default)
    local function ForceReputationTextConfiguration()
        if ReputationWatchStatusBarText and ReputationWatchStatusBar then
            -- Force correct parent
            ReputationWatchStatusBarText:SetParent(ReputationWatchStatusBar)
            -- Force reasonable layering - not excessively high
            ReputationWatchStatusBarText:SetDrawLayer("OVERLAY", 2)
            -- Force correct positioning for NEW style
            ReputationWatchStatusBarText:SetClearPoint('CENTER', ReputationWatchStatusBar, 'CENTER', 0, 1)
            -- IMPORTANT: Hide by default - only show on hover (Blizzard handles this)
            ReputationWatchStatusBarText:Hide()
        end
    end

    -- Update bar positioning when needed
    local function UpdateBarPositions()
        if not addon.ActionBarFrames.repexpbar then
            return
        end

        local mainMenuExpBar = MainMenuExpBar
        local repWatchBar = ReputationWatchBar

        if repWatchBar and repWatchBar:IsShown() then
            -- When Rep is visible: Rep takes the original XP position (center)
            repWatchBar:ClearAllPoints()
            repWatchBar:SetSize(537, 10)
            repWatchBar:SetScale(0.9)
            repWatchBar:SetFrameLevel(1)
            repWatchBar:SetPoint("CENTER", addon.ActionBarFrames.repexpbar, "CENTER", 0, -3)

            -- XP se mueve hacia abajo
            if mainMenuExpBar then
                mainMenuExpBar:ClearAllPoints()
                mainMenuExpBar:SetSize(537, 10)
                mainMenuExpBar:SetFrameLevel(1)
                mainMenuExpBar:SetScale(0.9)
                mainMenuExpBar:SetPoint("CENTER", addon.ActionBarFrames.repexpbar, "CENTER", 0, -22)
            end

            if ReputationWatchStatusBar then
                ReputationWatchStatusBar:SetSize(537, 10)

                if ReputationWatchStatusBarText then
                    ReputationWatchStatusBarText:SetParent(ReputationWatchStatusBar)
                    ReputationWatchStatusBarText:SetDrawLayer("OVERLAY", 2)
                    ReputationWatchStatusBarText:SetClearPoint('CENTER', ReputationWatchStatusBar, 'CENTER', 0, 1)
                    ReputationWatchStatusBarText:Hide()
                end
            end
        else
            -- When Rep is NOT visible: XP returns to center
            if mainMenuExpBar then
                mainMenuExpBar:ClearAllPoints()
                mainMenuExpBar:SetSize(537, 10)
                mainMenuExpBar:SetFrameLevel(1)
                mainMenuExpBar:SetScale(0.9)
                mainMenuExpBar:SetPoint("CENTER", addon.ActionBarFrames.repexpbar, "CENTER", 0, 0)
            end
        end
    end
   -- Specific function to disable MainMenuBarMaxLevelBar
    local function DisableMaxLevelBar()
        if MainMenuBarMaxLevelBar then
            MainMenuBarMaxLevelBar:Hide()
            MainMenuBarMaxLevelBar:EnableMouse(false)
            MainMenuBarMaxLevelBar:SetAlpha(0)
            -- Ensure it never interferes
            MainMenuBarMaxLevelBar:SetFrameLevel(0)
        end
    end

    local function RemoveBlizzardFrames()
        -- Disable MainMenuBarMaxLevelBar immediately
        DisableMaxLevelBar()
        
        local blizzFrames = {MainMenuBarPerformanceBar, MainMenuBarTexture0, MainMenuBarTexture1, MainMenuBarTexture2,
                             MainMenuBarTexture3, MainMenuBarMaxLevelBar, ReputationXPBarTexture1,
                             ReputationXPBarTexture2, ReputationXPBarTexture3, ReputationWatchBarTexture1,
                             ReputationWatchBarTexture2, ReputationWatchBarTexture3, MainMenuXPBarTexture1,
                             MainMenuXPBarTexture2, MainMenuXPBarTexture3, SlidingActionBarTexture0,
                             SlidingActionBarTexture1, BonusActionBarTexture0, BonusActionBarTexture1,
                             ShapeshiftBarLeft, ShapeshiftBarMiddle, ShapeshiftBarRight, PossessBackground1,
                             PossessBackground2}

        for _, frame in pairs(blizzFrames) do
            if frame then
                frame:SetAlpha(0)
                if frame == MainMenuBarMaxLevelBar then
                    frame:EnableMouse(false)
                    frame:Hide()
                    frame:SetFrameLevel(0)
                end
            end
        end
    end

    function MainMenuBarMixin:initialize()
        self:actionbutton_setup();
        self:actionbar_setup();
        self:actionbar_art_setup();
        self:statusbar_setup();
    end

    -- Create action bar container frames (RetailUI pattern)
    -- Uses BarContainerSize() for consistent column-based sizing.
    local function CreateActionBarFrames()
        -- Main bar - create a NEW container frame instead of using pUiMainBar directly
        addon.ActionBarFrames.mainbar = addon.CreateUIFrame(pUiMainBar:GetWidth(), pUiMainBar:GetHeight(), "MainBar")

        local db = addon.db and addon.db.profile and addon.db.profile.mainbars
        local rightCfg = db and db.right or {}
        local leftCfg  = db and db.left or {}
        local blCfg    = db and db.bottom_left or {}
        local brCfg    = db and db.bottom_right or {}

        local rW, rH  = BarContainerSize(rightCfg.columns or 1,  rightCfg.buttons_shown or 12)
        local lW, lH  = BarContainerSize(leftCfg.columns or 1,   leftCfg.buttons_shown or 12)
        local blW, blH = BarContainerSize(blCfg.columns or 12,   blCfg.buttons_shown or 12)
        local brW, brH = BarContainerSize(brCfg.columns or 12,   brCfg.buttons_shown or 12)

        addon.ActionBarFrames.rightbar       = addon.CreateUIFrame(rW, rH, "RightBar")
        addon.ActionBarFrames.leftbar        = addon.CreateUIFrame(lW, lH, "LeftBar")
        addon.ActionBarFrames.bottombarleft  = addon.CreateUIFrame(blW, blH, "BottomBarLeft")
        addon.ActionBarFrames.bottombarright = addon.CreateUIFrame(brW, brH, "BottomBarRight")

        -- RepExp bar container (RetailUI pattern)
        addon.ActionBarFrames.repexpbar = addon.CreateUIFrame(addon.ActionBarFrames.mainbar:GetWidth(), 10, "RepExpBar")
    end

    -- Position action bars to their container frames (initialization only - safe during addon load)
    -- Side bars and bottom bars use BOTTOMLEFT so buttons positioned from BOTTOMLEFT
    -- or TOPLEFT align exactly with the container edge.
    local function PositionActionBarsToContainers_Initial()
        -- Position main bar - anchor pUiMainBar to its container (CENTER - has padding/NineSlice)
        if pUiMainBar and addon.ActionBarFrames.mainbar then
            pUiMainBar:SetParent(UIParent)
            pUiMainBar:ClearAllPoints()
            pUiMainBar:SetPoint("CENTER", addon.ActionBarFrames.mainbar, "CENTER")
        end

        -- Position right bar - TOPLEFT matches PositionSideBarButtons grid origin
        if MultiBarRight and addon.ActionBarFrames.rightbar then
            MultiBarRight:SetParent(UIParent)
            MultiBarRight:ClearAllPoints()
            MultiBarRight:SetPoint("TOPLEFT", addon.ActionBarFrames.rightbar, "TOPLEFT", 0, 0)
        end

        -- Position left bar - TOPLEFT matches PositionSideBarButtons grid origin
        if MultiBarLeft and addon.ActionBarFrames.leftbar then
            MultiBarLeft:SetParent(UIParent)
            MultiBarLeft:ClearAllPoints()
            MultiBarLeft:SetPoint("TOPLEFT", addon.ActionBarFrames.leftbar, "TOPLEFT", 0, 0)
        end

        -- Position bottom left bar - CENTER so the bar is visually centered
        -- inside its container regardless of bar scale (0.9 default).
        if MultiBarBottomLeft and addon.ActionBarFrames.bottombarleft then
            MultiBarBottomLeft:SetParent(UIParent)
            MultiBarBottomLeft:ClearAllPoints()
            MultiBarBottomLeft:SetPoint("CENTER", addon.ActionBarFrames.bottombarleft, "CENTER", 0, 0)
        end

        -- Position bottom right bar - CENTER for same reason
        if MultiBarBottomRight and addon.ActionBarFrames.bottombarright then
            MultiBarBottomRight:SetParent(UIParent)
            MultiBarBottomRight:ClearAllPoints()
            MultiBarBottomRight:SetPoint("CENTER", addon.ActionBarFrames.bottombarright, "CENTER", 0, 0)
        end
    end

    -- Position action bars to their container frames
    local function PositionActionBarsToContainers()
        -- Only proceed if not in combat to avoid taint
        if InCombatLockdown() then
            return
        end

        -- Use the initial function for runtime positioning
        PositionActionBarsToContainers_Initial()
    end

    -- Apply saved positions from database (RetailUI pattern)
    local function ApplyActionBarPositions()
        -- CRITICAL: Don't touch frames during combat to avoid taint
        if InCombatLockdown() then
            return
        end

        if not addon.db or not addon.db.profile or not addon.db.profile.widgets then
            return
        end

        local widgets = addon.db.profile.widgets

        -- Apply mainbar container position
        if widgets.mainbar and addon.ActionBarFrames.mainbar then
            local config = widgets.mainbar
            if config.anchor then
                addon.ActionBarFrames.mainbar:ClearAllPoints()
                addon.ActionBarFrames.mainbar:SetPoint(config.anchor, config.posX, config.posY)
            end
        end

        -- Apply other bar positions
        local barConfigs = {{
            frame = addon.ActionBarFrames.rightbar,
            config = widgets.rightbar,
            default = {"RIGHT", -10, -70}
        }, {
            frame = addon.ActionBarFrames.leftbar,
            config = widgets.leftbar,
            default = {"RIGHT", -45, -70}
        }, {
            frame = addon.ActionBarFrames.bottombarleft,
            config = widgets.bottombarleft,
            default = {"BOTTOM", 0, 120}
        }, {
            frame = addon.ActionBarFrames.bottombarright,
            config = widgets.bottombarright,
            default = {"BOTTOM", 0, 160}
        }, -- RetailUI pattern: RepExp bar positioning
        {
            frame = addon.ActionBarFrames.repexpbar,
            config = widgets.repexpbar,
            default = {"BOTTOM", 0, 35}
        }}

        for _, barData in ipairs(barConfigs) do
            if barData.frame and barData.config and barData.config.anchor then
                local config = barData.config
                barData.frame:ClearAllPoints()
                barData.frame:SetPoint(config.anchor, config.posX, config.posY)
            elseif barData.frame then
                -- Apply default position
                local default = barData.default
                barData.frame:ClearAllPoints()
                barData.frame:SetPoint(default[1], UIParent, default[1], default[2], default[3])
            end
        end
    end

    -- Register action bar frames with the centralized system (RetailUI pattern)
    local function RegisterActionBarFrames()
        -- Register all action bar frames
        local frameRegistrations = {{
            name = "mainbar",
            frame = addon.ActionBarFrames.mainbar,
            blizzardFrame = MainMenuBar,
            configPath = {"widgets", "mainbar"}
        }, {
            name = "rightbar",
            frame = addon.ActionBarFrames.rightbar,
            blizzardFrame = MultiBarRight,
            configPath = {"widgets", "rightbar"}
        }, {
            name = "leftbar",
            frame = addon.ActionBarFrames.leftbar,
            blizzardFrame = MultiBarLeft,
            configPath = {"widgets", "leftbar"}
        }, {
            name = "bottombarleft",
            frame = addon.ActionBarFrames.bottombarleft,
            blizzardFrame = MultiBarBottomLeft,
            configPath = {"widgets", "bottombarleft"}
        }, {
            name = "bottombarright",
            frame = addon.ActionBarFrames.bottombarright,
            blizzardFrame = MultiBarBottomRight,
            configPath = {"widgets", "bottombarright"}
        }, -- RetailUI pattern: RepExp bar registration
        {
            name = "repexpbar",
            frame = addon.ActionBarFrames.repexpbar,
            blizzardFrame = nil,
            configPath = {"widgets", "repexpbar"}
        }}

        for _, registration in ipairs(frameRegistrations) do
            if registration.frame then
                addon:RegisterEditableFrame({
                    name = registration.name,
                    frame = registration.frame,
                    blizzardFrame = registration.blizzardFrame,
                    configPath = registration.configPath,
                    module = addon.MainBars
                })
            end
        end
    end

    -- Hook drag events to ensure action bars follow their containers
    local function SetupActionBarDragHandlers()
        -- Add drag end handlers to reposition action bars
        for name, frame in pairs(addon.ActionBarFrames) do
            -- Exclude bars that don't need repositioning after drag
            if frame and name ~= "mainbar" then
                frame:HookScript("OnDragStop", function(self)
                    -- RetailUI Pattern: Only reposition if not in combat
                    PositionActionBarsToContainers()
                end)
            end
        end
    end

    -- update position for secondary action bars - LEGACY FUNCTION
    function addon.RefreshUpperActionBarsPosition()
        if not MultiBarBottomLeftButton1 or not MultiBarBottomRight then
            return
        end

        -- calculate offset based on background visibility
        local yOffset1, yOffset2
        if addon.db and addon.db.profile.buttons.hide_main_bar_background then
            -- values when background is hidden
            yOffset1 = 45
            yOffset2 = 8
        else
            -- default values when background is visible
            yOffset1 = 48
            yOffset2 = 8
        end
    end

    -- Apply the mainbars system
    local function ApplyMainbarsSystem()
        if MainbarsModule.applied then
            return
        end

        -- CRITICAL: Disable MainMenuBarMaxLevelBar IMMEDIATELY
        if MainMenuBarMaxLevelBar then
            MainMenuBarMaxLevelBar:Hide()
            MainMenuBarMaxLevelBar:EnableMouse(false)
            MainMenuBarMaxLevelBar:SetAlpha(0)
            MainMenuBarMaxLevelBar:SetFrameLevel(0)
        end

        MainMenuBarMixin:initialize()
        addon.pUiMainBar = pUiMainBar

        CreateActionBarFrames()
        ApplyActionBarPositions()
        RegisterActionBarFrames()

        -- Temporarily hide secondary bars to prevent position flash on reload.
        -- They'll be restored in PLAYER_ENTERING_WORLD after final positioning.
        local barsToStabilize = {MultiBarBottomLeft, MultiBarBottomRight, MultiBarRight, MultiBarLeft}
        for _, bar in ipairs(barsToStabilize) do
            if bar then bar:SetAlpha(0) end
        end

        -- Note: Gryphon frame levels will be set after all positioning is complete

        -- Set up hooks for XP/Rep bars - RESTORED FUNCTIONALITY
        -- Connect bars to editor system first
        ConnectBarsToEditor()

        -- Force reputation text configuration
        ForceReputationTextConfiguration()

        -- Hook for maintaining editor connection
        hooksecurefunc('MainMenuExpBar_Update', UpdateBarPositions)
        hooksecurefunc('ReputationWatchBar_Update', UpdateBarPositions)

        -- Add the essential ReputationWatchBar_Update hook for styling only
        hooksecurefunc('ReputationWatchBar_Update', function()
            local name = GetWatchedFactionInfo()
            if name and ReputationWatchBar then
                -- Update editor positioning only if using editor system
                if addon.ActionBarFrames.repexpbar then
                    UpdateBarPositions()
                end

                -- Configure reputation status bar for NEW style only
                if ReputationWatchStatusBar then
                    ReputationWatchStatusBar:SetHeight(10)
                    ReputationWatchStatusBar:SetClearPoint('TOPLEFT', ReputationWatchBar, 0, 3)

                    -- Set size to match NEW style (537x10)
                    ReputationWatchStatusBar:SetSize(537, 10)

                    if ReputationWatchStatusBarBackground then
                        ReputationWatchStatusBarBackground:SetAllPoints(ReputationWatchStatusBar)
                    end

                    -- Text positioning for NEW style with FIXED layering
                    if ReputationWatchStatusBarText then
                        -- NEW style text positioning (offset +1)
                        ReputationWatchStatusBarText:SetClearPoint('CENTER', ReputationWatchStatusBar, 'CENTER', 0, 1)

                        -- Reasonable layering - not excessively high
                        ReputationWatchStatusBarText:SetDrawLayer("OVERLAY", 2)
                    end
                end
            end
        end)

        -- Position action bars immediately
        PositionActionBarsToContainers_Initial()
        
        -- Apply button positioning based on horizontal settings (RetailUI pattern)
        -- This ensures buttons are positioned correctly when horizontal mode is enabled on reload
        addon.PositionActionBars()

        -- Set up drag handlers - Execute immediately
        SetupActionBarDragHandlers()

        -- CRITICAL: Ensure gryphons are above all action bars after everything is positioned
        local function EnsureGryphonsOnTop()
            if pUiMainBarArt then
                -- Get the highest frame level from all action bars including containers
                local maxLevel = 1
                local bars = {MultiBarBottomLeft, MultiBarBottomRight, MultiBarLeft, MultiBarRight, pUiMainBar}
                for _, bar in pairs(bars) do
                    if bar then
                        maxLevel = math.max(maxLevel, bar:GetFrameLevel())
                    end
                end
                
                -- Check container frame levels too
                for _, frame in pairs(addon.ActionBarFrames) do
                    if frame and frame.GetFrameLevel then
                        maxLevel = math.max(maxLevel, frame:GetFrameLevel())
                    end
                end

                -- Set gryphon art frame level significantly higher than all bars
                pUiMainBarArt:SetFrameLevel(maxLevel + 15)
                
                -- Also ensure individual gryphons have high draw layers
                if MainMenuBarLeftEndCap then
                    MainMenuBarLeftEndCap:SetDrawLayer('OVERLAY', 7)
                end
                if MainMenuBarRightEndCap then
                    MainMenuBarRightEndCap:SetDrawLayer('OVERLAY', 7)
                end
            end
        end
        
        -- Execute immediately to ensure gryphons are on top
        EnsureGryphonsOnTop()

        -- Store module state
        MainbarsModule.frames.pUiMainBar = pUiMainBar
        MainbarsModule.frames.pUiMainBarArt = pUiMainBarArt
        MainbarsModule.actionBarFrames = addon.ActionBarFrames
        MainbarsModule.applied = true
    end

    -- Store functions globally for RefreshMainbarsSystem access
    addon.ApplyActionBarPositions = ApplyActionBarPositions
    addon.PositionActionBarsToContainers = PositionActionBarsToContainers

    -- Initialize immediately since we're already enabled
    ApplyMainbarsSystem()

    -- Set up event handlers - NEW style only system
    local function ApplyDragonUIExpRepBarStyling()
        -- Always use NEW style system only

        -- Setup both exp and rep bars with NEW styling system
        for _, bar in pairs({MainMenuExpBar, ReputationWatchStatusBar}) do
            if bar then
                -- ElvUI/RetailUI pattern: defensive check for GetStatusBarTexture
                local barTexture = bar.GetStatusBarTexture and bar:GetStatusBarTexture()
                if barTexture and barTexture.SetDrawLayer then
                    barTexture:SetDrawLayer('BORDER')
                end

                -- Create status texture if it doesn't exist
                if not bar.status then
                    bar.status = bar:CreateTexture(nil, 'ARTWORK')
                end

                -- Always apply NEW style (537x10 size)
                bar:SetSize(537, 10)
                bar.status:SetPoint('CENTER', 0, -2)
                bar.status:set_atlas('ui-hud-experiencebar-round', true)

                -- Apply custom textures for reputation bar
                if bar == ReputationWatchStatusBar then
                    bar:SetStatusBarTexture(addon._dir .. 'statusbarfill.tga')
                    if ReputationWatchStatusBarBackground then
                        ReputationWatchStatusBarBackground:set_atlas('ui-hud-experiencebar-background', true)
                    end
                end
            end
        end

        -- Apply background styling for NEW style for MainMenuExpBar
        if MainMenuExpBar then
            -- Ensure MainMenuExpBar is properly centered
            MainMenuExpBar:ClearAllPoints()
            if addon.ActionBarFrames.repexpbar then
                MainMenuExpBar:SetPoint('CENTER', addon.ActionBarFrames.repexpbar, 'CENTER', 0, 0)
            end

            for _, obj in pairs({MainMenuExpBar:GetRegions()}) do
                if obj:GetObjectType() == 'Texture' and obj:GetDrawLayer() == 'BACKGROUND' then
                    obj:set_atlas('ui-hud-experiencebar-background', true)
                end
            end
        end
    end

    local function ApplyModernExpBarVisual()
        local exhaustionStateID = GetRestState()
        local mainMenuExpBar = MainMenuExpBar

        if not mainMenuExpBar then
            return
        end

        -- Always apply NEW style custom texture system
        mainMenuExpBar:SetStatusBarTexture(addon._dir .. "uiexperiencebar")
        mainMenuExpBar:SetStatusBarColor(1, 1, 1, 1)

        -- Configure ExhaustionLevelFillBar (rested XP overlay) - ElvUI/RetailUI pattern: only adjust height
        if ExhaustionLevelFillBar then
            ExhaustionLevelFillBar:SetHeight(mainMenuExpBar:GetHeight())
            
            -- Apply color using GetStatusBarTexture():SetVertexColor() (3.3.5a compatible)
            -- Defensive check: GetStatusBarTexture may not exist or return nil in 3.3.5a
            if ExhaustionLevelFillBar.GetStatusBarTexture then
                local exhaustTexture = ExhaustionLevelFillBar:GetStatusBarTexture()
                if exhaustTexture and exhaustTexture.SetVertexColor then
                    if exhaustionStateID == 1 then
                        -- Rested state - Blue
                        exhaustTexture:SetVertexColor(0.0, 0.39, 0.88, 0.65)
                    elseif exhaustionStateID == 2 then
                        -- Tired state - Purple
                        exhaustTexture:SetVertexColor(0.58, 0.0, 0.55, 0.65)
                    end
                end
            end
        end

        -- Apply exhaustion-based TexCoords to main bar texture
        -- Defensive check: GetStatusBarTexture may not exist or return nil
        local mainTexture = mainMenuExpBar.GetStatusBarTexture and mainMenuExpBar:GetStatusBarTexture()
        if mainTexture and mainTexture.SetTexCoord then
            if exhaustionStateID == 1 then
                -- Rested state
                mainTexture:SetTexCoord(574 / 2048, 1137 / 2048, 34 / 64, 43 / 64)
            elseif exhaustionStateID == 2 then
                -- Tired state
                mainTexture:SetTexCoord(1 / 2048, 570 / 2048, 42 / 64, 51 / 64)
            else
                -- Normal state
                mainTexture:SetTexCoord(0, 1, 0, 1)
            end
        end

        -- Never show ExhaustionTick (as requested)
        if ExhaustionTick then
            ExhaustionTick:Hide()
        end
    end
    -- Single event handler for addon initialization
    local initFrame = CreateFrame("Frame")
    initFrame:RegisterEvent("ADDON_LOADED")
    initFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    initFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
    initFrame:RegisterEvent("UPDATE_FACTION")
    initFrame:RegisterEvent("PET_BAR_UPDATE")
    initFrame:RegisterEvent("PET_BAR_UPDATE_COOLDOWN")
    initFrame:RegisterEvent("UNIT_PET")
    initFrame:RegisterEvent("UNIT_EXITED_VEHICLE")
    initFrame:RegisterEvent("UNIT_ENTERED_VEHICLE")
    initFrame:RegisterEvent("PLAYER_LOGIN")

    local eventFrame = CreateFrame("Frame")
    eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    eventFrame:RegisterEvent("UPDATE_EXHAUSTION")
    eventFrame:SetScript("OnEvent", function(self, event)
        if event == "PLAYER_ENTERING_WORLD" then
            -- Apply initial styling setup - Execute immediately
            ApplyDragonUIExpRepBarStyling()
            ApplyModernExpBarVisual()
            ForceReputationTextConfiguration()
        elseif event == "UPDATE_EXHAUSTION" then
            -- Update exhaustion state immediately - no timer needed
            ApplyModernExpBarVisual()
            ForceReputationTextConfiguration()
        end
    end)

    initFrame:SetScript("OnEvent", function(self, event, addonName)
        if event == "ADDON_LOADED" and addonName == "DragonUI" then
            -- Initialize basic components immediately
            if IsModuleEnabled() then
                ApplyMainbarsSystem()
            end

        elseif event == "PLAYER_ENTERING_WORLD" then
            -- Apply XP/Rep bar styling and connect to editor - Execute immediately
            if IsModuleEnabled() then
                -- Remove interfering Blizzard textures FIRST
                RemoveBlizzardFrames()

                -- Connect bars to editor system
                ConnectBarsToEditor()

                -- Apply DragonUI styling system (from OLD)
                ApplyDragonUIExpRepBarStyling()

                -- Apply modern exhaustion system
                ApplyModernExpBarVisual()

                -- Force reputation text configuration
                ForceReputationTextConfiguration()

                -- Update positions
                UpdateBarPositions()

                -- Hide text by default
                if MainMenuBarExpText then
                    MainMenuBarExpText:Hide()
                end
                if ReputationWatchBarText then
                    ReputationWatchBarText:Hide()
                end
                
                -- Ensure gryphons are on top after all setup is complete
                if pUiMainBarArt then
                    local maxLevel = 1
                    local bars = {MultiBarBottomLeft, MultiBarBottomRight, MultiBarLeft, MultiBarRight, pUiMainBar}
                    for _, bar in pairs(bars) do
                        if bar then
                            maxLevel = math.max(maxLevel, bar:GetFrameLevel())
                        end
                    end
                    
                    for _, frame in pairs(addon.ActionBarFrames) do
                        if frame and frame.GetFrameLevel then
                            maxLevel = math.max(maxLevel, frame:GetFrameLevel())
                        end
                    end

                    pUiMainBarArt:SetFrameLevel(maxLevel + 15)
                end
            end

            -- Initialize pet bar visibility - Execute immediately
            if IsModuleEnabled() then
                addon.UpdatePetBarVisibility()
            end

            -- Final reposition and restore bar alpha (hidden during init to prevent flash)
            if not InCombatLockdown() and IsModuleEnabled() then
                ApplyActionBarPositions()
                PositionActionBarsToContainers()
                addon.ApplyAllBarButtonCounts()
            end
            local bars = {MultiBarBottomLeft, MultiBarBottomRight, MultiBarRight, MultiBarLeft}
            for _, bar in ipairs(bars) do
                if bar then bar:SetAlpha(1) end
            end
            if addon.RefreshActionBarVisibility then
                addon.RefreshActionBarVisibility()
            end

            -- Sync Blizzard CVars with DragonUI bar enable/disable settings
            addon.SyncBarCVarsFromProfile()

            self:UnregisterEvent("PLAYER_ENTERING_WORLD")

        elseif event == "PLAYER_LOGIN" then
            -- Set up profile callbacks - Execute immediately
            do
                if addon.db then
                    addon.db.RegisterCallback(addon, "OnProfileChanged", function()
                        -- Execute immediately - no timer needed
                        addon.RefreshMainbarsSystem()
                    end)
                    addon.db.RegisterCallback(addon, "OnProfileCopied", function()
                        -- Execute immediately - no timer needed  
                        addon.RefreshMainbarsSystem()
                    end)
                    addon.db.RegisterCallback(addon, "OnProfileReset", function()
                        -- Execute immediately - no timer needed
                        addon.RefreshMainbarsSystem()
                    end)

                    -- Initial refresh
                    addon.RefreshMainbarsSystem()
                end
            end

            self:UnregisterEvent("PLAYER_LOGIN")

        elseif event == "PLAYER_REGEN_ENABLED" then
            -- Reposition when combat ends - Execute immediately
            if IsModuleEnabled() then
                ApplyActionBarPositions()
                PositionActionBarsToContainers()
            end

        elseif event == "UPDATE_FACTION" then
            -- Update reputation bar when watched faction changes - Execute immediately
            if IsModuleEnabled() then
                ApplyDragonUIExpRepBarStyling()
                ForceReputationTextConfiguration()
                UpdateBarPositions()
            end

        elseif event == "PET_BAR_UPDATE" or event == "PET_BAR_UPDATE_COOLDOWN" or event == "UNIT_PET" then
            -- Handle pet bar visibility and updates - Execute immediately
            if IsModuleEnabled() and (arg1 == "player" or not arg1) then
                addon.UpdatePetBarVisibility()
            end

        elseif event == "UNIT_ENTERED_VEHICLE" or event == "UNIT_EXITED_VEHICLE" then
            -- Handle vehicle events that affect pet bar - Execute immediately
            if IsModuleEnabled() and arg1 == "player" then
                addon.UpdatePetBarVisibility()
            end
        end
    end)

    -- Mark module as initialized
    MainbarsModule.initialized = true
    MainbarsModule.applied = true

end

-- ============================================================================
-- BLIZZARD BAR TOGGLE SYNC (bar enable/disable ↔ Interface Options)
-- ============================================================================
-- In WoW 3.3.5a, bar visibility is controlled via global variables
-- SHOW_MULTI_ACTIONBAR_1..4 and persisted by SetActionBarToggles().
-- We sync DragonUI's actionbars.*_enabled settings bidirectionally.

local syncingBars = false

-- Push DragonUI profile → Blizzard (persistent via SetActionBarToggles)
function addon.SyncBarCVarsFromProfile()
    if syncingBars then return end
    syncingBars = true
    local config = addon.db and addon.db.profile and addon.db.profile.actionbars
    if config then
        local bl = (config.bottom_left_enabled  ~= false) and 1 or 0
        local br = (config.bottom_right_enabled ~= false) and 1 or 0
        local r  = (config.right_enabled        ~= false) and 1 or 0
        local l  = (config.left_enabled         ~= false) and 1 or 0

        -- SetActionBarToggles persists into Blizzard saved variables AND
        -- sets the SHOW_MULTI_ACTIONBAR_* globals AND calls MultiActionBar_Update.
        if SetActionBarToggles then
            SetActionBarToggles(bl, br, r, l)
        end

        -- Force-show enabled bars so they're visible immediately.
        -- Blizzard's MultiActionBar_Update may have :Hide()'d them;
        -- we need them :Show()'n for our alpha-based visibility to work.
        if not InCombatLockdown() then
            local barMap = {
                { frame = MultiBarBottomLeft,  enabled = bl == 1 },
                { frame = MultiBarBottomRight, enabled = br == 1 },
                { frame = MultiBarRight,       enabled = r  == 1 },
                { frame = MultiBarLeft,        enabled = l  == 1 },
            }
            for _, bar in ipairs(barMap) do
                if bar.frame then
                    bar.frame:Show()  -- always Show; alpha controls visibility
                    bar.frame:SetAlpha(bar.enabled and 1 or 0)
                end
            end
        end

        -- Re-apply DragonUI positioning (Blizzard may have moved things)
        if not InCombatLockdown() and addon.ActionBarFrames then
            if addon.PositionActionBarsToContainers then
                addon.PositionActionBarsToContainers()
            end
            addon.ApplyAllBarButtonCounts()
        end
    end
    syncingBars = false

    -- Final visibility pass OUTSIDE the guard so our alpha system is authoritative
    if addon.RefreshActionBarVisibility then
        addon.RefreshActionBarVisibility()
    end
end

-- Pull Blizzard globals → DragonUI profile (called from MultiActionBar_Update hook)
local function SyncBarGlobalsToProfile()
    if syncingBars then return end
    local config = addon.db and addon.db.profile and addon.db.profile.actionbars
    if not config then return end
    config.bottom_left_enabled  = (SHOW_MULTI_ACTIONBAR_1 == 1 or SHOW_MULTI_ACTIONBAR_1 == "1")
    config.bottom_right_enabled = (SHOW_MULTI_ACTIONBAR_2 == 1 or SHOW_MULTI_ACTIONBAR_2 == "1")
    config.right_enabled        = (SHOW_MULTI_ACTIONBAR_3 == 1 or SHOW_MULTI_ACTIONBAR_3 == "1")
    config.left_enabled         = (SHOW_MULTI_ACTIONBAR_4 == 1 or SHOW_MULTI_ACTIONBAR_4 == "1")
    -- Re-apply DragonUI positioning after Blizzard repositioned
    if not InCombatLockdown() and addon.ActionBarFrames then
        if addon.PositionActionBarsToContainers then
            addon.PositionActionBarsToContainers()
        end
        addon.ApplyAllBarButtonCounts()
        if addon.RefreshActionBarVisibility then
            addon.RefreshActionBarVisibility()
        end
    end
end

-- Hook Blizzard's MultiActionBar_Update to capture changes from Interface Options
if MultiActionBar_Update then
    hooksecurefunc("MultiActionBar_Update", SyncBarGlobalsToProfile)
end

-- ============================================================================
-- ACTION BAR VISIBILITY SYSTEM (hover/combat show/hide)
-- ============================================================================
-- Ported from old contributor. Uses alpha-based visibility for the main bar
-- (to keep XP/stance bars visible) and frame-level show/hide for secondary bars.
-- Each bar tracks hovered + inCombat state independently with debounced hover.

-- Visibility state tracking (file scope, survives reloads)
addon.visibilityStates = addon.visibilityStates or {
    main         = { hovered = false, inCombat = false },
    bottom_left  = { hovered = false, inCombat = false },
    bottom_right = { hovered = false, inCombat = false },
    right        = { hovered = false, inCombat = false },
    left         = { hovered = false, inCombat = false },
}

-- Returns true if a bar has any visibility behavior enabled
local function ShouldUseVisibility(barName)
    local db = addon.db and addon.db.profile and addon.db.profile.actionbars
    if not db then return false end
    return db[barName .. "_show_on_hover"] or db[barName .. "_show_in_combat"]
end

-- Deep alpha pass on main bar art textures  (skip functional bars/buttons)
local function SetMainBarArtAlphaDeep(alpha)
    local pUiMainBar    = addon.pUiMainBar
    local pUiMainBarArt = addon.pUiMainBarArt
    if not pUiMainBar then return end

    local function shouldSkip(f)
        if not f then return true end
        if f == MainMenuExpBar or f == ReputationWatchStatusBar
            or f == StanceBarFrame or f == ShapeshiftBarFrame then
            return true
        end
        local n = f.GetName and f:GetName() or ""
        if n and (n:find("ActionButton") or n:find("MultiBar")
            or n:find("BonusActionButton") or n:find("PetActionButton")) then
            return true
        end
        return false
    end

    local function applyToRegions(f)
        if not f or shouldSkip(f) then return end
        for i = 1, (f.GetNumRegions and f:GetNumRegions() or 0) do
            local region = select(i, f:GetRegions())
            if region and region.GetObjectType and region:GetObjectType() == "Texture" then
                region:SetAlpha(alpha)
            end
        end
    end

    for _, container in ipairs({ pUiMainBar, pUiMainBarArt, MainMenuBarArtFrame }) do
        applyToRegions(container)
        if container and container.GetNumChildren then
            for i = 1, container:GetNumChildren() do
                local child = select(i, container:GetChildren())
                applyToRegions(child)
            end
        end
    end
end

-- Core visibility resolver — called every time hover/combat state changes
function addon.UpdateActionBarVisibility(barName, frame)
    if not frame or not addon.db or not addon.db.profile or not addon.db.profile.actionbars then
        return
    end

    -- Skip during vehicle — vehicle module handles bar visibility
    if UnitHasVehicleUI and UnitHasVehicleUI("player") then return end

    local config = addon.db.profile.actionbars
    local state  = addon.visibilityStates and addon.visibilityStates[barName]
    if not state then return end

    -- Check if bar is disabled (secondary bars only)
    if barName ~= "main" then
        local enabledKey = barName .. "_enabled"
        if config[enabledKey] == false then
            if not InCombatLockdown() then
                frame:Show()       -- keep frame alive for state tracking
            end
            frame:SetAlpha(0)  -- visually hidden
            return
        end
    end

    local showOnHover  = config[barName .. "_show_on_hover"]
    local showInCombat = config[barName .. "_show_in_combat"]

    -- If neither option enabled, bar is always visible
    if not showOnHover and not showInCombat then
        if barName == "main" then
            for i = 1, 12 do
                local btn = _G["ActionButton" .. i]; if btn then btn:SetAlpha(1) end
            end
            -- Restore art/gryphon alpha (may have been set to 0 by previous visibility mode)
            local buttonsCfg = addon.db.profile.buttons
            local baseArtAlpha = (buttonsCfg and buttonsCfg.hide_main_bar_background) and 0 or 1
            if addon.pUiMainBarArt  then addon.pUiMainBarArt:SetAlpha(baseArtAlpha) end
            if MainMenuBarArtFrame  then MainMenuBarArtFrame:SetAlpha(baseArtAlpha) end
            if MainMenuBarLeftEndCap  then MainMenuBarLeftEndCap:SetAlpha(1) end
            if MainMenuBarRightEndCap then MainMenuBarRightEndCap:SetAlpha(1) end
            if ActionBarUpButton   then ActionBarUpButton:SetAlpha(baseArtAlpha) end
            if ActionBarDownButton then ActionBarDownButton:SetAlpha(baseArtAlpha) end
            if MainMenuBarPageNumber then MainMenuBarPageNumber:SetAlpha(baseArtAlpha) end
            if addon.pUiMainBar then
                if addon.pUiMainBar.BorderArt then addon.pUiMainBar.BorderArt:SetAlpha(baseArtAlpha) end
                if addon.pUiMainBar.Background then addon.pUiMainBar.Background:SetAlpha(baseArtAlpha) end
            end
            SetMainBarArtAlphaDeep(baseArtAlpha)
        else
            if not InCombatLockdown() then
                frame:Show()  -- counteract any Blizzard :Hide()
            end
            frame:SetAlpha(1)
        end
        return
    end

    -- Determine if bar should be visible
    local shouldShow = true
    if showOnHover and showInCombat then
        shouldShow = state.hovered and state.inCombat
    elseif showOnHover then
        shouldShow = state.hovered
    elseif showInCombat then
        shouldShow = state.inCombat
    end

    if barName == "main" then
        -- Main bar: alpha-only on action buttons to keep XP/stance visible
        local btnAlpha = shouldShow and 1 or 0
        for i = 1, 12 do
            local btn = _G["ActionButton" .. i]
            if btn then btn:SetAlpha(btnAlpha); btn:Show() end
        end
        -- Control main bar art (gryphons, page arrows, background)
        local buttonsCfg = addon.db.profile.buttons
        local baseArtAlpha = (buttonsCfg and buttonsCfg.hide_main_bar_background) and 0 or 1
        local artAlpha = shouldShow and baseArtAlpha or 0
        if addon.pUiMainBarArt  then addon.pUiMainBarArt:SetAlpha(artAlpha) end
        if MainMenuBarArtFrame  then MainMenuBarArtFrame:SetAlpha(artAlpha) end
        if MainMenuBarLeftEndCap  then MainMenuBarLeftEndCap:SetAlpha(artAlpha) end
        if MainMenuBarRightEndCap then MainMenuBarRightEndCap:SetAlpha(artAlpha) end
        if ActionBarUpButton   then ActionBarUpButton:SetAlpha(artAlpha) end
        if ActionBarDownButton then ActionBarDownButton:SetAlpha(artAlpha) end
        if MainMenuBarPageNumber then MainMenuBarPageNumber:SetAlpha(artAlpha) end
        if addon.pUiMainBar then
            if addon.pUiMainBar.BorderArt then addon.pUiMainBar.BorderArt:SetAlpha(artAlpha) end
            if addon.pUiMainBar.Background then addon.pUiMainBar.Background:SetAlpha(artAlpha) end
        end
        SetMainBarArtAlphaDeep(artAlpha)
        -- Always keep the container shown for XP/stance
        frame:Show()
    else
        -- Secondary bars: simple alpha
        frame:SetAlpha(shouldShow and 1 or 0)
        -- Keep frame shown for hover detection even when hidden-by-alpha
        if ShouldUseVisibility(barName) then
            frame:Show()
        end
    end
end

-- Refresh all bars (called from options or after profile change)
function addon.RefreshActionBarVisibility()
    if InCombatLockdown() then return end
    -- Skip during vehicle — vehicle module handles bar visibility
    if UnitHasVehicleUI and UnitHasVehicleUI("player") then return end

    local pUiMainBar = addon.pUiMainBar
    local barFrames = {
        main         = pUiMainBar,
        bottom_left  = MultiBarBottomLeft,
        bottom_right = MultiBarBottomRight,
        right        = MultiBarRight,
        left         = MultiBarLeft,
    }

    -- Normalise hover state from mouse position
    for barName, frame in pairs(barFrames) do
        local st = addon.visibilityStates[barName]
        if st and frame and frame.IsMouseOver then
            st.hovered = frame:IsMouseOver()
        end
    end

    for barName, frame in pairs(barFrames) do
        if frame then
            addon.UpdateActionBarVisibility(barName, frame)
        end
    end
end

-- Hover detection with 0.25s debounce (uses AceTimer for 3.3.5a compat)
local hoverTimers = {}

local function SetupActionBarHoverDetection(barName, frame)
    if not frame then return end
    if frame.EnableMouse then frame:EnableMouse(true) end

    -- Button prefix for gap-stabilisation hooks
    local buttonPrefix
    if barName == "main"         then buttonPrefix = "ActionButton"
    elseif barName == "bottom_left"  then buttonPrefix = "MultiBarBottomLeftButton"
    elseif barName == "bottom_right" then buttonPrefix = "MultiBarBottomRightButton"
    elseif barName == "right"    then buttonPrefix = "MultiBarRightButton"
    elseif barName == "left"     then buttonPrefix = "MultiBarLeftButton"
    end

    -- Frame enter/leave
    frame:HookScript("OnEnter", function()
        if hoverTimers[barName] and addon.core and addon.core.CancelTimer then
            addon.core:CancelTimer(hoverTimers[barName], true)
            hoverTimers[barName] = nil
        end
        if addon.visibilityStates[barName] then
            addon.visibilityStates[barName].hovered = true
            addon.UpdateActionBarVisibility(barName, frame)
        end
    end)

    frame:HookScript("OnLeave", function()
        if hoverTimers[barName] and addon.core and addon.core.CancelTimer then
            addon.core:CancelTimer(hoverTimers[barName], true)
        end
        if addon.core and addon.core.ScheduleTimer then
            hoverTimers[barName] = addon.core:ScheduleTimer(function()
                if addon.visibilityStates[barName] then
                    addon.visibilityStates[barName].hovered = false
                    addon.UpdateActionBarVisibility(barName, frame)
                end
                hoverTimers[barName] = nil
            end, 0.25)
        end
    end)

    -- Button-level hooks stabilise hover across gaps between buttons
    if buttonPrefix then
        for i = 1, 12 do
            local btn = _G[buttonPrefix .. i]
            if btn and not btn.__DragonUI_HoverHooked then
                btn:HookScript("OnEnter", function()
                    if hoverTimers[barName] and addon.core and addon.core.CancelTimer then
                        addon.core:CancelTimer(hoverTimers[barName], true)
                        hoverTimers[barName] = nil
                    end
                    if addon.visibilityStates[barName] then
                        addon.visibilityStates[barName].hovered = true
                        addon.UpdateActionBarVisibility(barName, frame)
                    end
                end)
                btn:HookScript("OnLeave", function()
                    if hoverTimers[barName] and addon.core and addon.core.CancelTimer then
                        addon.core:CancelTimer(hoverTimers[barName], true)
                    end
                    if addon.core and addon.core.ScheduleTimer then
                        hoverTimers[barName] = addon.core:ScheduleTimer(function()
                            if addon.visibilityStates[barName] then
                                addon.visibilityStates[barName].hovered = false
                                addon.UpdateActionBarVisibility(barName, frame)
                            end
                            hoverTimers[barName] = nil
                        end, 0.25)
                    end
                end)
                btn.__DragonUI_HoverHooked = true
            end
        end
    end
end

-- Combat state handler
local function OnCombatStateChanged(inCombat)
    local pUiMainBar = addon.pUiMainBar
    local barFrameMap = {
        main         = pUiMainBar,
        bottom_left  = MultiBarBottomLeft,
        bottom_right = MultiBarBottomRight,
        right        = MultiBarRight,
        left         = MultiBarLeft,
    }
    for barName, state in pairs(addon.visibilityStates or {}) do
        state.inCombat = inCombat
        local frame = barFrameMap[barName]
        if frame then
            addon.UpdateActionBarVisibility(barName, frame)
        end
    end
end

-- Initialize the full visibility system (called once after all bars exist)
local function InitializeActionBarVisibility()
    local pUiMainBar = addon.pUiMainBar
    if not pUiMainBar then return end

    SetupActionBarHoverDetection("main",         pUiMainBar)
    SetupActionBarHoverDetection("bottom_left",  MultiBarBottomLeft)
    SetupActionBarHoverDetection("bottom_right", MultiBarBottomRight)
    SetupActionBarHoverDetection("right",        MultiBarRight)
    SetupActionBarHoverDetection("left",         MultiBarLeft)

    -- Combat events
    local combatFrame = CreateFrame("Frame")
    combatFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
    combatFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
    combatFrame:SetScript("OnEvent", function(self, event)
        OnCombatStateChanged(event == "PLAYER_REGEN_DISABLED")
    end)

    -- Hook Blizzard MultiActionBar_Update to restore our visibility after it re-shows bars
    -- BUT skip during vehicle UI — the vehicle module handles visibility in that case.
    if MultiActionBar_Update then
        hooksecurefunc("MultiActionBar_Update", function()
            -- Never interfere while in a vehicle — vehicle module manages bar hiding
            if UnitHasVehicleUI and UnitHasVehicleUI("player") then return end
            if addon.core and addon.core.ScheduleTimer then
                addon.core:ScheduleTimer(function()
                    if UnitHasVehicleUI and UnitHasVehicleUI("player") then return end
                    if addon.RefreshActionBarVisibility then
                        addon.RefreshActionBarVisibility()
                    end
                end, 0.1)
            end
        end)
    end

    -- Initial visibility pass
    if addon.core and addon.core.ScheduleTimer then
        addon.core:ScheduleTimer(function()
            addon.RefreshActionBarVisibility()
        end, 1)
    end
end

-- ============================================================================
-- INITIALIZATION CONTROL
-- ============================================================================

-- Event frame to handle initialization
local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("ADDON_LOADED")
initFrame:RegisterEvent("PLAYER_LOGIN")
initFrame:SetScript("OnEvent", function(self, event, addonName)
    if event == "ADDON_LOADED" and addonName == "DragonUI" then
        -- Only initialize if enabled
        InitializeMainbars()
        self:UnregisterEvent("ADDON_LOADED")
    elseif event == "PLAYER_LOGIN" then
        -- Backup check
        InitializeMainbars()
        -- Initialize visibility system after all bars are created
        InitializeActionBarVisibility()
        self:UnregisterEvent("PLAYER_LOGIN")
    end
end)

-- Global UpdateGryphonStyle function (accessible from RefreshMainbarsSystem)
function addon.UpdateGryphonStyle()
    if not MainMenuBarLeftEndCap or not MainMenuBarRightEndCap then
        return
    end

    local db_style = addon.db and addon.db.profile and addon.db.profile.style
    if not db_style then
        db_style = config.style
    end

    local faction = UnitFactionGroup('player')

    if db_style.gryphons == 'old' then
        MainMenuBarLeftEndCap:SetClearPoint('BOTTOMLEFT', -85, -22)
        MainMenuBarRightEndCap:SetClearPoint('BOTTOMRIGHT', 84, -22)
        MainMenuBarLeftEndCap:set_atlas('ui-hud-actionbar-gryphon-left', true)
        MainMenuBarRightEndCap:set_atlas('ui-hud-actionbar-gryphon-right', true)
        MainMenuBarLeftEndCap:Show()
        MainMenuBarRightEndCap:Show()
    elseif db_style.gryphons == 'new' then
        MainMenuBarLeftEndCap:SetClearPoint('BOTTOMLEFT', -95, -23)
        MainMenuBarRightEndCap:SetClearPoint('BOTTOMRIGHT', 95, -23)
        if faction == 'Alliance' then
            MainMenuBarLeftEndCap:set_atlas('ui-hud-actionbar-gryphon-thick-left', true)
            MainMenuBarRightEndCap:set_atlas('ui-hud-actionbar-gryphon-thick-right', true)
        else
            MainMenuBarLeftEndCap:set_atlas('ui-hud-actionbar-wyvern-thick-left', true)
            MainMenuBarRightEndCap:set_atlas('ui-hud-actionbar-wyvern-thick-right', true)
        end
        MainMenuBarLeftEndCap:Show()
        MainMenuBarRightEndCap:Show()
    elseif db_style.gryphons == 'flying' then
        MainMenuBarLeftEndCap:SetClearPoint('BOTTOMLEFT', -80, -21)
        MainMenuBarRightEndCap:SetClearPoint('BOTTOMRIGHT', 80, -21)
        MainMenuBarLeftEndCap:set_atlas('ui-hud-actionbar-gryphon-flying-left', true)
        MainMenuBarRightEndCap:set_atlas('ui-hud-actionbar-gryphon-flying-right', true)
        MainMenuBarLeftEndCap:Show()
        MainMenuBarRightEndCap:Show()
    else
        MainMenuBarLeftEndCap:Hide()
        MainMenuBarRightEndCap:Hide()
    end
end

-- ============================================================================
-- BAR SIZE SYSTEM - Grid-based button layout
-- ============================================================================

-- Apply all bar button counts from database
function addon.ApplyAllBarButtonCounts()
    if InCombatLockdown() then return end

    local db = addon.db and addon.db.profile and addon.db.profile.mainbars
    if not db then return end

    -- Main bar: use grid layout from player sub-table
    local playerCfg = db.player or {}
    local mainColumns = playerCfg.columns or 12
    local mainCount = playerCfg.buttons_shown or 12
    -- Auto-compute rows from columns and buttons shown
    local mainRows = math.ceil(mainCount / mainColumns)

    -- Main bar uses ArrangeActionBarButtons for grid layout
    addon.ArrangeActionBarButtons("ActionButton",
        addon.pUiMainBar, addon.pUiMainBar,
        mainRows, mainColumns, mainCount,
        nil, nil)

    -- Also apply same layout to BonusActionButtons (vehicle/shapeshift override bar)
    addon.ArrangeActionBarButtons("BonusActionButton",
        nil, addon.pUiMainBar,
        mainRows, mainColumns, mainCount,
        nil, nil)

    -- Show/hide ThreeSlice dividers between buttons
    -- Only show dividers in single-row mode (multi-row would look odd)
    if addon.MainBarDividers then
        for i = 1, 11 do
            local div = addon.MainBarDividers[i]
            if div then
                if mainRows == 1 and i < mainCount then
                    -- Single row: show divider between two visible buttons
                    if div.top then div.top:Show() end
                    if div.mid then div.mid:Show() end
                    if div.bottom then div.bottom:Show() end
                else
                    -- Multi-row or beyond last button: hide
                    if div.top then div.top:Hide() end
                    if div.mid then div.mid:Hide() end
                    if div.bottom then div.bottom:Hide() end
                end
            end
        end
    end

    -- Reposition gryphons to hug the resized main bar
    addon.UpdateGryphonStyle()

    -- NOTE: Container frames (editor overlays) are NOT resized here.
    -- Resizing containers shifts bars depending on their anchor point.
    -- Only pUiMainBar (with NineSlice/gryphons) resizes via ArrangeActionBarButtons above.
    -- Containers keep their initial size set by CreateActionBarFrames / PositionActionBars.

    -- Bottom Left bar — use grid layout (no padding)
    -- Pass bar as parentFrame so it gets resized to match buttons.
    -- This ensures CENTER anchoring keeps buttons visually centered.
    local blCfg = db.bottom_left or {}
    local blCols = blCfg.columns or 12
    local blCount = blCfg.buttons_shown or 12
    local blRows = math.ceil(blCount / blCols)
    if not MultiBarBottomLeft or MultiBarBottomLeft:IsShown() then
        addon.ArrangeActionBarButtons("MultiBarBottomLeftButton",
            MultiBarBottomLeft, MultiBarBottomLeft,
            blRows, blCols, blCount,
            0, 0)
    end

    -- Bottom Right bar — use grid layout (no padding)
    local brCfg = db.bottom_right or {}
    local brCols = brCfg.columns or 12
    local brCount = brCfg.buttons_shown or 12
    local brRows = math.ceil(brCount / brCols)
    if not MultiBarBottomRight or MultiBarBottomRight:IsShown() then
        addon.ArrangeActionBarButtons("MultiBarBottomRightButton",
            MultiBarBottomRight, MultiBarBottomRight,
            brRows, brCols, brCount,
            0, 0)
    end

    -- Left/Right bars: uses TOPLEFT grid layout via PositionSideBarButtons
    -- which respects columns setting (1=vertical, 12=horizontal, etc.)
    addon.PositionActionBars()

    -- Keep overlay sizes in sync with current layout
    if addon.UpdateOverlaySizes then
        addon.UpdateOverlaySizes()
    end
end

-- Public API for options
function addon.RefreshMainbarsSystem()
    if not IsModuleEnabled() then
        return
    end

    -- CRITICAL: Don't touch protected frames during combat
    if InCombatLockdown() then
        -- Only update safe things (not frames)
        addon.UpdateGryphonStyle()
        if addon.MainMenuBarMixin and addon.MainMenuBarMixin.update_main_bar_background then
            addon.MainMenuBarMixin:update_main_bar_background()
        end
        return
    end

    -- Apply scales to all action bars (ONLY OUTSIDE COMBAT)
    local db = addon.db and addon.db.profile and addon.db.profile.mainbars
    if not db then
        return
    end

    -- Apply main bar scale
    if addon.pUiMainBar and db.scale_actionbar then
        addon.pUiMainBar:SetScale(db.scale_actionbar)
    end

    -- Apply scales to other bars
    if MultiBarRight and db.scale_rightbar then
        MultiBarRight:SetScale(db.scale_rightbar)
    end

    if MultiBarLeft and db.scale_leftbar then
        MultiBarLeft:SetScale(db.scale_leftbar)
    end

    if MultiBarBottomLeft and db.scale_bottomleft then
        MultiBarBottomLeft:SetScale(db.scale_bottomleft)
    end

    if MultiBarBottomRight and db.scale_bottomright then
        MultiBarBottomRight:SetScale(db.scale_bottomright)
    end

    -- Update gryphon style and background
    addon.UpdateGryphonStyle()
    if addon.MainMenuBarMixin and addon.MainMenuBarMixin.update_main_bar_background then
        addon.MainMenuBarMixin:update_main_bar_background()
    end

    -- Update widget positions if available
    if addon.ActionBarFrames and addon.ApplyActionBarPositions then
        addon.ApplyActionBarPositions()
        if addon.PositionActionBarsToContainers then
            addon.PositionActionBarsToContainers()
        end
    end

    -- Apply bar button counts (show/hide buttons)
    -- This also calls PositionActionBars() at the end for left/right bar orientation
    addon.ApplyAllBarButtonCounts()
end

-- Alias for compatibility
addon.RefreshMainbars = addon.RefreshMainbarsSystem
