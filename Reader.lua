local focusedFrame = nil
local topFrame = nil
local focusStack = {}

local function IsEligible(frame)
    if not frame then
        return false
    end
    while frame do
        if frame:IsForbidden() or not frame:IsShown() then
            return false
        end
        frame = frame:GetParent()
    end
    return true
end

local function GetStrings(frame)
    if frame:IsForbidden() or not frame:IsShown() then
        return ""
    end
    local text = ""
    if frame.GetText and frame:GetText() and frame:GetText():find("%S") then
        text = frame:GetText() .. "\n"
    end
    if frame.GetChildren then
        for index, region in ipairs({frame:GetRegions()}) do
            text = text .. GetStrings(region)
        end
        for index, child in ipairs({frame:GetChildren()}) do
            text = text .. GetStrings(child)
        end
    end
    return text
end

function ReadTooltip(frame)
    local tooltipOwner = GameTooltip:GetOwner()
    if frame ~= tooltipOwner then
        if tooltipOwner then
            ExecuteFrameScript(tooltipOwner, "OnLeave", false)
        end
        ExecuteFrameScript(frame, "OnEnter", false)
    end
    local text = GetStrings(GameTooltip)
    if frame ~= tooltipOwner then
        ExecuteFrameScript(frame, "OnLeave", false)
        if tooltipOwner then
            ExecuteFrameScript(tooltipOwner, "OnEnter", false)
        end
    end
    return text
end

local function Text(frame)
    if not IsEligible(frame) then
        return nil
    end
    local text = ""
    for index, region in ipairs({frame:GetRegions()}) do
        if region:IsShown() and region.GetText and region:GetText() and region:GetText():find("%S") then
            text = text .. region:GetText() .. "\n"
        end
    end
    if frame:IsObjectType("Button") then
        text = text .. ReadTooltip(frame) .. "\n"
        if not text:find("%S") then
            text = (frame:GetName() or "") .. "\n"
        end
    end
    if not text:find("%S") then
        return nil
    end
    text = text .. "\n"
    if frame:GetObjectType() ~= "Frame" then
        text = text .. frame:GetObjectType()
    end
    if frame.GetChecked then
        text = text .. (frame:GetChecked() and ", Checked" or ", Not Checked")
    end
    if frame.IsEnabled and not frame:IsEnabled() then
        text = text .. ", Disabled"
    elseif frame.Click then
        text = text .. ", Clickable"
    end
    return text
end

local function Explore(frame, backward)
    if not IsEligible(frame) then
        return nil
    end
    if not backward and not focusedFrame then
        local text = Text(frame)
        if text then
            focusedFrame = frame
            return text
        end
    end
    if frame == focusedFrame then
        focusedFrame = nil
        if backward then
            return nil
        end
    end
    local children = {frame:GetChildren()}
    if #children > 0 then
        local first = 1
        local last = #children
        local increment = 1
        if backward then
            first, last = last, first
            increment = -1
        end
        for index = first, last, increment do
            local child = children[index]
            local text = Explore(child, backward)
            if text then
                return text
            end
        end
    end
    if backward and not focusedFrame then
        local text = Text(frame)
        if text then
            focusedFrame = frame
            return text
        end
    end
    return nil
end

local function Next(backward)
    if not topFrame then
        Vimp_Read("Lost focus")
        focusedFrame = nil
        return
    end
    if not IsEligible(focusedFrame) then
        focusedFrame = nil
    end
    local savedFocus = focusedFrame
    local text = Explore(topFrame, backward)
    if not text then
        focusedFrame = savedFocus
        text = Text(focusedFrame)
        if not text then
            Vimp_Read("Nothing to read")
            return
        end
        if not backward then
            Vimp_Read("Last element\n" .. Text(focusedFrame))
        else
            Vimp_Read("First element\n" .. Text(focusedFrame))
        end
        return
    end
    Vimp_Read(text)
