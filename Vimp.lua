function Vimp_Say(message)
    if type(message) == "table" then
        message = table.concat(message, "\n")
    end
    message = message:gsub("(%P)%s*\n", "%1, ")
    message = message:gsub("(%l)(%u)", "%1 %2")
    local voice = TextToSpeech_GetSelectedVoice("standard").voiceID
    local destination = Enum.VoiceTtsDestination.ScreenReader
    local rate = TEXTTOSPEECH_CONFIG.speechRate
    local volume = TEXTTOSPEECH_CONFIG.speechVolume
    C_VoiceChat.SpeakText(voice, message, destination, rate, volume)
end

function Vimp_Shut()
    C_VoiceChat:StopSpeakingText()
end

function Vimp_Print(...)
    local strings = {...}
    local message = table.concat(strings, ", ")
    DEFAULT_CHAT_FRAME:AddMessage(message)
    Vimp_Say(message)
end

local commands = {}

local function Command(message)
    local command = message:match("^%s*(%S+)")
    local message = message:match("^%s*%S+%s*(.*)$")
    if not command then
        return
    end
    if not commands[command:lower()] then
        Vimp_Print("Invalid command: " .. command)
        return
    end
    commands[command:lower()](message)
end

function Vimp_AddCommand(command, callback)
    commands[command:lower()] = callback
end

RegisterNewSlashCommand(Command, "vimp", "vi")
