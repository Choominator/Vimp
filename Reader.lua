local openWindows = {}
local topWindow = nil
local focusedRegion = nil
local clickState = nil

-- Create the cursor outline
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
cursor:Hide()

-- Recursively extracts all the text from a Frame or FontString
local function GetText(region, validate)
    if region:IsForbidden() or not region:IsShown() then
        return nil
    end
    if region:IsObjectType("FontString") then
        local text = region:GetText()
        if text and text:find("%S") then
            return text .. "\n"
        end
        return nil
    end
    if not region:IsObjectType("Frame") then
        return nil
    end
    local text = ""
    for index, region in ipairs({region:GetRegions()}) do
        text = text .. (GetText(region, validate) or "")
        if validate and text:find("%S") then
            return text
        end
    end
    for index, region in ipairs({region:GetChildren()}) do
        text = text .. (GetText(region, validate) or "")
        if validate and text:find("%S") then
            return text
        end
    end
    if text:find("%S") then
        return text
    end
    if region:IsObjectType("Button") and region:GetName() then
        return region:GetName() .. "\n"
    end
    return nil
end

-- Returns a list of readable elements
local function Flatten(region, flattened)
    if region:IsForbidden() or not region:IsShown() then
        return flattened
    end
    if (region:IsObjectType("FontString") or region:IsObjectType("Button")) and region ~= topWindow then
        if GetText(region, true) then
            table.insert(flattened, region)
        end
        return flattened
    end
    if region:IsObjectType("Slider") then
        local min, max = region:GetMinMaxValues()
        if min ~= max then
            table.insert(flattened, region)
        end
        return flattened
    end
    if not region:IsObjectType("Frame") then
        return flattened
    end
    for index, region in ipairs({region:GetRegions()}) do
        Flatten(region, flattened)
    end
    for index, region in ipairs({region:GetChildren()}) do
        Flatten(region, flattened)
    end
    return flattened
end

-- Returns all the text from the tooltip associated with focusedRegion
local function GetTooltip()
    if not focusedRegion then
        error("Called with an undefined focusedRegion")
    end
    local tooltipOwner = GameTooltip:GetOwner()
    if focusedRegion ~= tooltipOwner then
        if tooltipOwner then
            ExecuteFrameScript(tooltipOwner, "OnLeave", false)
        end
        ExecuteFrameScript(focusedRegion, "OnEnter", false)
    end
    local text = ""
    if GameTooltip:GetOwner() == focusedRegion then
        text = GetText(GameTooltip) or ""
    end
    if focusedRegion ~= tooltipOwner then
        ExecuteFrameScript(focusedRegion, "OnLeave", false)
        if tooltipOwner then
            ExecuteFrameScript(tooltipOwner, "OnEnter", false)
        end
    end
    return text
end

-- Reads the text from focusedRegion
local function Read()
    if not focusedRegion then
        error("Called with an undefined focusedRegion")
    end
    local text = GetText(focusedRegion, false)
    if not text then
        error("Could not find any text in focusedRegion")
    end
    if focusedRegion:IsObjectType("Button") then
        text = text .. GetTooltip()
    end
    local regionType = focusedRegion:GetObjectType()
    if regionType ~= "Frame" and regionType ~= "FontString" then
        text = text .. regionType .. "\n"
        if regionType == "CheckButton" then
            text = text .. (focusedRegion:GetChecked() and "Checked" or "Not checked") .. "\n"
        end
        if regionType == "Slider" then
            local min, max = focusedRegion:GetMinMaxValues()
            local current = focusedRegion:GetValue()
            text = text .. string.format("Current: %.2f, Min: %.2f, Max: %.2f\n", current, min, max)
        end
    end
    if focusedRegion.IsEnabled and not focusedRegion:IsEnabled() then
        text = text .. "Disabled\n"
    end
    Vimp_Say(text)
end

