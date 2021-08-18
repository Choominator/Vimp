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

function Vimp_AddCommand(command, callback)
    commands[command:lower()] = callback
end

RegisterNewSlashCommand(Command, "vimp", "vi")
