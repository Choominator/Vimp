local function Describe()
    local name = UnitName("target")
    if not name then
        return
    end
    local strings= {}
    table.insert(strings, name)
    local guild = GetGuildInfo("target")
    if guild then
        table.insert(strings, guild)
    end
    local format = {}
    local args = {}
    if UnitIsFriend("player", "target") then
        table.insert(format, "Friendly")
    end
    if UnitIsEnemy("player", "target") then
        table.insert(format, "Enemy")
    end
    if UnitIsPlayer("target") then
        table.insert(format, "Player")
    end
    local classification = UnitClassification("target")
    if classification == "worldboss" then
        table.insert(format, "Boss")
    elseif classification == "rareelite" then
        table.insert(format, "Rare Elite")
    elseif classification == "elite" then
        table.insert(format, "Elite")
    elseif classification == "rare" then
        table.insert(format, "Rare")
    end
    local level = UnitLevel("target")
    if level then
        table.insert(format, "Level %d")
        table.insert(args, level)
    end
    local gender = UnitSex("target")
    if gender and gender == 2 or gender == 3 then
        table.insert(format, gender == 2 and "Male" or "Female")
    end
    local race = UnitRace("target")
    if race then
        table.insert(format, race)
    end
    local class = UnitClass("target")
    if class and class ~= name then
        table.insert(format, class)
    end
    local format = table.concat(format, " ")
    local description = string.format(format, unpack(args))
    table.insert(strings, description)
    local family = UnitCreatureFamily("target")
    if family then
        table.insert(strings, family)
    end
    if UnitIsAFK("target") then
        table.insert(strings, "Away")
    end
    if UnitIsDND("target") then
        table.insert(strings, "Busy")
    end
    local health = UnitHealth("target")
    local maxHealth = UnitHealthMax("target")
    if health and maxHealth and maxHealth > 0 then
        table.insert(strings, string.format("%d%% Health", math.floor(health / maxHealth * 100 + 0.5)))
    end
    local power = UnitPower("target")
    local maxPower = UnitPowerMax("target")
    local _, powerType = UnitPowerType("target")
    if power and maxPower and maxPower > 0 and powerType then
        table.insert(strings, string.format("%d%% %s", math.floor(power / maxPower * 100 + 0.5), powerType))
    end
    if UnitIsCorpse("target") then
        table.insert(strings, "Corpse")
    end
    local distanceSquared = UnitDistanceSquared("target")
    if distanceSquared and distanceSquared > 0 then
        local distance = math.sqrt(distanceSquared)
        table.insert(strings, string.format("%d yards"), distance)
    end
    Vimp_Shut()
    Vimp_Say(strings)
end

local function Command(message)
    Describe()
end

local function OnEvent(frame, event)
    if event ~= "PLAYER_TARGET_CHANGED" then
        return
    end
    Describe()
end

Vimp_AddCommand("target", Command)

TargetFrame:HookScript("OnEvent", OnEvent)
