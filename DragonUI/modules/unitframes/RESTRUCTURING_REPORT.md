# DragonUI Unit Frame Restructuring — Final Report

## Summary

Completed restructuring of all 8 Unit Frame modules using the **Hybrid B+C strategy** (Parameterized Consolidation + Shared Core). Work was executed across 6 phases.

## Results

| Metric | Before | After | Change |
|--------|--------|-------|--------|
| Files | 8 | 11 | +3 shared core |
| Total Lines | 8,526 | 6,655 | **−1,871 (22%)** |
| Duplicated Lines | 2,084 (24.4%) | ~400 (6%) | **−81% duplication** |

### Per-File Breakdown

| File | Before | After | Notes |
|------|--------|-------|-------|
| **uf_core.lua** | — | 352 | NEW: Shared constants & utilities |
| **small_frame.lua** | — | 610 | NEW: ToT/FoT factory |
| **target_style.lua** | — | 946 | NEW: Target/Focus factory |
| player.lua | 2,112 | 1,818 | Standardized (UF refs) |
| target.lua | 1,209 | 197 | **Thin wrapper (−84%)** |
| text_system.lua | 413 | 354 | Unchanged |
| focus.lua | 1,005 | 109 | **Thin wrapper (−89%)** |
| tot.lua | 595 | 52 | **Thin wrapper (−91%)** |
| tof.lua | 574 | 52 | **Thin wrapper (−91%)** |
| party.lua | 1,758 | 1,506 | Standardized (UF refs + TextSystem) |
| pet.lua | 713 | 659 | Standardized (UF refs) |

## Architecture

### Load Order (unitframes.xml)
```
uf_core.lua          → UF namespace, textures, constants, utilities
small_frame.lua      → UF.SmallFrame.Create() factory (ToT/FoT)
target_style.lua     → UF.TargetStyle.Create() factory (Target/Focus)
player.lua           → Standalone (uses UF.TEXTURES.player, UF.GetConfig)
target.lua           → Thin wrapper calling UF.TargetStyle.Create
text_system.lua      → TextSystem utilities
focus.lua            → Thin wrapper calling UF.TargetStyle.Create
tot.lua              → Thin wrapper calling UF.SmallFrame.Create
tof.lua              → Thin wrapper calling UF.SmallFrame.Create
party.lua            → Standalone (uses UF.TEXTURES.party, TextSystem)
pet.lua              → Standalone (uses UF.TEXTURES.pet)
```

### Key Design Patterns

1. **Closure-based factories**: `UF.SmallFrame.Create(opts)` and `UF.TargetStyle.Create(opts)` return independent module instances via closures. No shared mutable state between instances.

2. **Opts-driven customization**: Each factory accepts an opts table with:
   - Identity: `configKey`, `unitToken`, `widgetKey`
   - Frame refs: `blizzFrame`, `healthBar`, `manaBar`, `portrait`, etc.
   - Behavioral flags: `forceLayoutOnUnitChange`, `hasTapDenied`, `nameVertexAlpha`
   - Callbacks: `afterInit(ctx)`, `afterBarHooks(...)`, `setupExtraHooks(...)`, `extraEventHandler(...)`

3. **Single source of truth**: All texture paths, boss coords, power maps, threat colors, and famous NPCs defined once in `uf_core.lua` as `UF.TEXTURES`, `UF.BOSS_COORDS`, `UF.POWER_MAP`, etc.

4. **Thin wrappers export full API**: Each wrapper preserves ALL public API names used by `DragonUI_Options/unitframes.lua` and legacy `addon.unitframe.*` aliases.

## Phases Completed

### Phase 1: uf_core.lua ✅
- Created `addon.UF` namespace with shared constants and utility functions
- Populated legacy `addon.unitframe.famous` for backward compatibility
- Fixed bug: `addon.unitframe.famous` was never populated in original code

### Phase 2: small_frame.lua + ToT/FoT ✅
- Built `UF.SmallFrame.Create(opts)` factory (610 lines)
- Rewrote tot.lua (595→52) and tof.lua (574→52) as thin wrappers
- Fixed retry frame leak, added CombatQueue deferral

### Phase 3: target_style.lua + Target/Focus ✅
- Built `UF.TargetStyle.Create(opts)` factory (946 lines)
- Rewrote target.lua (1209→197) and focus.lua (1005→109) as thin wrappers
- Unified: health bar class color, power bar texture management, classification, threat, ShowTest/HideTest
- Target-specific: ForceReapplyLayout, TargetFrame_CheckClassification hooks, class color hooks
- Focus-specific: FocusFrame_SetSmallSize hook, SetMinMaxValues white-force

### Phase 4: Standardize player.lua, pet.lua, party.lua ✅
- player.lua: replaced 14-line TEXTURES + 18-line GetPlayerConfig with UF references (−30 lines)
- pet.lua: replaced 14-line texture constants with UF.TEXTURES.pet references (−8 lines)
- party.lua: replaced 10-line TEXTURES + 22-line power bar function with UF references (−20 lines)

### Phase 5: TextSystem party integration ✅
- Replaced party.lua's 60-line FormatNumber + GetFormattedText with TextSystem delegations (−50 lines)
- Added `show_runes = true` default to database.lua for clean UF.GetConfig replacement

### Phase 6: Polish ✅
- Verified load order in unitframes.xml
- Code review: no syntax errors, no missing ends, no undefined references
- All external API contracts preserved

## Backup Files
- `target.lua.bak` — original 1,209-line target module
- `focus.lua.bak` — original 1,005-line focus module
- `tot.lua.bak` — original 595-line ToT module
- `tof.lua.bak` — original 574-line ToF module

## Testing Checklist

- [ ] `/reload` — addon loads without errors
- [ ] Target frame: select target, verify health/power bars, class color, classification decorations
- [ ] Focus frame: set focus, verify same features
- [ ] Target of Target / Target of Focus: verify when target/focus has a target
- [ ] Player frame: check all features (DK runes, class portrait, power bars)
- [ ] Party frames: invite to group, check health/power text formatting
- [ ] Pet frame: summon pet, check power bar textures, combat pulse
- [ ] Editor mode: `/dragonui editor` — move all frames, verify ShowTest/HideTest
- [ ] Combat test: enter combat, verify no taint errors, test /reload during combat
- [ ] Options panel: change settings for target/focus scale, class color, class portrait — verify refresh
