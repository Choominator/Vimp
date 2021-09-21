Vimp_Reader = {}

Vimp_Reader.Windows = {}

Vimp_Reader.Cursor = CreateFrame("Frame", nil, UIParent)
local top = Vimp_Reader.Cursor:CreateLine()
top:SetColorTexture(1, 1, 1, 1)
top:SetStartPoint("TOPLEFT")
top:SetEndPoint("TOPRIGHT")
top:SetThickness(2)
local bottom = Vimp_Reader.Cursor:CreateLine()
bottom:SetColorTexture(1, 1, 1, 1)
bottom:SetStartPoint("BOTTOMLEFT")
bottom:SetEndPoint("BOTTOMRIGHT")
bottom:SetThickness(2)
local left = Vimp_Reader.Cursor:CreateLine()
left:SetColorTexture(1, 1, 1, 1)
left:SetStartPoint("TOPLEFT")
left:SetEndPoint("BOTTOMLEFT")
left:SetThickness(2)
local right = Vimp_Reader.Cursor:CreateLine()
right:SetColorTexture(1, 1, 1, 1)
right:SetStartPoint("TOPRIGHT")
right:SetEndPoint("BOTTOMRIGHT")
right:SetThickness(2)
Vimp_Reader.Cursor:EnableKeyboard(true)
Vimp_Reader.Cursor:SetFrameStrata("TOOLTIP")
Vimp_Reader.Cursor:SetFrameLevel(10000)
Vimp_Reader.Cursor:HasFixedFrameStrata(true)
Vimp_Reader.Cursor:HasFixedFrameLevel(true)
Vimp_Reader.Cursor:Hide()

