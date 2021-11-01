Vimp_Window = {}

Vimp_Window.Registry = {}

function Vimp_Window:CreateDriver(frame, probe, describe)
    if not frame:IsObjectType("Frame") then
        error("Window driver's frame member must be a Frame", 2)
    end
    if type(probe) ~= "function" then
        error("Window driver's probe member must be a function", 2)
    end
    if type(describe) ~= "function" then
        error("Window driver's describe member must be a function", 2)
    end
    local driver = {}
    driver.Probe = probe
    driver.Describe = describe
    self.Registry[frame] = driver
end

function Vimp_Window:Probe(frame)
    return self.Registry[frame] ~= nil
end

local function Probe(region)
    return Vimp_Window.Registry[region] ~= nil
end

local function Describe(region, strings)
    if not region then
        region = Vimp_Reader:GetRoot()
    end
    return Vimp_Window.Registry[region].Describe(region, strings)
end

local function Next(backward)
    local focus = Vimp_Reader:GetFocus()
    local root = Vimp_Reader:GetRoot()
    if focus == root then
        focus = nil
    end
    local children = {}
    Vimp_Children(children, root:GetRegions())
    Vimp_Children(children, root:GetChildren())
    if #children == 0 then
        Vimp_Say("Nothing to read!")
        Vimp_Reader:SetFocus(root)
        return
    end
    local first, last, increment = 1, #children, 1
    if backward then
        first, last, increment = last, first, -1
    end
    for index = first, last, increment do
        local child = children[index]
        if not focus then
            focus = child
            break
        end
        if child == focus then
            focus = nil
        end
    end
    if not focus then
        focus = children[first]
    end
    Vimp_Reader:SetFocus(focus)
    local driver = Vimp_Driver:ProbeRegion(focus)
    driver.Describe()
end

local function Activate()
    local focus = Vimp_Reader:GetFocus()
    local strings = {"Enter"}
    Describe(focus, strings)
    Vimp_Say(strings)
    Vimp_Reader:Push(focus)
    Next(false)
end

local function Dismiss()
    Vimp_Say("Cannot exit a window!")
end

Vimp_Driver:Create(Probe, Describe, Next, Activate, Dismiss, Vimp_Dummy)
