# DragonUI - Release Notes Source

This file is kept as a local source for preparing release notes.

It replaces the old root changelog so the repository root stays cleaner and release notes can be summarized per version instead of growing as a branch diary.

## 2026-03-19 — v2.4.0

### Added
- Module lifecycle system with centralized registry
- Database migration system for safe profile upgrades
- Unified combat queue system for deferred secure frame operations
- Quick access shortcuts in General options tab (Dark Mode, Fat Health Bar, Dragon Decoration, etc.)
- Micromenu character portrait highlight and grayscale mode improvements

### Changed
- Options system fully separated into DragonUI_Options addon (removed monolithic `options.lua`)
- Version bumped from 2.3 to 2.4.0

### Localization
- Full localization sync across enUS, esES, esMX, deDE, koKR, ruRU
- Tested on ruRU, koKR, esES, enUS clients
- Auto-translated Russian coverage (may contain errors)
- Partial auto-translated Korean and German (pending community review)
- All module names and descriptions now use localized strings

### Legal
- MIT License file added to repository root
- THIRD_PARTY_NOTICES.md created (GPL-2.0 for AbsorbsMonitor, font licenses)
- Font license files added: Typodermic EULA, SIL OFL 1.1
- README rewritten with disclaimer, credits, and legal summary

## 2026-03-16

### Added
- Bag slot lock system
- Quick lock controls with `Alt + LeftClick` and a clear button

### Fixed
- Target PvP icon overlap
- Bank slot locking on main bank slots
- CompactRaidFrame compatibility issue
- ToT self-target aura flicker

### Changed
- Localization coverage for bag lock texts
- Game menu compatibility handling for a custom-server-specific path

## 2026-03-15

### Fixed
- Target and focus elite dragon overlap
- Minimap rotation stability
- SexyMap Hybrid Mode behavior
- Party frame recovery improvements
- Target and focus mana text alignment

### Changed
- Unit Frame Layers options cleanup

## 2026-03-14

### Added
- Unit Frame Layers module beta
- UnitFrameLayers compatibility popup
- Focus name background toggle

### Changed
- Centralized font system

### Fixed
- Attempted fix for UI freezes caused by visual corruption
- Options panel translation errors
- Korean translations update

## 2026-03-12

### Added
- Target name background toggle
- Extended chat font size range
- QuestHelper compatibility

### Fixed
- Target class color reset issue
- Player icon layering
- Micromenu latency tooltip localization
- Modules tab locale error
- Party background CVar conflict
- Item quality borders on inspect
- Party frames vehicle texture bleed-through

## 2026-03-10

### Added
- Bag Sort module
- Bag Sort translations

### Changed
- Combuctor disabled by default

### Fixed
- Combuctor bank tooltips

## 2026-03-09

### Added
- Chat enhancements module
- Combuctor bags module
- Bags options tab
- Boss frames in Editor Mode
- esMX locale

### Fixed
- Boss frame styling
- Dark mode coverage
- Party frame layering and vehicle texture handling
- Options panel cleanup

## 2026-03-07

### Added
- Quest tracker font size option

### Fixed
- Death Knight rune texture issue

## 2026-03-04

### Added
- SexyMap compatibility system

### Fixed
- Item quality borders in guild bank
- Party frame Master Looter icon position
- Pet frame default position overlap

## 2026-03-03

### Added
- Weapon Enchants frame
- Restyled game menu button
- Dungeon Eye mover

### Fixed
- Action bar CVar behavior
- Korean font rendering
- Compatibility module localized popup text
- Leader icon overlap
- Quest tracker anchor drift
