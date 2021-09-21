local function Probe(region)
    local content = region.GetScrollChild and region:GetScrollChild()
    if not content then
        return false
    end
    local children = {}
    Vimp_Children(children, content:GetRegions())
    Vimp_Children(children, content:GetChildren())
    if #children == 0 then
        return false
    end
    return true
end

local function Describe(...)
    local region, strings = ...
    local speak = false
    if not strings then
        region = Vimp_Reader:GetFocus()
        strings = {}
        speak = true
    end
    local content = region:GetScrollChild()
    if not speak then
        Vimp_Strings(strings, content:GetRegions())
        Vimp_Strings(strings, content:GetChildren())
        return strings
    end
    local children = {}
    Vimp_Children(children, content:GetRegions())
    Vimp_Children(children, content:GetChildren())
    table.insert(strings, "Scroll")
    table.insert(strings, string.format("%d children", #children))
    Vimp_Say(strings)
end

local function Next(backward)
    local region = Vimp_Reader:GetFocus()
    local scroll = Vimp_Reader:GetParent()
    if region == scroll then
        region = nil
    end
    local content = scroll:GetScrollChild()
    local children = {}
    Vimp_Children(children, content:GetRegions())
    Vimp_Children(children, content:GetChildren())
    if #children == 0 then
        Vimp_Say("Nothing to read!")
        Vimp_Reader:SetFocus(scroll)
        return
    end
    local first, last, increment = 1, #children, 1
    if backward then
        first, last, increment = last, first, -1
    end
    for index = first, last, increment do
        local child = children[index]
        if not region then
            region = child
            break
        end
        if child == region then
            region = nil
        end
    end
    if not region then
        region = children[first]
    end
    local scrollHorizontalOrigin, scrollVerticalOrigin, scrollWidth, scrollHeight = scroll:GetScaledRect()
    local scrollScale = scroll:GetEffectiveScale()
    local regionHorizontalOrigin, regionVerticalOrigin, regionWidth, regionHeight = region:GetScaledRect()
    local horizontalRange = scroll:GetHorizontalScrollRange()
    local verticalRange = scroll:GetVerticalScrollRange()
    if horizontalRange > 0 then
        local scrollCenter = scrollHorizontalOrigin + scrollWidth / 2
        local regionCenter = regionHorizontalOrigin + regionWidth / 2
        local offset = regionCenter - scrollCenter
        local old = scroll:GetHorizontalScroll()
        local new = old + offset / scrollScale
        new = max(0, min(new, horizontalRange))
        scroll:SetHorizontalScroll(new)
    end
    if verticalRange > 0 then
        local scrollCenter = scrollVerticalOrigin + scrollHeight / 2
        local regionCenter = regionVerticalOrigin + regionHeight / 2
        local offset = regionCenter - scrollCenter
        local old = scroll:GetVerticalScroll()
        local new = old - offset / scrollScale
        new = max(0, min(new, verticalRange))
        scroll:SetVerticalScroll(new)
    end
    Vimp_Reader:SetFocus(region)
    local driver = Vimp_Driver:ProbeRegion(region)
    driver.Describe()
end

local function Activate()
    local focus = Vimp_Reader:GetFocus()
    local parent = Vimp_Reader:GetParent()
    if focus == parent then
        Vimp_Say("Already interacting with the scroll!")
        return
    end
    local strings = {"Enter", "Scroll"}
    Vimp_Say(strings)
    Vimp_Reader:Push(focus)
    Next(false)
end

local function Dismiss()
    Vimp_Reader:Pop()
    local strings = {"Exit", "Scroll"}
    Vimp_Say(strings)
    Describe()
end

Vimp_Driver:Create(Probe, Describe, Next, Activate, Dismiss)