-- Moves the cursor to the next readable element
local function Next(backward)
    if not topWindow or topWindow:IsForbidden() or not topWindow:IsVisible() then
        error("Called with an undefined, forbidden, or invisible topWindow")
    end
    if focusedRegion ~= topWindow and (focusedRegion:IsForbidden() or not focusedRegion:IsVisible() or not GetText(focusedRegion, true)) then
        -- Current element isn't eligible so return to the sentinel
        focusedRegion = topWindow
    end
    local regions = Flatten(topWindow, {})
    if #regions == 0 then
        error("Called with an empty topWindow")
    end
    local first, last, increment = 1, #regions, 1
    if backward then
        first, last, increment = last, first, -1
    end
    for index = first, last, increment do
        if focusedRegion == topWindow then
            -- A sentinel valui in focusedRegion means this is the desired element
            focusedRegion = regions[index]
            break
        end
        if regions[index] == focusedRegion then
            -- Set focusedRegion to the sentinel value to signal that the next element is the desired one
            focusedRegion = topWindow
        end
    end
    if focusedRegion == topWindow then
        -- The current element was the last so wrap around
        focusedRegion = regions[first]
    end
    Read()
end

-- A coroutine that performs a click intended to last one frame
local function ClickRoutine(button)
    local targetRegion = focusedRegion
    ExecuteFrameScript(targetRegion, "OnEnter", false)
    ExecuteFrameScript(targetRegion, "OnMouseDown", button)
    targetRegion:Click(button, true)
    -- Yields twice because OnKeyDown is called before OnUpdate in the same frame and we need to wait a frame before releasing the mouse button
    coroutine.yield()
    coroutine.yield()
    if not targetRegion:IsForbidden() and targetRegion:IsVisible() then
        if targetRegion:GetButtonState() == "PUSHED" then
            targetRegion:Click(button, false)
        end
        ExecuteFrameScript(targetRegion, "OnMouseUp", button)
        ExecuteFrameScript(targetRegion, "OnLeave", false)
    end
    clickState = nil
end

-- Clicks on the currently focused element
local function Click()
    if clickState then
        return
    end
    if not focusedRegion or focusedRegion:IsForbidden() or not focusedRegion:IsVisible() then
        error("Called with an undefined, forbidden, or invisible focusedRegion")
    end
    if not focusedRegion:IsObjectType("Button") then
        Vimp_Say("Not clickable!")
        return
    end
    if not focusedRegion:IsEnabled() then
        Vimp_Say("Disabled")
        return
    end
    local text = "Click\n"
    if focusedRegion:IsObjectType("CheckButton") then
        text = (not focusedRegion:GetChecked() and "Checked" or "Unchecked") .. "\n"
    end
    Vimp_Say(text .. GetText(focusedRegion, false))
    clickState = coroutine.create(ClickRoutine)
    coroutine.resume(clickState, "LeftButton")
end

-- Slides the currently focused element
local function Slide(backward, fine)
    if not focusedRegion or focusedRegion:IsForbidden() or not focusedRegion:IsVisible() then
        error("Called with an undefined, forbidden, or invisible focusedRegion")
    end
    if not focusedRegion:IsObjectType("Slider") then
        Vimp_Say("Not slidable!")
        return
    end
    local min, max = focusedRegion:GetMinMaxValues()
    local current = focusedRegion:GetValue()
    local step = focusedRegion:GetValueStep()
    if focusedRegion:GetObeyStepOnDrag() then
        fine = false
    else
        step = (max - min) / (not fine and 10 or 100)
    end
    local new = current + (not backward and step or -step) - (current - min) % step
    new = new < min and min or new > max and max or new
    focusedRegion:SetValue(new)
    Vimp_Say(string.format("%.2f", new))
end

local strataLevels = {WORLD = 1, BACKGROUND = 2, LOW = 3, MEDIUM = 4, HIGH = 5, DIALOG = 6, FULLSCREEN = 7, FULLSCREEN_DIALOG = 8, TOOLTIP = 9}

