local function Probe(region)
    return region:GetName() == "KeyBindingFrame"
end

local function Describe(region, strings)
    local speak = false
    if not strings then
        region = Vimp_Reader:GetRoot()
        strings = {}
        speak = true
    end
    table.insert(strings, "Key Binding")
    if not speak then
        return strings
    end
    Vimp_Say(strings)
end

local function ItemProbe(region)
    if not _G["KeyBindingFrameScrollFrame"] then
        return false
    end
    local name = region:GetName()
    if not name then
        return false
    end
    if name:find("^KeyBindingFrameScrollFrame") then
        return nil
    end
    if not name:find("^" .. KEY_BINDING_ROW_NAME .. "%d+$") then
        return false
    end
    if #Vimp_Children({}, region:GetRegions()) == 0 then
        return false
    end
    return true
end

local function ItemDescribe(region, strings)
    local speak = false
    if not strings then
        region = Vimp_Reader:GetFocus()
        strings = {}
        speak = true
    end
    local scrollBar = _G["KeyBindingFrameScrollFrame"].ScrollBar
    local _, range = scrollBar:GetMinMaxValues()
    range = math.floor(range / KEY_BINDING_HEIGHT)
    if range > 0 then
        local offset = math.floor(scrollBar:GetValue() / KEY_BINDING_HEIGHT)
        local row = region:GetName():match("^" .. KEY_BINDING_ROW_NAME .. "(%d+)$") - 1
        local bias = math.floor(KEY_BINDINGS_DISPLAYED / 2)
        local absolute = offset + row
        local relative = absolute < bias and absolute or absolute > range + bias and absolute - range or bias
        local offset = min(max(absolute - bias, 0), range)
        scrollBar:SetValue(offset * KEY_BINDING_HEIGHT)
        region = _G[KEY_BINDING_ROW_NAME .. relative + 1]
        Vimp_Reader:SetFocus(region)
    end
    Vimp_Strings(strings, region:GetRegions())
    Vimp_Strings(strings, region:GetChildren())
    if not speak then
        return strings
    end
    Vimp_Say(strings)
end

local function ItemNext(backward)
    local region = Vimp_Reader:GetFocus()
    local parent = Vimp_Reader:GetParent()
    if region == parent then
        region = nil
    end
    local children = {}
    Vimp_Children(children, parent:GetRegions())
    Vimp_Children(children, parent:GetChildren())
    if #children == 0 then
        Vimp_Say("Nothing to read!")
        local driver = Vimp_Driver:ProbeRegion(parent)
        driver.Dismiss(parent)
    end
    local first, last, increment = 1, #children, 1
    if backward then
        first, last, increment = last, first, -1
    end
    for index = first, last, increment do
        if not region then
            region = children[index]
            break
        end
        if children[index] == region then
            region = nil
        end
    end
    if not region then
        region = children[first]
    end
    Vimp_Reader:SetFocus(region)
    local driver = Vimp_Driver:ProbeRegion(region)
    driver.Describe()
end

local function ItemActivate()
    local region = Vimp_Reader:GetFocus()
    local parent = Vimp_Reader:GetParent()
    local strings = Vimp_Strings({}, parent:GetRegions())
    local name = table.concat(strings, "\n")
    if region == parent then
        Vimp_Say(string.format("Already interacting with %s", name))
        return
    end
    local strings = {"Enter", name}
    Vimp_Say(strings)
    Vimp_Reader:Push(region)
    ItemNext(false)
end

local function ItemDismiss()
    Vimp_Reader:Pop()
    local region = Vimp_Reader:GetFocus()
    local strings = Vimp_Strings({"Exit"}, region:GetRegions())
    Vimp_Say(strings)
    Describe()
end

local function OnPanelShow(frame)
    if Probe(frame) then
        Vimp_Window:CreateDriver(frame, Probe, Describe)
    end
end

hooksecurefunc("ShowUIPanel", OnPanelShow)
Vimp_Driver:Create(ItemProbe, ItemDescribe, ItemNext, ItemActivate, ItemDismiss, Vimp_Dummy)
