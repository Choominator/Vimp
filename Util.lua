function Vimp_Validate(region, ...)
    if not region then
        return children
    end
    if region:IsForbidden() or not region:IsShown() then
        return Vimp_Validate(...)
    end
    if Vimp_Driver:ProbeRegion(region) then
        return true
    end
    if region:IsObjectType("Frame") and (Vimp_Validate(region:GetRegions()) or Vimp_Validate(region:GetChildren())) then
        return true
    end
    return Vimp_Validate(...)
end

function Vimp_Strings(strings, region, ...)
    if not region then
        return strings
    end
    if region:IsForbidden() or not region:IsShown() then
        return Vimp_Strings(strings, ...)
    end
    local driver = Vimp_Driver:ProbeRegion(region)
    if driver then
        driver.Describe(region, strings)
    elseif region:IsObjectType("Frame") then
        Vimp_Strings(strings, region:GetRegions())
        Vimp_Strings(strings, region:GetChildren())
    end
    return Vimp_Strings(strings, ...)
end

function Vimp_Children(children, region, ...)
    if not region then
        return children
    end
    if region:IsForbidden() or not region:IsShown() then
        return Vimp_Children(children, ...)
    end
    if Vimp_Driver:ProbeRegion(region) then
        table.insert(children, region)
    elseif region:IsObjectType("Frame") then
        Vimp_Children(children, region:GetRegions())
        Vimp_Children(children, region:GetChildren())
    end
    return Vimp_Children(children, ...)
end

function Vimp_ReadTooltip(frame)
    local tooltipOwner = GameTooltip:GetOwner()
    if frame ~= tooltipOwner then
        if tooltipOwner then
            ExecuteFrameScript(tooltipOwner, "OnLeave", false)
        end
        ExecuteFrameScript(frame, "OnEnter", false)
    end
    local strings = {"Tooltip"}
    if GameTooltip:GetOwner() == frame then
        Vimp_Strings(strings, GameTooltip)
    end
    if frame ~= tooltipOwner then
        ExecuteFrameScript(frame, "OnLeave", false)
        if tooltipOwner then
            ExecuteFrameScript(tooltipOwner, "OnEnter", false)
        end
    end
    if #strings == 1 then
        return
    end
    Vimp_Say(strings)
end

function Vimp_Levenshtein(left, right)
    local matrix = {}
    local cols = left:len()
    local rows = right:len()
    if cols == 0 then
        return rows
    end
    if rows == 0 then
        return cols
    end
    for index = 0, cols do
        matrix[index] = index
    end
    for index = 1, rows do
        matrix[index * (cols + 1)] = index
    end
    for row = 1, rows do
        if right:byte(row) and right:byte(row) >= 0x80 then
            return nil
        end
        for col = 1, cols do
            if left:byte(col) and left:byte(col) >= 0x80 then
                return nil
            end
            matrix[row * (cols + 1) + col] = min(min(matrix[row * (cols + 1) + col - 1] + 1, matrix[(row - 1) * (cols + 1) + col] + 1), matrix[(row - 1) * (cols + 1) + col - 1] + (left:byte(col) ~= right:byte(row) and 1 or 0))
        end
    end
    return matrix[(rows + 1) * (cols + 1) - 1]
end

function Vimp_Dummy()
    error("This function must never be called", 2)
end
