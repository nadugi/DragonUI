--[[
 DragonUI - Portuguese (Brazil) Locale (ptBR)
 Community translation — Edit this file to contribute!

 Guidelines:
 - Use `true` for strings you haven't translated yet (falls back to English)
 - Keep format specifiers like %s, %d, %.1f intact
 - Keep slash commands untranslated (/dragonui, /dui, /rl)
 - Keep "DragonUI" as addon name untranslated
 - Keep color codes |cff...|r outside of L[] strings
]]

local L = LibStub("AceLocale-3.0"):NewLocale("DragonUI", "ptBR")
if not L then return end

-- Example:
-- L["Cannot toggle editor mode during combat!"] = "Não é possível alternar o modo editor durante o combate!"

-- UnitFrameLayers compatibility popup
L["TooltipWidget"] = true
L["DragonUI - UnitFrameLayers Detected"] = true
L["DragonUI already includes Unit Frame Layers functionality (heal prediction, absorb shields, and animated health loss)."] = true
L["Choose how to resolve this overlap:"] = true
L["Use DragonUI: disable external UnitFrameLayers and enable DragonUI layers."] = true
L["Disable Both: disable external UnitFrameLayers and keep DragonUI layers disabled."] = true
L["Use DragonUI"] = true
L["Disable Both"] = true
