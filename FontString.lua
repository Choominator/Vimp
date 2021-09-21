local function Probe(region)
    return region:GetObjectType() == "FontString" and region:GetText() ~= nil and region:GetText():find("%S") ~= nil
end

local function Describe(...)
    local region, strings = ...
    local speak = false
    if not strings then
        region = Vimp_Reader:GetFocus()
        strings = {}
        speak = true
    end
    table.insert(strings, region:GetText())
    if not speak then
        return strings
    end
    Vimp_Say(strings)
end

local function Next(backward)
    error("This function must never be called", 2)
end

local function Activate()
    Vimp_Say("Not interactable!")
end

local function Dismiss()
    error("This function must never be called", 2)
end

Vimp_Driver:Create(Probe, Describe, Next, Activate, Dismiss)
