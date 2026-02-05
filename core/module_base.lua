--[[
================================================================================
DragonUI - Module Base Template
================================================================================
Este archivo contiene el template base que todos los módulos de DragonUI
deben seguir para mantener consistencia y funcionalidad correcta.

USO:
1. Copia este template al crear un nuevo módulo
2. Reemplaza "ModuleName" con el nombre de tu módulo
3. Implementa las funciones Apply() y Restore()
4. Registra los eventos y hooks necesarios

IMPORTANTE:
- Siempre usar SafeCall() para modificaciones de frames seguros
- Trackear todos los eventos, hooks y frames creados
- Implementar cleanup correcto en Restore()
================================================================================
]]

local addon = select(2, ...)

-- ============================================================================
-- MODULE BASE MIXIN
-- Funciones compartidas que todos los módulos pueden usar
-- ============================================================================

addon.ModuleBase = {}

-- Crear un nuevo módulo con la estructura estándar
function addon.ModuleBase:New(moduleName)
    local Module = {
        name = moduleName,
        initialized = false,
        applied = false,
        originalStates = {},      -- Estados originales para restaurar
        registeredEvents = {},    -- Eventos registrados (para cleanup)
        hooks = {},               -- Hooks registrados (para cleanup)
        stateDrivers = {},        -- State drivers registrados (para cleanup)
        frames = {},              -- Frames creados (para cleanup)
        pendingUpdate = false,    -- Si hay operación pendiente por combate
        eventFrame = nil          -- Frame para manejar eventos
    }
    
    -- Almacenar referencia global
    addon[moduleName .. "Module"] = Module
    
    return Module
end

-- ============================================================================
-- COMBAT SAFETY SYSTEM
-- Sistema centralizado para manejar operaciones seguras en combate
-- ============================================================================

addon.CombatSafety = {
    pendingOperations = {},
    eventFrame = nil,
    initialized = false
}

function addon.CombatSafety:Initialize()
    if self.initialized then return end
    
    self.eventFrame = CreateFrame("Frame")
    self.eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
    self.eventFrame:SetScript("OnEvent", function(_, event)
        if event == "PLAYER_REGEN_ENABLED" then
            self:ExecuteAllPending()
        end
    end)
    
    self.initialized = true
end

function addon.CombatSafety:AddPending(id, func, ...)
    self.pendingOperations[id] = {
        func = func,
        args = {...}
    }
end

function addon.CombatSafety:ExecutePending(id)
    local operation = self.pendingOperations[id]
    if operation then
        local success, err = pcall(operation.func, unpack(operation.args))
        if not success then
            print("|cFFFF0000[DragonUI]|r Error executing pending operation:", err)
        end
        self.pendingOperations[id] = nil
    end
end

function addon.CombatSafety:ExecuteAllPending()
    for id, _ in pairs(self.pendingOperations) do
        self:ExecutePending(id)
    end
end

function addon.CombatSafety:HasPending(id)
    return self.pendingOperations[id] ~= nil
end

-- Función de utilidad para llamadas seguras en combate
-- Retorna: success (bool), result (any)
-- Si estamos en combate, registra la operación para después y retorna false
function addon.SafeCall(operationId, func, ...)
    if InCombatLockdown() then
        addon.CombatSafety:Initialize()
        addon.CombatSafety:AddPending(operationId, func, ...)
        return false, nil
    end
    
    local success, result = pcall(func, ...)
    if not success then
        print("|cFFFF0000[DragonUI]|r Error in SafeCall:", result)
        return false, nil
    end
    
    return true, result
end

-- ============================================================================
-- EVENT MANAGEMENT HELPERS
-- Funciones de ayuda para manejar eventos con tracking
-- ============================================================================

-- Registrar un evento con tracking automático
function addon.ModuleBase:RegisterEvent(module, event, handler)
    if not module.eventFrame then
        module.eventFrame = CreateFrame("Frame")
        module.eventFrame:SetScript("OnEvent", function(self, event, ...)
            local handler = module.registeredEvents[event]
            if handler then
                if type(handler) == "function" then
                    handler(event, ...)
                elseif type(handler) == "string" and module[handler] then
                    module[handler](module, event, ...)
                end
            end
        end)
    end
    
    if not module.registeredEvents[event] then
        module.registeredEvents[event] = handler
        module.eventFrame:RegisterEvent(event)
        return true
    end
    
    return false
end

