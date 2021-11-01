local function Probe(region)
    return region:GetObjectType() == "FontString" and region:GetText() ~= nil and region:GetText():find("%S") ~= nil
end

local function Describe(region, strings)
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

local function Activate()
    Vimp_Say("Not interactable!")
end

Vimp_Driver:Create(Probe, Describe, Vimp_Dummy, Activate, Vimp_Dummy, Vimp_Dummy)