-- Updates focus
local function Refocus()
    -- Set the defaults for when all the windows are closed
    local highestStrata = 1
    local highestLevel = 0
    if topWindow then
        if not topWindow:IsForbidden() and topWindow:IsShown() then
            -- Save the window state just in case we end up switching to another window
            openWindows[topWindow] = focusedRegion
            highestStrata = strataLevels[topWindow:GetFrameStrata()]
            highestLevel = topWindow:GetFrameLevel()
        else
            -- Forget about this window
            openWindows[topWindow] = nil
            topWindow = nil
            focusedRegion = nil
        end
    end
    -- Save the current focusedRegion to check for and announce changes later
    local savedFocusedRegion = focusedRegion
    -- Look for the visible window with the highest strata and level
    for window, focused in pairs(openWindows) do
        if not window:IsForbidden() and window:IsShown() then
            local currentStrata = strataLevels[window:GetFrameStrata()]
            local currentLevel = window:GetFrameLevel()
            if currentStrata > highestStrata or currentStrata == highestStrata and currentLevel > highestLevel then
                -- Found a new candidate
                topWindow = window
                focusedRegion = focused
                highestStrata = currentStrata
                highestLevel = currentLevel
            end
        else
            openWindows[window] = nil
        end
    end
    if not focusedRegion then
        return
    end
    if not cursor:IsShown() then
        cursor:Show()
    end
    if focusedRegion == topWindow then
        Next(false)
        return
    end
    if focusedRegion ~= savedFocusedRegion then
        Read()
    end
end

-- Cycles through open windows
local function Cycle()
    if not topWindow then
        error("Called with an undefined topWindow")
    end
    -- Save the state of the current window
    openWindows[topWindow] = focusedRegion
    -- Look for the next window
    local first = nil
    for window, focused in pairs(openWindows) do
        if not first then
            first = window
        end
        if not topWindow then
            -- Found the sentinel value so this is the desired window
            topWindow = window
            break
        end
        if window == topWindow then
            -- Found the currently active window so signal that the next one is the desired window using a sentinel value
            topWindow = nil
        end
    end
    if not topWindow then
        -- The currently active window is the last one so wrap around
        topWindow = first
    end
    topWindow:Raise()
    -- Read the first window element which is usually its title
    focusedRegion = topWindow
    Next(false)
    local savedFocusedRegion = openWindows[topWindow]
    if focusedRegion ~= savedFocusedRegion then
        -- Read the window's focused element
        focusedRegion = savedFocusedRegion
        Read()
    end
end

-- Triggered by the appearance of most panes
local function OnPanelShow(region)
    if openWindows[region] or region:IsForbidden() or not region:IsShown() then
        return
    end
    openWindows[region] = region
    region:Raise()
    topWindow = region
    focusedRegion = topWindow
    Refocus()
end

-- Updates the visible cursor every frame
local function OnCursorUpdate(frame)
    Refocus()
    if not focusedRegion then
        frame:Hide()
        clickState = nil
        return
    end
    frame:SetPropagateKeyboardInput(false)
    frame:SetAllPoints(focusedRegion)
    frame:SetFrameLevel(10000)
    if clickState then
        coroutine.resume(clickState)
    end
end

-- Handle keyboard events
local function OnCursorKeyDown(frame, key)
    if key == "TAB" then
        Vimp_Shut()
        if not IsControlKeyDown() then
            Next(IsShiftKeyDown())
        else
            Cycle()
        end
    elseif key == "ENTER" then
        Vimp_Shut()
        Click()
    elseif key == "RIGHT" then
        Vimp_Shut()
        Slide(false, false)
    elseif key == "DOWN" then
        Vimp_Shut()
        Slide(false, true)
    elseif key == "LEFT" then
        Vimp_Shut()
        Slide(true, false)
    elseif key == "UP" then
        Vimp_Shut()
        Slide(true, true)
    elseif key == "SPACE" then
        Vimp_Shut()
        Read()
    else
        frame:SetPropagateKeyboardInput(true)
    end
end

hooksecurefunc("ShowUIPanel", OnPanelShow)

cursor:HookScript("OnUpdate", OnCursorUpdate)
cursor:HookScript("OnKeyDown", OnCursorKeyDown)

for index = 1, STATICPOPUP_NUMDIALOGS do
    _G["StaticPopup" .. index]:HookScript("OnShow", OnPanelShow)
end

for index = 1, NUM_CONTAINER_FRAMES do
    _G["ContainerFrame" .. index]:HookScript("OnShow", OnPanelShow)
end

for index = 1, UIDROPDOWNMENU_MAXLEVELS do
    _G["DropDownList" .. index]:HookScript("OnShow", OnPanelShow)
end