-- Desregistrar un evento con cleanup
function addon.ModuleBase:UnregisterEvent(module, event)
    if module.registeredEvents[event] then
        if module.eventFrame then
            module.eventFrame:UnregisterEvent(event)
        end
        module.registeredEvents[event] = nil
        return true
    end
    return false
end

-- Desregistrar todos los eventos de un módulo
function addon.ModuleBase:UnregisterAllEvents(module)
    if module.eventFrame then
        module.eventFrame:UnregisterAllEvents()
    end
    module.registeredEvents = {}
end

-- ============================================================================
-- HOOK MANAGEMENT HELPERS
-- Funciones de ayuda para manejar hooks con tracking
-- ============================================================================

-- Registrar un hook seguro con tracking
function addon.ModuleBase:SecureHook(module, target, method, hookFunc)
    local hookId = tostring(target) .. "_" .. method
    
    if not module.hooks[hookId] then
        hooksecurefunc(target, method, hookFunc)
        module.hooks[hookId] = {
            target = target,
            method = method,
            func = hookFunc
        }
        return true
    end
    
    return false
end

-- Registrar un hook en función global
function addon.ModuleBase:SecureHookGlobal(module, funcName, hookFunc)
    if not module.hooks[funcName] then
        hooksecurefunc(funcName, hookFunc)
        module.hooks[funcName] = {
            funcName = funcName,
            func = hookFunc
        }
        return true
    end
    
    return false
end

-- ============================================================================
-- STATE DRIVER MANAGEMENT
-- Funciones para manejar state drivers con tracking
-- ============================================================================

-- Registrar un state driver con tracking
function addon.ModuleBase:RegisterStateDriver(module, frame, state, condition)
    local driverId = tostring(frame) .. "_" .. state
    
    if not module.stateDrivers[driverId] then
        RegisterStateDriver(frame, state, condition)
        module.stateDrivers[driverId] = {
            frame = frame,
            state = state,
            condition = condition
        }
        return true
    end
    
    return false
end

-- Desregistrar un state driver
function addon.ModuleBase:UnregisterStateDriver(module, frame, state)
    local driverId = tostring(frame) .. "_" .. state
    
    if module.stateDrivers[driverId] then
        UnregisterStateDriver(frame, state)
        module.stateDrivers[driverId] = nil
        return true
    end
    
    return false
end

-- Desregistrar todos los state drivers de un módulo
function addon.ModuleBase:UnregisterAllStateDrivers(module)
    for id, driver in pairs(module.stateDrivers) do
        UnregisterStateDriver(driver.frame, driver.state)
    end
    module.stateDrivers = {}
end

-- ============================================================================
-- FRAME MANAGEMENT HELPERS
-- Funciones para manejar frames creados con tracking
-- ============================================================================

-- Registrar un frame creado para cleanup posterior
function addon.ModuleBase:RegisterFrame(module, frameName, frame)
    module.frames[frameName] = frame
end

-- Ocultar y limpiar todos los frames de un módulo
function addon.ModuleBase:HideAllFrames(module)
    for name, frame in pairs(module.frames) do
        if frame and frame.Hide then
            frame:Hide()
        end
    end
end

-- ============================================================================
-- ORIGINAL STATE MANAGEMENT
-- Funciones para guardar y restaurar estados originales
-- ============================================================================

-- Guardar el estado original de un frame
function addon.ModuleBase:SaveOriginalState(module, frameName, frame)
    if not frame then return end
    
    module.originalStates[frameName] = {
        isShown = frame:IsShown(),
        alpha = frame:GetAlpha(),
        scale = frame:GetScale(),
        point = {frame:GetPoint(1)}
    }
end

-- Restaurar el estado original de un frame
function addon.ModuleBase:RestoreOriginalState(module, frameName, frame)
    if not frame then return end
    
    local state = module.originalStates[frameName]
    if not state then return end
    
    -- No modificar frames seguros en combate
    if InCombatLockdown() then
        addon.SafeCall("restore_" .. frameName, function()
            addon.ModuleBase:RestoreOriginalState(module, frameName, frame)
        end)
        return
    end
    
    frame:SetAlpha(state.alpha or 1)
    frame:SetScale(state.scale or 1)
    
    if state.point and state.point[1] then
        frame:ClearAllPoints()
        frame:SetPoint(unpack(state.point))
    end
    
    if state.isShown then
        frame:Show()
    else
        frame:Hide()
    end
end

-- ============================================================================
-- MODULE LIFECYCLE HELPERS
-- Funciones para el ciclo de vida del módulo
-- ============================================================================