function Vimp_Reader:GetFocus()
    local window = self.ActiveWindow
    if not window then
        return nil
    end
    return window[#window]
end

function  Vimp_Reader:SetFocus(focus)
    if not focus then
        error("Cannot set focus to a nil value", 2)
    end
    local window = self.ActiveWindow
    if not window or not window[2] then
        error("Cannot set focus without a window", 2)
    end
    window[#window] = focus
end

function Vimp_Reader:GetParent()
    local window = self.ActiveWindow
    if not window then
        return nil
    end
    return window[#window - 1]
end

function Vimp_Reader:GetRoot()
    local window = self.ActiveWindow
    if not window then
        return nil
    end
    return self.ActiveWindow[1]
end

function Vimp_Reader:Push(region)
    if not region then
        error("Cannot push a nil region", 2)
    end
    local window = self.ActiveWindow
    if not window then
        error("Cannot push onto a non-existent window", 2)
    end
    table.insert(window, region)
end

function Vimp_Reader:Pop()
    local window = self.ActiveWindow
    if not window then
        return
    end
    if not window[3] then
        error("Cannot pop the last element of a window or the window itself", 2)
    end
    table.remove(window)
end

function Vimp_Reader:Refresh()
    local savedWindow = self.ActiveWindow
    local savedFocus = savedWindow[#savedWindow]
    local index = 1
    local window = self.Windows[1]
    while window do
        local root = window[1]
        if root:IsForbidden() or not root:IsShown() then
            table.remove(self.Windows, index)
            if window == self.ActiveWindow then
                self.ActiveWindow = self.Windows[index]
            end
        else
            index = index + 1
        end
        window = self.Windows[index]
    end
    if not self.ActiveWindow then
        self.ActiveWindow = self.Windows[1]
    end
    if not self.ActiveWindow then
        return
    end
    local window = self.ActiveWindow
    local root = window[1]
    local visible = nil
    local region = window[#window]
    while region and region ~= root do
        if region:IsForbidden() or not region:IsShown() then
            visible = nil
        elseif not visible then
            visible = region
        end
        region = region:GetParent()
    end
    if visible == savedFocus then
        return
    end
    local region = window[#window]
    while region and region ~= visible and region ~= root do
        while region == window[#window] do
            table.remove(window)
        end
        region = region:GetParent()
    end
    local focus = window[#window]
    if focus and focus ~= savedFocus then
        if window ~= savedWindow then
            local driver = Vimp_Driver:ProbeRegion(root)
            driver.Describe()
        end
        local driver = Vimp_Driver:ProbeRegion(focus)
        if #window > 1 then
            driver.Describe()
        else
            table.insert(window, root)
            driver.Next(false)
        end
    end
end

function Vimp_Reader:HandleWindow(root)
    for index, window in pairs(self.Windows) do
        if window[1] == root then
            return
        end
    end
    local window = {root, root}
    table.insert(self.Windows, window)
    self.ActiveWindow = window
    local driver = Vimp_Driver:ProbeRegion(root)
    driver.Describe()
    driver.Next(false)
    self.Cursor:Show()
end

function Vimp_Reader:SwitchWindow()
    self:Refresh()
    local window = self.ActiveWindow
    if not window then
        return
    end
    Vimp_Shut()
    local highestStrata = window[1]:GetFrameStrata()
    local candidates = {}
    for index, window in ipairs(self.Windows) do
        local root = window[1]
        local strata = root:GetFrameStrata()
        if strata > highestStrata then
            candidates = {}
            highestStrata = strata
        end
        if strata == highestStrata then
            table.insert(candidates, window)
        end
    end
    for index, candidate in ipairs(candidates) do
        if not window then
            window = candidate
            break
        end
        if candidate == window then
            window = nil
        end
    end
    if not window then
        window = candidates[1]
    end
    self.ActiveWindow = window
    self:Refresh()
    local window = self.ActiveWindow
    local root = window[1]
    local driver = Vimp_Driver:ProbeRegion(root)
    driver.Describe()
    local focus = window[#window]
    local driver = Vimp_Driver:ProbeRegion(focus)
    driver.Describe()
end

function Vimp_Reader:Next(backward)
    self:Refresh()
    Vimp_Shut()
    local window = self.ActiveWindow
    local parent = window[#window - 1]
    local driver = Vimp_Driver:ProbeRegion(parent)
    driver.Next(backward)
end

function Vimp_Reader:Describe()
    self:Refresh()
    Vimp_Shut()
    local window = self.ActiveWindow
    local focus = window[#window]
    local driver = Vimp_Driver:ProbeRegion(focus)
    driver.Describe()
    if focus:IsObjectType("Frame") then
        Vimp_ReadTooltip(focus)
    end
end

function Vimp_Reader:Activate()
    self:Refresh()
    Vimp_Shut()
    local window = self.ActiveWindow
    local focus = window[#window]
    local driver = Vimp_Driver:ProbeRegion(focus)
    driver.Activate()
end

function Vimp_Reader:Dismiss()
    self:Refresh()
    Vimp_Shut()
    local window = self.ActiveWindow
    local parent = window[#window - 1]
    local driver = Vimp_Driver:ProbeRegion(parent)
    driver.Dismiss()
end

local function OnUpdate(frame)
    Vimp_Reader:Refresh()
    local focus = Vimp_Reader:GetFocus()
    if not focus then
        frame:Hide()
        return
    end
    frame:SetPropagateKeyboardInput(false)
    frame:SetAllPoints(focus)
end

local function OnKeyDown(frame, key)
    frame:SetPropagateKeyboardInput(false)
    if key == "DOWN" then
        if not IsShiftKeyDown() then
            Vimp_Reader:Activate()
        else
            Vimp_Reader:Describe()
        end
    elseif key == "UP" then
        if not IsShiftKeyDown() then
            Vimp_Reader:Dismiss()
        else
            Vimp_Reader:SwitchWindow()
        end
    elseif key == "LEFT" then
        Vimp_Reader:Next(true)
    elseif key == "RIGHT" then
        Vimp_Reader:Next(false)
    else
        frame:SetPropagateKeyboardInput(true)
    end
end

Vimp_Reader.Cursor:SetScript("OnUpdate", OnUpdate)
Vimp_Reader.Cursor:SetScript("OnKeyDown", OnKeyDown)
