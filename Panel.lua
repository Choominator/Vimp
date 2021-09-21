local function Probe(region)
    return region:IsObjectType("Frame")
end

local function Describe(...)
    local region, strings = ...
    local speak = false
    if not strings then
        region = Vimp_Reader:GetRoot()
        strings = {}
        speak = true
    end
    local name = region:GetName():gsub("Frame", "")
    table.insert(strings, name)
    if not speak then
        return strings
    end
    table.insert(strings, "Panel")
    Vimp_Say(strings)
end

local function OnPanelShow(frame)
    Vimp_Window:CreateDriver(frame, Probe, Describe)
    Vimp_Reader:HandleWindow(frame)
end

hooksecurefunc("ShowUIPanel", OnPanelShow)
