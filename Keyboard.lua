local isEnabled = false
local actions = nil

actions = {
    VIMPREPEAT = Vimp_Repeat,
    VIMPPREV = Vimp_Prev,
    VIMPNEXT = Vimp_Next,
    VIMPCLICK = Vimp_Click,
    VIMPDEC = Vimp_Dec,
    VIMPINC = Vimp_Inc
}

local function MatchKeyCombo(combo, ...)
    if not combo then
        return false
    end
    if not not combo:find("[LR]?CTRL%-") == IsControlKeyDown() then
        if combo:find("LCTRL%-") and not IsLeftControlKeyDown() then
            return MatchKeyCombo(...)
        end
        if combo:find("RCTRL%-") and not IsRightControlKeyDown() then
            return MatchKeyCombo(...)
        end
    else
        return MatchKeyCombo(...)
    end
    if not not combo:find("[LR]?ALT%-") == IsAltKeyDown() then
        if combo:find("LALT%-") and not IsLeftAltKeyDown() then
            return MatchKeyCombo(...)
        end
        if combo:find("RALT%-") and not IsRightAltKeyDown() then
            return MatchKeyCombo(...)
        end
    else
        return MatchKeyCombo(...)
    end
    if not not combo:find("[LR]?META%-") == IsMetaKeyDown() then
        if combo:find("LMETA%-") and not IsLeftMetaKeyDown() then
            return MatchKeyCombo(...)
        end
        if combo:find("RMETA%-") and not IsRightMetaKeyDown() then
            return MatchKeyCombo(...)
        end
    else
        return MatchKeyCombo(...)
    end
    if not not combo:find("[LR]?SHIFT%-") == IsShiftKeyDown() then
        if combo:find("LSHIFT%-") and not IsLeftShiftKeyDown() then
            return MatchKeyCombo(...)
        end
        if combo:find("RSHIFT%-") and not IsRightShiftKeyDown() then
            return MatchKeyCombo(...)
        end
    else
        return MatchKeyCombo(...)
    end
    local key = combo:match("%-$") or combo:match("[^%-]+$")
    if not IsKeyDown(key) then
        return MatchKeyCombo(...)
    end
    return true
end

local function MatchAction(action)
    return MatchKeyCombo(GetBindingKey(action))
end

local function OnEvent(frame, event)
    if InCombatLockdown() then
        return
    end
    if event ~= "UPDATE_BINDINGS" then
        return
    end
    if GetBindingAction("'") == "" and not GetBindingKey("VIMPCLICK") then
        SetBinding("'", "VIMPCLICK")
    end
    if GetBindingAction("[") == "" and not GetBindingKey("VIMPPREV") then
        SetBinding("[", "VIMPPREV")
    end
    if GetBindingAction("]") == "" and not GetBindingKey("VIMPNEXT") then
        SetBinding("]", "VIMPNEXT")
    end
    if GetBindingAction("SHIFT-'") == "" and not GetBindingKey("VIMPREPEAT") then
        SetBinding("SHIFT-'", "VIMPREPEAT")
    end
    if GetBindingAction("SHIFT-[") == "" and not GetBindingKey("VIMPDEC") then
        SetBinding("SHIFT-[", "VIMPDEC")
    end
    if GetBindingAction("SHIFT-]") == "" and not GetBindingKey("VIMPINC") then
        SetBinding("SHIFT-]", "VIMPINC")
    end
end

local actionStates = {}

local function OnUpdate(frame)
    if not isEnabled then
        return
    end
    for action, script in pairs(actions) do
        local isActive = MatchAction(action)
        if isActive and not actionStates[action] then
            script()
        end
        actionStates[action] = isActive
    end
end

function Vimp_EnableKeyboard()
    isEnabled = true
end

function Vimp_DisableKeyboard()
    isEnabled = false
end

BINDING_HEADER_VIMP = "Vimp"
BINDING_NAME_VIMPREPEAT = "Read current element"
BINDING_NAME_VIMPPREV = "Read previous element"
BINDING_NAME_VIMPNEXT = "Read next element"
BINDING_NAME_VIMPCLICK = "Click on element"
BINDING_NAME_VIMPDEC = "Decrement element"
BINDING_NAME_VIMPINC = "Increment element"

WorldFrame:RegisterEvent("UPDATE_BINDINGS")
WorldFrame:HookScript("OnEvent", OnEvent)
WorldFrame:HookScript("OnUpdate", OnUpdate)
