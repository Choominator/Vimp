local commands = {}

-- Parses and dispatches subcommands of the /vimp and /vi commands
local function Command(message)
    local command = message:match("^%s*(%S+)")
    local message = message:match("^%s*%S+%s*(.*)$")
    if not commands[command:lower()] then
        Vimp_Print("Invalid command: " .. command)
        return
    end
    commands[command:lower()](message)
end

-- Speaks text using the settings from Blizzard's chat text-to-speech
function Vimp_Say(message)
    message = message:gsub("(%P)%s*\n", "%1, ")
    message = message:gsub("(%l)(%u)", "%1 %2")
    local voice = TextToSpeech_GetSelectedVoice("standard").voiceID
    local destination = Enum.VoiceTtsDestination.ScreenReader
    local rate = TEXTTOSPEECH_CONFIG.speechRate
    local volume = TEXTTOSPEECH_CONFIG.speechVolume
    C_VoiceChat.SpeakText(voice, message, destination, rate, volume)
end

-- Stops speaking abruptly
function Vimp_Shut()
    C_VoiceChat:StopSpeakingText()
end

-- Reads and prints a message to the default chat window
function Vimp_Print(message)
    DEFAULT_CHAT_FRAME:AddMessage(message)
    Vimp_Read(message)
end

-- Adds a subcommand to the /vimp and /vi commands
function Vimp_AddCommand(command, callback)
    commands[command:lower()] = callback
end

RegisterNewSlashCommand(Command, "vimp", "vi")
