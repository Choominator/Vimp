local enabled = false
local tooltip = nil

local function Toggle()
    enabled = not enabled
    if enabled then
        Vimp_Print("Mouse tracking enabled!")
    else
        Vimp_Print("Mouse tracking disabled!")
    end
end

local function Tooltip(region)
    local owner = GameTooltip:GetOwner()
    if not GameTooltip:IsShown() or owner ~= region and owner ~= UIParent then
        return nil
    end
    local strings = {}
    Vimp_Strings(strings, GameTooltip:GetRegions())
    Vimp_Strings(strings, GameTooltip:GetChildren())
    local tooltip = table.concat(strings, "\n")
    return tooltip
end

local lastTooltip = nil

local function OnWorldUpdate()
    if not enabled then
        return
    end
    local region = GetMouseFocus()
    if not region then
        return
    end
    local tooltip = Tooltip(region)
    if tooltip == lastTooltip then
        return
    end
    lastTooltip = tooltip
    if not tooltip then
        return
    end
    Vimp_Shut()
    Vimp_Say(tooltip)
end

WorldFrame:HookScript("OnUpdate", OnWorldUpdate)
Vimp_AddCommand("mouse", Toggle)
