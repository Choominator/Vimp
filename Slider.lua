local function Probe(region)
    return region:GetObjectType() == "Slider"
end

local function Describe(region, strings)
    local speak = false
    if not strings then
        region = Vimp_Reader:GetFocus()
        strings = {}
        speak = true
    end
    Vimp_Strings(strings, region:GetRegions())
    Vimp_Strings(strings, region:GetChildren())
    if not speak then
        return strings
    end
    table.insert(strings, region:GetOrientation() .. " Slider")
    if not region:IsEnabled() then
        table.insert(strings, "Disabled")
    end
    Vimp_Say(strings)
end

local function Activate()
    Vimp_Say("Not interactable!  Use the arrow keys to move the slider's thumb.")
end

local function Direct(direction)
    local focus = Vimp_Reader:GetFocus()
    if not focus:IsEnabled() then
        Vimp_Say("Disabled!")
        return
    end
    local backward = false
    if direction == "UP" or direction == "LEFT" then
        backward = true
    end
    local low, high = focus:GetMinMaxValues()
    local current = focus:GetValue()
    local step = focus:GetValueStep()
    if step == 0 then
        step = (high - low) / 10
    end
    if not focus:GetObeyStepOnDrag() and IsShiftKeyDown() then
        step = step / 10
    end
    local new = (math.floor((current - low) / step + 0.5) + (not backward and 1 or -1)) * step + low
    new = max(low, min(new, high))
    focus:SetValue(new)
    ExecuteFrameScript(focus, "OnValueChanged", new, true)
    local strings = Describe(focus, {})
    Vimp_Say(strings)
end

Vimp_Driver:Create(Probe, Describe, Vimp_Dummy, Activate, Vimp_Dummy, Direct)