-- Verificar si un módulo está habilitado en la configuración
function addon.ModuleBase:IsModuleEnabled(moduleName)
    local cfg = addon.db and addon.db.profile and addon.db.profile.modules 
                and addon.db.profile.modules[moduleName:lower()]
    return cfg and cfg.enabled
end

-- Obtener la configuración de un módulo
function addon.ModuleBase:GetModuleConfig(moduleName)
    return addon.db and addon.db.profile and addon.db.profile.modules 
           and addon.db.profile.modules[moduleName:lower()]
end

-- Cleanup completo de un módulo
function addon.ModuleBase:Cleanup(module)
    -- Desregistrar todos los eventos
    self:UnregisterAllEvents(module)
    
    -- Desregistrar todos los state drivers
    self:UnregisterAllStateDrivers(module)
    
    -- Ocultar todos los frames creados
    self:HideAllFrames(module)
    
    -- Restaurar estados originales
    for frameName, _ in pairs(module.originalStates) do
        local frame = module.frames[frameName] or _G[frameName]
        if frame then
            self:RestoreOriginalState(module, frameName, frame)
        end
    end
    
    -- Marcar como no aplicado
    module.applied = false
end

-- ============================================================================
-- MODULE TEMPLATE
-- Template completo para copiar al crear nuevos módulos
-- ============================================================================

--[[
-- Copiar este template para crear un nuevo módulo:

local addon = select(2, ...)
local ModuleName = "MiModulo"  -- Cambiar por el nombre del módulo

-- ============================================================================
-- MODULE CONFIGURATION
-- ============================================================================

local function GetModuleConfig()
    return addon.db and addon.db.profile and addon.db.profile.modules 
           and addon.db.profile.modules[ModuleName:lower()]
end

local function IsModuleEnabled()
    local cfg = GetModuleConfig()
    return cfg and cfg.enabled
end

-- ============================================================================
-- MODULE STATE TRACKING
-- ============================================================================

local Module = addon.ModuleBase:New(ModuleName)

-- ============================================================================
-- MODULE FUNCTIONS
-- ============================================================================

local function Apply()
    if not IsModuleEnabled() then return end
    if Module.applied then return end
    
    -- Verificar combate para frames seguros
    local success = addon.SafeCall(ModuleName .. "_apply", function()
        -- Guardar estados originales
        -- Aplicar cambios
        -- Registrar eventos
        -- Crear hooks
        
        Module.applied = true
    end)
    
    if not success then
        Module.pendingUpdate = true
    end
end

local function Restore()
    if not Module.applied then return end
    
    local success = addon.SafeCall(ModuleName .. "_restore", function()
        -- Cleanup usando ModuleBase
        addon.ModuleBase:Cleanup(Module)
    end)
    
    if not success then
        Module.pendingUpdate = true
    end
end

local function Initialize()
    if Module.initialized then return end
    if not IsModuleEnabled() then return end
    
    Apply()
    Module.initialized = true
end

-- ============================================================================
-- PROFILE CALLBACKS
-- ============================================================================

local function OnProfileChanged()
    if IsModuleEnabled() then
        if not Module.applied then
            Apply()
        else
            -- Refresh settings
        end
    else
        Restore()
    end
end

-- ============================================================================
-- PUBLIC API
-- ============================================================================

function addon["Refresh" .. ModuleName]()
    if not IsModuleEnabled() then return end
    -- Lógica de refresh
end

function addon["Refresh" .. ModuleName .. "System"]()
    if IsModuleEnabled() then
        if not Module.initialized then
            Initialize()
        else
            addon["Refresh" .. ModuleName]()
        end
    else
        Restore()
    end
end

-- ============================================================================
-- INITIALIZATION
-- ============================================================================

-- Registrar para inicialización cuando DragonUI esté listo
local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("PLAYER_LOGIN")
initFrame:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_LOGIN" then
        -- Esperar a que addon.db esté disponible
        if addon.db then
            Initialize()
            
            -- Registrar callbacks de perfil
            addon.db.RegisterCallback(addon, "OnProfileChanged", OnProfileChanged)
            addon.db.RegisterCallback(addon, "OnProfileCopied", OnProfileChanged)
            addon.db.RegisterCallback(addon, "OnProfileReset", OnProfileChanged)
        end
        self:UnregisterEvent("PLAYER_LOGIN")
    end
end)

]]

print("|cFF00FF00[DragonUI]|r Module Base loaded")