end

local function Click()
    if not focusedFrame then
        Vimp_Read("Lost focus")
        return
    end
    if not focusedFrame.Click then
        Vimp_Read("Not clickable")
        return
    end
    if focusedFrame.IsEnabled and not focusedFrame:IsEnabled() then
        Vimp_Read("Disabled")
        return
    end
    if focusedFrame.GetChecked then
        Vimp_Read((focusedFrame:GetChecked() and "Unchecked: " or "Checked: ") .. Text(focusedFrame))
    else
        Vimp_Read("Click: " .. Text(focusedFrame))
    end
    focusedFrame:Click()
end

local function PushFrame(frame)
    if frame == topFrame or frame:IsForbidden() then
        return
    end
    for index = 1, #focusStack do
        if focusStack[index].top == frame then
            return
        end
    end
    if topFrame then
        table.insert(focusStack, {top = topFrame, focused = focusedFrame})
    else
        Vimp_EnableKeyboard()
    end
    topFrame = frame
    focusedFrame = nil
    Next(false)
end

local function DiscardFrame(frame)
    if not frame then
        return
    end
    if frame ~= topFrame and #focusStack > 0 then
        for index = #focusStack, 1 do
            if focusStack[index].top == frame then
                table.remove(focusStack, index)
            end
        end
        return
    end
    local lastFocused = focusStack[#focusStack]
    if lastFocused then
        table.remove(focusStack)
        focusedFrame = lastFocused.focused
        topFrame = lastFocused.top
        local text = nil
        if focusedFrame then
            text = Text(focusedFrame)
        end
        if text then
            Read(text)
        else
            Next(false)
        end
    else
        focusedFrame = nil
        topFrame = nil
        Vimp_DisableKeyboard()
    end
end

local shownContainers = 0

local function ShowContainer(frame)
    if shownContainers == 0 then
        PushFrame(ContainerParentFrame)
    end
    shownContainers = shownContainers + 1
end

local function HideContainer(frame)
    shownContainers = shownContainers - 1
    if shownContainers == 0 then
        DiscardFrame(ContainerParentFrame)
    end
end

local function ShowPopup(frame)
    PushFrame(frame)
end

local function HidePopup(frame, ...)
    DiscardFrame(frame)
end

function Vimp_Repeat()
    Vimp_Stop()
    Vimp_Read(Text(focusedFrame))
end

function Vimp_Prev()
    Vimp_Stop()
    Next(true)
end

function Vimp_Next()
    Vimp_Stop()
    Next(false)
end

function Vimp_Click()
    Vimp_Stop()
    Click()
end

function Vimp_Dec()
    Vimp_Stop()
    Vimp_Read("Not decrementable")
end

function Vimp_Inc()
    Vimp_Stop()
    Vimp_Read("Not incrementable")
end

hooksecurefunc("ShowUIPanel", PushFrame)
hooksecurefunc("HideUIPanel", DiscardFrame)

ContainerParentFrame = CreateFrame("Frame", "ContainerParentFrame", UIParent)
ContainerParentFrame:SetPoint("TOPLEFT")
ContainerParentFrame:SetPoint("BottomRight")

BankFrame:SetParent(ContainerParentFrame)
BankFrame:HookScript("OnShow", ShowContainer)
BankFrame:HookScript("OnHide", HideContainer)
for index = 1, NUM_CONTAINER_FRAMES do
    _G["ContainerFrame" .. index]:SetParent(ContainerParentFrame)
    _G["ContainerFrame" .. index]:HookScript("OnShow", ShowContainer)
    _G["ContainerFrame" .. index]:HookScript("OnHide", HideContainer)
end

for index = 1, STATICPOPUP_NUMDIALOGS do
    _G["StaticPopup" .. index]:HookScript("OnShow", ShowPopup)
    _G["StaticPopup" .. index]:HookScript("OnHide", HidePopup)
end
