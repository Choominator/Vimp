local function Read()
    if not ScriptErrorsFrame:IsShown() then
        Vimp_Say("No errors!")
        return
    end
    local errorFrame = ScriptErrorsFrame:GetEditBox()
    Vimp_Shut()
    Vimp_Say(errorFrame:GetText())
    errorFrame:SetFocus()
    errorFrame:HighlightText()
end

local function OnShow(frame)
    Vimp_Say("Lua error")
end

local function OnEvent(frame, event)
    if event == "LUA_WARNING" then
        UIParent:UnregisterEvent("LUA_WARNING")
    end
end

Vimp_AddCommand("error", Read)
ScriptErrorsFrame:HookScript("OnShow", OnShow)
UIParent:HookScript("onEvent", OnEvent)
