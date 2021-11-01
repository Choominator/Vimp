local function Probe(region)
    return region:IsObjectType("Frame") and region:GetName():find("^StaticPopup%d+$") ~= nil
end

local function Describe(region, strings)
    local speak = false
    if not strings then
        region = Vimp_Reader:GetRoot()
        strings = {}
        speak = true
    end
    table.insert(strings, "Popup")
    if not speak then
        return strings
    end
    Vimp_Say(strings)
end

local function OnShow(frame)
    Vimp_Window:CreateDriver(frame, Probe, Describe)
    Vimp_Reader:HandleWindow(frame)
end

for index = 1, STATICPOPUP_NUMDIALOGS do
    _G["StaticPopup" .. index]:HookScript("OnShow", OnShow)
end
