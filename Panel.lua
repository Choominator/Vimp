local function Probe(region)
    return region:IsObjectType("Frame")
end

local function Describe(region, strings)
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
    if not Vimp_Window:Probe(frame) then
        Vimp_Window:CreateDriver(frame, Probe, Describe)
    end
    Vimp_Reader:HandleWindow(frame)
end

hooksecurefunc("ShowUIPanel", OnPanelShow)
