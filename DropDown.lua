local menuFocus = {}

local cursor = CreateFrame("Frame", nil, UIParent)
local top = cursor:CreateLine()
top:SetColorTexture(1, 1, 1, 1)
top:SetStartPoint("TOPLEFT")
top:SetEndPoint("TOPRIGHT")
top:SetThickness(2)
local bottom = cursor:CreateLine()
bottom:SetColorTexture(1, 1, 1, 1)
bottom:SetStartPoint("BOTTOMLEFT")
bottom:SetEndPoint("BOTTOMRIGHT")
bottom:SetThickness(2)
local left = cursor:CreateLine()
left:SetColorTexture(1, 1, 1, 1)
left:SetStartPoint("TOPLEFT")
left:SetEndPoint("BOTTOMLEFT")
left:SetThickness(2)
local right = cursor:CreateLine()
right:SetColorTexture(1, 1, 1, 1)
right:SetStartPoint("TOPRIGHT")
right:SetEndPoint("BOTTOMRIGHT")
right:SetThickness(2)
cursor:EnableKeyboard(true)
cursor:SetFrameStrata("TOOLTIP")
cursor:SetFrameLevel(10000)
cursor:HasFixedFrameStrata(true)
cursor:HasFixedFrameLevel(true)
cursor:Hide()


local function Probe(region)
    return region.Text ~= nil and region.Button ~= nil
end

local function Describe(...)
    local region, strings = ...
    local speak = false
    if not strings then
        region = Vimp_Reader:GetFocus()
        strings = {}
        speak = true
    end
    local text = region.Text:GetText()
    table.insert(strings, text)
    table.insert(strings, region.selectedName)
    if not speak then
        return strings
    end
    table.insert(strings, "Menu")
    Vimp_Say(strings)
end

local function Activate()
    local region = Vimp_Reader:GetFocus()
    Vimp_Say({"Click", region.Text:GetText()})
    ExecuteFrameScript(region.Button, "OnMouseDown", "LeftButton")
end

local function Dummy()
    error("This function must never be called", 2)
end

local function MenuDescribe()
    local focus = menuFocus[#menuFocus]
    local strings = {}
    table.insert(strings, focus:GetText())
    local name = focus:GetName()
    if _G[name .. "Check"]:IsShown() then
        table.insert(strings, "Checked")
    elseif _G[name .. "UnCheck"]:IsShown() then
        table.insert(strings, "Unchecked")
    end
    if _G[name .. "ExpandArrow"]:IsShown() then
        table.insert(strings, "Submenu")
    end
    if not focus:IsEnabled() then
        table.insert(strings, "Disabled")
    end
    Vimp_Say(strings)
end

local function Children(children, child, ...)
    if not child then
        return children
    end
    if not child:IsForbidden() and child:IsShown() and child.GetText and child:GetText() then
        table.insert(children, child)
    end
    return Children(children, ...)
end

local function MenuNext(backward)
    Vimp_Shut()
    local focus = menuFocus[#menuFocus]
    local parent = focus:GetParent()
    local siblings =Children({}, parent:GetChildren())
    local first, last, increment = 1, #siblings, 1
    if backward then
        first, last, increment = last, first, -1
    end
    for index = first, last, increment do
        if not focus and siblings[index]:GetText() then
            focus = siblings[index]
            break
        end
        if siblings[index] == focus then
            focus = nil
        end
    end
    if not focus then
        focus = siblings[first]
    end
    menuFocus[#menuFocus] = focus
    MenuDescribe()
end

local function MenuActivate()
    Vimp_Shut()
    local focus = menuFocus[#menuFocus]
    if not focus.IsEnabled then
        Vimp_Say("Not clickable!")
        return
    end
    if not focus:IsEnabled() then
        Vimp_Say("Disabled!")
        return
    end
    Vimp_Say({"Click", focus:GetText()})
    if _G[focus:GetName() .. "ExpandArrow"] then
        ExecuteFrameScript(focus, "OnEnter", false)
        ExecuteFrameScript(focus, "OnLeave", false)
    else
        focus:Click()
    end
end

local function MenuDismiss()
    Vimp_Shut()
    local parent = menuFocus[#menuFocus]:GetParent()
    table.remove(menuFocus)
    parent:Hide()
    if #menuFocus > 0 then
        MenuDescribe()
    end
end

local function OnMenuShow(frame)
    local children =Children({}, frame:GetChildren())
    if #children == 0 then
        return
    end
    table.insert(menuFocus, children[1])
    if frame:GetID() == 1 then
        Vimp_Reader:Disable()
        cursor:Show()
    end
    MenuDescribe()
end

local function OnMenuHide(frame)
    local level = frame:GetID()
    if level == 1 then
        table.wipe(menuFocus)
        cursor:Hide()
        Vimp_Reader:Enable()
        return
    end
    if not menuFocus[level] then
        return
    end
    menuFocus[level] = nil
    MenuDescribe()
end

local menuLevelCount = 0

local function OnMenuCreate()
    if UIDROPDOWNMENU_MAXLEVELS <= menuLevelCount then
        return
    end
    for index = menuLevelCount + 1, UIDROPDOWNMENU_MAXLEVELS do
        local frame = _G["DropDownList" .. index]
        frame:HookScript("OnShow", OnMenuShow)
        frame:HookScript("OnHide", OnMenuHide)
    end
    menuLevelCount =  UIDROPDOWNMENU_MAXLEVELS
end

local function OnCursorUpdate(frame)
    local focus = menuFocus[#menuFocus]
    if not focus then
        cursor:Hide()
    end
    cursor:SetAllPoints(focus)
    cursor:Show()
    cursor:SetPropagateKeyboardInput(false)
end

local function OnCursorKeyDown(frame, key)
    frame:SetPropagateKeyboardInput(false)
    if key == "DOWN" then
        if not IsShiftKeyDown() then
            MenuActivate()
        else
            MenuDescribe()
        end
    elseif key == "UP" then
        MenuDismiss()
    elseif key == "LEFT" then
        MenuNext(true)
    elseif key == "RIGHT" then
        MenuNext(false)
    else
        frame:SetPropagateKeyboardInput(true)
    end
end

cursor:SetScript("OnUpdate", OnCursorUpdate)
cursor:SetScript("OnKeyDown", OnCursorKeyDown)
Vimp_Driver:Create(Probe, Describe, Dummy, Activate, Dummy)
hooksecurefunc("UIDropDownMenu_CreateFrames", OnMenuCreate)
OnMenuCreate()
