local function Probe(region)
    return (region.scrollChild or region.GetScrollChild and region:GetScrollChild()) ~= nil
end

local function HybridDescribe(region, strings)
    local children = {region.scrollChild:GetChildren()}
    local scrollBar = region.scrollBar
    local _, range = scrollBar:GetMinMaxValues()
    local height = range + region:GetHeight()
    local processedOffset = 0
    while processedOffset < height do
        local offset = min(processedOffset, range)
        scrollBar:SetValue(offset)
        offset = scrollBar:GetValue()
        local childHeight = not region.dynamic and children[1]:GetHeight()
        local alignedOffset = not region.dynamic and math.floor(offset / childHeight + 0.5) * childHeight or region.dynamic(offset)
        for index, child in ipairs(children) do
            if not child:IsEnabled() then
                return strings
            end
            alignedOffset = alignedOffset + child:GetHeight()
            if alignedOffset > processedOffset then
                Vimp_Strings(strings, child)
            end
        end
        processedOffset = alignedOffset
    end
    return strings
end

local function Describe(region, strings)
    local speak = false
    if not strings then
        region = Vimp_Reader:GetFocus()
        strings = {}
        speak = true
    end
    if region.scrollChild then
        HybridDescribe(region, strings)
    else
        local content = region:GetScrollChild()
        Vimp_Strings(strings, content:GetRegions())
        Vimp_Strings(strings, content:GetChildren())
    end
    if not speak then
        return strings
    end
    Vimp_Say({"Scroll", string.format("%d children", #strings)})
end

local function HybridNext(backward, scroll, region)
    local scrollBar = scroll.scrollBar
    local content = scroll.scrollChild
    local _, range = scrollBar:GetMinMaxValues()
    local children = {content:GetChildren()}
    while not children[#children]:IsEnabled() do
        table.remove(children)
    end
    if #children == 0 then
        Vimp_Say("Nothing to read!")
        local driver = Vimp_Driver:ProbeRegion(scroll)
        driver.Dismiss()
        return
    end
    if not region then
        local offset = not backward and 0 or range
        scrollBar:SetValue(offset)
        while not children[#children]:IsEnabled() do
            table.remove(children)
        end
        local child = not backward and children[1] or children[#children]
        Vimp_Reader:SetFocus(child)
        local driver = Vimp_Driver:ProbeRegion(child)
        driver.Describe()
        return
    end
    local offset = scrollBar:GetValue()
    local alignedHeight = not scroll.dynamic and math.floor(offset / region:GetHeight() + 0.5) * region:GetHeight() or offset - select(2, scroll.dynamic(offset))
    local next = nil
    for index, child in ipairs(children) do
        if child == region then
            next = children[not backward and index + 1 or index - 1]
            break
        end
        alignedHeight = alignedHeight + child:GetHeight()
    end
    if not next or not next:IsEnabled() then
        HybridNext(backward, scroll, nil)
        return
    end
    local nextHeight = next:GetHeight()
    local nextCenter = not backward and alignedHeight + region:GetHeight() + nextHeight / 2 or alignedHeight - nextHeight / 2
    local offset = min(max(nextCenter - scroll:GetHeight() / 2, 0), range)
    scrollBar:SetValue(offset)
    offset = scrollBar:GetValue()
    local alignedHeight = not scroll.dynamic and math.floor(offset / nextHeight + 0.5) * nextHeight or offset - select(2, scroll.dynamic(offset))
    region = nil
    for index, child in ipairs(children) do
        alignedHeight = alignedHeight + child:GetHeight()
        if alignedHeight > nextCenter then
            region = child
            break
        end
    end
    if not region or not region:IsEnabled() then
        HybridNext(backward, scroll, nil)
        return
    end
    Vimp_Reader:SetFocus(region)
    local driver = Vimp_Driver:ProbeRegion(region)
    driver.Describe(region)
end

local function Next(backward)
    local region = Vimp_Reader:GetFocus()
    local scroll = Vimp_Reader:GetParent()
    if region == scroll then
        region = nil
    end
    if scroll.scrollChild then
        HybridNext(backward, scroll, region)
        return
    end
    local content = scroll:GetScrollChild()
    local children = {}
    Vimp_Children(children, content:GetRegions())
    Vimp_Children(children, content:GetChildren())
    if #children == 0 then
        Vimp_Say("Nothing to read!")
        local driver = Vimp_Driver:ProbeRegion(scroll)
        driver.Dismiss()
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

Vimp_Driver:Create(Probe, Describe, Next, Activate, Dismiss, Vimp_Dummy)
