local function Probe(region)
    return region:IsObjectType("Frame") and region:GetName():find("^ContainerFrame%d+$") ~= nil
end

local function Describe(...)
    local region, strings = ...
    local speak = false
    if not strings then
        region = Vimp_Reader:GetRoot()
        strings = {}
        speak = true
    end
    table.insert(strings, GetBagName(region:GetID()))
    if not speak then
        return strings
    end
    table.insert(strings, "Container")
    Vimp_Say(strings)
end

local function OnShow(frame)
    Vimp_Window:CreateDriver(frame, Probe, Describe)
    Vimp_Reader:HandleWindow(frame)
end

for index = 1, NUM_CONTAINER_FRAMES do
    _G["ContainerFrame" .. index]:HookScript("OnShow", OnShow)
end
