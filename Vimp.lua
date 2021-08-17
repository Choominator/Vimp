local commands = {}

local function Command(message)
    local command = message:match("^%s*(%S+)")
    local message = message:match("^%s*%S+%s*(.*)$")
    if not commands[command:lower()] then
        Vimp_Print("Invalid command: " .. command)
        return
    end
    commands[command:lower()](message)
end

local function OnEvent(frame, event)
    if InCombatLockdown() then
        return
    end
    if event ~= "UPDATE_BINDINGS" then
        return
    end
    if GetBindingAction("'") == "" and not GetBindingKey("VIMPREPEAT") then
        SetBinding("'", "VIMPREPEAT")
    end
    if GetBindingAction("[") == "" and not GetBindingKey("VIMPPREV") then
        SetBinding("[", "VIMPPREV")
    end
    if GetBindingAction("]") == "" and not GetBindingKey("VIMPNEXT") then
        SetBinding("]", "VIMPNEXT")
    end
    if GetBindingAction("SHIFT-'") == "" and not GetBindingKey("VIMPCLICK") then
        SetBinding("SHIFT-'", "VIMPCLICK")
    end
    if GetBindingAction("SHIFT-[") == "" and not GetBindingKey("VIMPDEC") then
        SetBinding("SHIFT-[", "VIMPDEC")
    end
    if GetBindingAction("SHIFT-]") == "" and not GetBindingKey("VIMPINC") then
        SetBinding("SHIFT-]", "VIMPINC")
    end
end

function Vimp_Read(message)
    message = message:gsub("(%P)%s*\n", "%1, ")
    message = message:gsub("%u", " %1")
    local voice = TextToSpeech_GetSelectedVoice("standard").voiceID
    local destination = Enum.VoiceTtsDestination.ScreenReader
    local rate = TEXTTOSPEECH_CONFIG.speechRate
    local volume = TEXTTOSPEECH_CONFIG.speechVolume
    C_VoiceChat.SpeakText(voice, message, destination, rate, volume)
end

function Vimp_Stop()
    C_VoiceChat:StopSpeakingText()
end

function Vimp_Print(message)
    DEFAULT_CHAT_FRAME:AddMessage(message)
    Vimp_Read(message)
end

function Vimp_Repeat()
    Vimp_Stop()
    Vimp_Read("Repeat")
end

function Vimp_Prev()
    Vimp_Stop()
    Vimp_Read("Previous")
end

function Vimp_Next()
    Vimp_Stop()
    Vimp_Read("Next")
end

function Vimp_Click()
    Vimp_Stop()
    Vimp_Read("Click")
end

function Vimp_Dec()
    Vimp_Stop()
    Vimp_Read("Decrement")
end

function Vimp_Inc()
    Vimp_Stop()
    Vimp_Read("Increment")
end

function Vimp_AddCommand(command, callback)
    commands[command:lower()] = callback
end

RegisterNewSlashCommand(Command, "vimp", "vi")

BINDING_HEADER_VIMP = "Vimp"
BINDING_NAME_VIMPREPEAT = "Read current element"
BINDING_NAME_VIMPPREV = "Read previous element"
BINDING_NAME_VIMPNEXT = "Read next element"
BINDING_NAME_VIMPCLICK = "Click on element"
BINDING_NAME_VIMPDEC = "Decrement element"
BINDING_NAME_VIMPINC = "Increment element"

WorldFrame:RegisterEvent("UPDATE_BINDINGS")
WorldFrame:HookScript("OnEvent", OnEvent)