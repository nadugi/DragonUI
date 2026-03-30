--[[
  DragonUI - Target Frame Module (target.lua)

  Target-specific configuration and hooks passed to the
  UF.TargetStyle closure factory defined in target_style.lua.
]]

local addon = select(2, ...)
local UF = addon.UF

-- ============================================================================
-- BLIZZARD FRAME CACHE
-- ============================================================================

local TargetFrame                      = _G.TargetFrame
local TargetFrameHealthBar             = _G.TargetFrameHealthBar
local TargetFrameManaBar               = _G.TargetFrameManaBar
local TargetFramePortrait              = _G.TargetFramePortrait
local TargetFrameTextureFrameName      = _G.TargetFrameTextureFrameName
local TargetFrameTextureFrameLevelText = _G.TargetFrameTextureFrameLevelText
local TargetFrameNameBackground        = _G.TargetFrameNameBackground

local function IsToTDetached()
    local cfg = addon.db and addon.db.profile and addon.db.profile.unitframe and addon.db.profile.unitframe.tot
    if cfg and cfg.override then
        return true
    end

    local totFrame = _G.TargetFrameToT
    if totFrame and totFrame.GetPoint then
        local _, relativeTo = totFrame:GetPoint(1)
        if relativeTo and relativeTo ~= TargetFrame then
            return true
        end
    end

    return false
end

local function InstallTargetAuraVisibilityWrapper()
    if _G.DragonUI_TargetAuraVisibilityWrapped or not _G.TargetFrame_UpdateAuras then
        return
    end

    local originalUpdateAuras = _G.TargetFrame_UpdateAuras
    _G.TargetFrame_UpdateAuras = function(frame, ...)
        if frame == TargetFrame and IsToTDetached() and frame and frame.totFrame then
            local totFrame = frame.totFrame
            local originalIsShown = totFrame.IsShown

            totFrame.IsShown = function()
                return false
            end

            local ok, err = pcall(originalUpdateAuras, frame, ...)

            totFrame.IsShown = originalIsShown

            if not ok then
                error(err)
            end
            return
        end

        return originalUpdateAuras(frame, ...)
    end

    _G.DragonUI_TargetAuraVisibilityWrapped = true
end

-- ============================================================================
-- CREATE VIA FACTORY
-- ============================================================================

