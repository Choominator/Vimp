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
    Vimp_Reader:HandleWindow(frame)
end

local function ItemProbe(region)
    local name = region:GetName()
    if not name then
        return false
    end
    if not name:find("^ContainerFrame%d+Item%d+$") and not name:find("^BankFrameItem%d+$") and not name:find("^ReagentBankFrameItem%d+$") then
        return false
    end
    return true
end

local QualityStrings = {
    [0] = "Poor",
    [1] = "Common",
    [2] = "Uncommon",
    [3] = "Rare",
    [4] = "Epic",
    [5] = "Legendary",
    [6] = "Artifact",
    [7] = "Heirloom",
}

local function ItemDescribe(...)
    local region, strings = ...
    local speak = false
    if not strings then
        region = Vimp_Reader:GetFocus()
        strings = {}
        speak = true
    end
    local bag = region:GetParent():GetID()
    local slot = region:GetID()
    local _, count, locked, _, readable, lootable, _, _, _, id = GetContainerItemInfo(bag, slot)
    if not id then
        if not speak then
            return strings
        end
        Vimp_Say("Empty slot!")
        return
    end
    local name, _, quality = GetItemInfo(id)
    if not name then
        if not speak then
            return strings
        end
        Vimp_Say("Loading Item description...")
        return
    end
    if count > 1 then
        table.insert(strings, string.format("Stack of %d %s", count, name))
    else
        table.insert(strings, name)
    end
    if not speak then
        return strings
    end
    if QualityStrings[quality] then
        table.insert(strings, string.format("%s Item", QualityStrings[quality]))
    else
        table.insert(strings, "Item")
    end
    if locked then
        table.insert(strings, "Locked")
    end
    if readable then
        table.insert(strings, "Readable")
    end
    if lootable then
        table.insert(strings, "Lootable")
    end
    Vimp_Say(strings)
end

local function ItemNext(backward)
    error("This function must never be called", 2)
end

local function ItemActivate()
    local focus = Vimp_Reader:GetFocus()
    local strings = {"Click"}
    ItemDescribe(focus, strings)
    Vimp_Say(strings)
    focus:Click()
end

local function ItemDismiss()
    error("This function must never be called", 2)
end

for index = 1, NUM_CONTAINER_FRAMES do
    local frame = _G["ContainerFrame" .. index]
    Vimp_Window:CreateDriver(frame, Probe, Describe)
    frame:HookScript("OnShow", OnShow)
end

Vimp_Driver:Create(ItemProbe, ItemDescribe, ItemNext, ItemActivate, ItemDismiss)
