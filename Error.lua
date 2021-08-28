-- Locates the specified frame type in the specified frame's hierarchy
local function Search(frame, type)
    if frame:IsObjectType(type) then
        return frame
    end
    for index, frame in ipairs({frame:GetChildren()}) do
        local result = Search(frame, type)
        if result then
            return result
        end
    end
    return nil
end

-- Reads the text from the Lua errors frame
local function Read()
    local errorFrame = Search(ScriptErrorsFrame, "EditBox")
    if not errorFrame then
        return
    end
    Vimp_Shut()
    Vimp_Say(errorFrame:GetDisplayText())
end

-- Warns when Lua errors are displayed
local function OnShow(frame)
    Vimp_Say("Lua errors")
end

Vimp_AddCommand("error", Read)
ScriptErrorsFrame:HookScript("OnShow", OnShow)