local api = UF.TargetStyle.Create({
    -- Identity
    configKey        = "target",
    unitToken        = "target",
    widgetKey        = "target",
    combatQueueKey   = "target_position",

    -- Blizzard frame references
    blizzFrame       = TargetFrame,
    healthBar        = TargetFrameHealthBar,
    manaBar          = TargetFrameManaBar,
    portrait         = TargetFramePortrait,
    nameText         = TargetFrameTextureFrameName,
    levelText        = TargetFrameTextureFrameLevelText,
    nameBackground   = TargetFrameNameBackground,

    -- Naming & layout
    namePrefix       = "Target",
    defaultPos       = { anchor = "TOPLEFT", posX = 250, posY = -4 },
    overlaySize      = { 200, 75 },

    -- Events
    unitChangedEvent = "PLAYER_TARGET_CHANGED",
    extraEvents      = {
        "UNIT_MODEL_CHANGED",
        "UNIT_LEVEL",
        "UNIT_NAME_UPDATE",
        "UNIT_PORTRAIT_UPDATE",
    },

    -- Feature flags
    forceLayoutOnUnitChange = true,   -- ReapplyElementPositions on every change
    hasTapDenied            = true,   -- Grey name bg for tapped-by-other targets

    -- Blizzard elements to hide
    hideListFn = function()
        return {
            _G.TargetFrameTextureFrameTexture,
            _G.TargetFrameBackground,
            _G.TargetFrameFlash,
            _G.TargetFrameNumericalThreat,
            TargetFrame.threatNumericIndicator,
            TargetFrame.threatIndicator,
            -- ToT children (visible as part of TargetFrame even if ToT module is disabled)
            _G.TargetFrameToTBackground,
            _G.TargetFrameToTTextureFrameTexture,
        }
    end,

    -- Famous NPC callback (message throttle)
    onFamousNpc = function(name, cache)
        local now = GetTime()
        if cache.lastFamousTarget ~= name
           or (now - cache.lastFamousMessage) > 5 then
            cache.lastFamousMessage = now
            cache.lastFamousTarget  = name
        end
    end,

    -- ----------------------------------------------------------------
    -- After-init hooks
    -- ----------------------------------------------------------------
    afterInit = function(ctx)
        -- Hook TargetFrame_CheckClassification for threat flash texture
        if not ctx.Module.threatHooked then
            hooksecurefunc("TargetFrame_CheckClassification",
                function(self, forceNormalTexture)
                    local threatFlash = _G.TargetFrameFlash
                    if threatFlash then
                        threatFlash:SetTexture(ctx.TEXTURES.THREAT)
                        threatFlash:SetTexCoord(0, 376/512, 0, 134/256)
                        threatFlash:SetBlendMode("ADD")
                        threatFlash:SetAlpha(0.7)
                        threatFlash:SetDrawLayer("ARTWORK", 10)
                        threatFlash:ClearAllPoints()
                        threatFlash:SetPoint("BOTTOMLEFT",
                            TargetFrame, "BOTTOMLEFT", 2, 25)
                        threatFlash:SetSize(188, 67)
                    end
                end)
            ctx.Module.threatHooked = true
        end

        -- Classification delay frame + hooks
        if not ctx.Module.classificationHooked then
            local delayFrame = CreateFrame("Frame")
            delayFrame:Hide()
            delayFrame.elapsed = 0
            delayFrame:SetScript("OnUpdate", function(self, dt)
                self.elapsed = self.elapsed + dt
                if self.elapsed >= 0.1 then
                    self:Hide()
                    if UnitExists("target") then
                        ctx.UpdateClassification()
                    end
                end
            end)

            if _G.TargetFrame_CheckClassification then
                hooksecurefunc("TargetFrame_CheckClassification",
                    function()
                        if UnitExists("target") then
                            delayFrame.elapsed = 0
                            delayFrame:Show()
                        end
                    end)
            end

            if _G.TargetFrame_Update then
                hooksecurefunc("TargetFrame_Update", function()
                    if UnitExists("target") then
                        ctx.UpdateClassification()
                    end
                end)
            end

            ctx.Module.classificationHooked = true
        end

        InstallTargetAuraVisibilityWrapper()
    end,

    -- ----------------------------------------------------------------
    -- Class color hooks
    -- ----------------------------------------------------------------
    setupExtraHooks = function(UpdateHealthBarColor, UpdateClassPortrait)
        if not _G.DragonUI_TargetHealthHookSetup then
            hooksecurefunc("UnitFrameHealthBar_Update",
                function(statusbar, unit)
                    if statusbar == TargetFrameHealthBar
                       and unit == "target" then
                        UpdateHealthBarColor()
                    end
                end)

            hooksecurefunc("TargetFrame_Update", function()
                if UnitExists("target") then
                    UpdateHealthBarColor()
                    UpdateClassPortrait()
                end
            end)

            -- UnitFramePortrait_Update is already hooked in SetupBarHooks

            _G.DragonUI_TargetHealthHookSetup = true
        end
    end,

    -- ----------------------------------------------------------------
    -- Extra event handler
    -- ----------------------------------------------------------------
    extraEventHandler = function(event, unitToken, UpdateClassification,
                                  UpdateHealthBarColor, ForceUpdatePowerBar,
                                  textSystem, ...)
        local unit = ...
        if unit ~= unitToken or not UnitExists(unitToken) then return end

        if event == "UNIT_MODEL_CHANGED" then
            UpdateClassification()
            UpdateHealthBarColor()
            if textSystem then textSystem.update() end
        elseif event == "UNIT_LEVEL"
            or event == "UNIT_NAME_UPDATE" then
            UpdateClassification()
        end
    end,
})

-- ============================================================================
-- PUBLIC API
-- ============================================================================

addon.TargetFrame = {
    Refresh                  = api.Refresh,
    RefreshTargetFrame       = api.Refresh,
    Reset                    = api.Reset,
    anchor                   = api.anchor,
    ChangeTargetFrame        = api.Refresh,
    UpdateTargetHealthBarColor = function()
        if UnitExists("target") then
            api.UpdateHealthBarColor()
        end
    end,
    UpdateTargetClassPortrait = api.UpdateClassPortrait,
}

-- Legacy compatibility
addon.unitframe = addon.unitframe or {}
addon.unitframe.ChangeTargetFrame   = api.Refresh
addon.unitframe.ReApplyTargetFrame  = api.Refresh

function addon:RefreshTargetFrame()
    api.Refresh()
end
