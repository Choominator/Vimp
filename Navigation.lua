Vimp_Marks = {}

local function Direction(cos, sin)
    local direction = ""
    if sin >= 0.5 then
        direction = "North"
    elseif sin <= 0.5 then
        direction = "South"
    end
    if cos >= 0.5 then
        direction = direction .. "East"
    elseif cos <= 0.5 then
        direction = direction .. "West"
    end
    return direction
end

local function Orientation()
    local angle = GetPlayerFacing()
    if not angle then
        return nil
    end
    local cos = -math.sin(angle)
    local sin = math.cos(angle)
    return Direction(cos, sin)
end

local function Navigation()
    local strings = {"You are currently"}
    if IsStealthed() then
        table.insert(strings, "Stealthed")
    end
    if IsFlying() then
        table.insert(strings, "Flying")
    end
    if IsSwimming() then
        table.insert(strings, "Swimming")
    end
    if IsSubmerged() then
        table.insert(strings, "Submerged")
    end
    if IsMounted() then
        table.insert(strings, "Mounted")
    end
    table.insert(strings, IsIndoors() and "Indoors" or "Outdoors")
    local area = GetAreaText()
    table.insert(strings, "In " .. area)
    local zone = GetZoneText()
    if zone ~= "" and zone ~= area then
        table.insert(strings, zone)
    end
    local subZone = GetSubZoneText()
    if subZone ~= "" and subZone ~= zone then
        table.insert(strings, "At " .. subZone)
    end
    local location = table.concat(strings, " ")
    local strings = {location}
    local pvp = GetZonePVPInfo()
    if pvp == "arena" then
        table.insert(strings, "Arena")
    elseif pvp == "friendly" then
        table.insert(strings, "Friendly Territory")
    elseif pvp == "contested" then
        table.insert(strings, "Contested Territory")
    elseif pvp == "hostile" then
        table.insert(strings, "Enemy Territory")
    elseif pvp == "sanctuary" then
        table.insert(strings, "Sanctuary")
    elseif zone == "combat" then
        table.insert(strings, "Combat Territory")
    end
    local orientation = Orientation()
    if orientation then
        table.insert(strings, "Facing " .. orientation)
    end
    local map = C_Map.GetBestMapForUnit("player")
    local position = C_Map.GetPlayerMapPosition(map, "player")
    if position then
        position.x = math.ceil(position.x * 10000) / 100
        position.y = math.ceil(position.y * 10000) / 100
        table.insert(strings, string.format("%.02f, %.02f", position.x, position.y))
    end
    local speed = GetUnitSpeed("player")
    if speed > 0 then
        table.insert(strings, string.format("%d%% speed", math.floor(speed / 7 * 100 + 0.5)))
    end
    Vimp_Shut()
    Vimp_Say(strings)
end

local function GetCommonAscendantMap(map1, map2)
    local ascendants = {}
    while map1 ~= 0 do
        ascendants[map1] = true
        local info = C_Map.GetMapInfo(map1)
        map1 = info.parentMapID
    end
    while not ascendants[map2] do
        local info = C_Map.GetMapInfo(map2)
        map2 = info.parentMapID
    end
    return map2
end

local function MapDistance(fromMap, fromX, fromY, toMap, toX, toY)
    local map = fromMap
    if fromMap ~= toMap then
        map = GetCommonAscendantMap(fromMap, toMap)
        local left, right, top, bottom = C_Map.GetMapRectOnMap(fromMap, map)
        fromX = fromX * (right - left) + left
        fromY = fromY * (bottom - top) + top
        local left, right, top, bottom = C_Map.GetMapRectOnMap(toMap, map)
        toX = toX * (right - left) + left
        toY = toY * (bottom - top) + top
    end
    local width, height = C_Map.GetMapWorldSize(map)
    local distanceX = (toX - fromX) * width
    local distanceY = (toY - fromY) * height
    local distance = math.sqrt(distanceX * distanceX + distanceY * distanceY)
    if distance == 0 then
        return distance, map, 0, 0
    end
    local cos = distanceX / distance
    local sin = -distanceY / distance
    return distance, map, cos, sin
end

local function Mark(mnemonic)
    if not mnemonic or mnemonic == "" then
        Vimp_Print("Usage: mark mnemonic")
        return
    end
    local map = C_Map.GetBestMapForUnit("player")
    local info = C_Map.GetMapInfo(map)
    local position = C_Map.GetPlayerMapPosition(map, "player")
    if not position then
        Vimp_Print(string.format("Cannot mark locations in %s", info.name))
        return
    end
    mnemonic = mnemonic:upper()
    if Vimp_Marks[mnemonic] and Vimp_Marks[mnemonic][map] then
        local mark = Vimp_Marks[mnemonic][map]
        local x = math.ceil(mark.x * 10000) / 100
        local y = math.ceil(mark.y * 10000) / 100
        Vimp_Print(string.format("A mark named %s already exists in %s: %.02f, %.02f", mnemonic, info.name, x, y))
        return
    end
    Vimp_Marks[mnemonic] = Vimp_Marks[mnemonic] or {}
    Vimp_Marks[mnemonic][map] = {x = position.x, y = position.y}
    local x = math.ceil(position.x * 10000) / 100
    local y = math.ceil(position.y * 10000) / 100
    Vimp_Print(string.format("Marked: %s: %s %.02f, %.02f", mnemonic, info.name, x, y))
end

local function Unmark(mnemonic)
    if not mnemonic or mnemonic == "" then
        Vimp_Print("Usage: unmark mnemonic")
        return
    end
    local map = C_Map.GetBestMapForUnit("player")
    local info = C_Map.GetMapInfo(map)
    mnemonic = mnemonic:upper()
    if not Vimp_Marks[mnemonic] or not Vimp_Marks[mnemonic][map] then
        Vimp_Print(string.format("No mark named %s exists in %s", mnemonic, info.name))
        return
    end
    Vimp_Marks[mnemonic][map] = nil
    Vimp_Print(string.format("Unmarked %s from %s", mnemonic, info.name))
end

local function Recall(mnemonic)
    if not mnemonic or mnemonic == "" then
        Vimp_Print("Usage: recall mnemonic")
        return
    end
    mnemonic = mnemonic:upper()
    if not Vimp_Marks[mnemonic] then
        Vimp_Print(string.format("No marks named %s found", mnemonic))
        return
    end
    local playerMap = C_Map.GetBestMapForUnit("player")
    local position = C_Map.GetPlayerMapPosition(playerMap, "player")
    if not position then
        local info = C_Map.GetMapInfo(playerMap)
        Vimp_Print("Cannot recall positions from %s", info.name)
        return
    end
    local mark = Vimp_Marks[mnemonic][playerMap]
    if not mark then
        local strings = {}
        local chosenMap, chosenCoords, chosenDistance, chosenCos, chosenSin = nil, nil, math.huge, nil, nil
        for map, coords in pairs(Vimp_Marks[mnemonic]) do
            local distance, ascendant, cos, sin = MapDistance(playerMap, position.x, position.y, map, coords.x, coords.y)
            local info = C_Map.GetMapInfo(ascendant)
            if info.mapType >= Enum.UIMapType.Continent and distance < chosenDistance then
                chosenMap = map
                chosenCoords = coords
                chosenDistance = distance
                chosenCos = cos
                chosenSin = sin
            end
        end
        if chosenMap ~= nil then
            local zone = {}
            while chosenMap ~= 0 do
                local info = C_Map.GetMapInfo(chosenMap)
                if info.mapType < Enum.UIMapType.Continent then
                    break
                end
                table.insert(zone, info.name)
                chosenMap = info.parentMapID
            end
            local zone = table.concat(zone, ", ")
            local x = math.ceil(chosenCoords.x * 10000) / 100
            local y = math.ceil(chosenCoords.y * 10000) / 100
            local direction = Direction(chosenCos, chosenSin)
            table.insert(strings, string.format("Found mark %d yards to the %s in %s: %.02f, %.02f", math.floor(chosenDistance), direction, zone, x, y))
        else
            local info = C_Map.GetMapInfo(playerMap)
            table.insert(strings, string.format("No marks named %s found in %s", mnemonic, info.name))
            for map, coords in pairs(Vimp_Marks[mnemonic]) do
                local zone = {}
                while map ~= 0 do
                    local info = C_Map.GetMapInfo(map)
                    if info.mapType < Enum.UIMapType.World then
                        break
                    end
                    table.insert(zone, info.name)
                    map = info.parentMapID
                end
                local zone = table.concat(zone, ", ")
                local x = math.ceil(coords.x * 10000) / 100
                local y = math.ceil(coords.y * 10000) / 100
                table.insert(strings, string.format("Found mark in %s: %.02f, %.02f", zone, x, y))
            end
        end
        Vimp_Print(table.concat(strings, "\n"))
        return
    end
    local info = C_Map.GetMapInfo(playerMap)
    local distance, ascendant, cos, sin = MapDistance(playerMap, position.x, position.y, playerMap, mark.x, mark.y)
    local x = math.ceil(mark.x * 10000) / 100
    local y = math.ceil(mark.y * 10000) / 100
    if math.floor(distance) < 5 then
        Vimp_Print(string.format("Recalling mark right here in %s: %.02f, %.02f", info.name, x, y))
        return
    end
    local direction = Direction(cos, sin)
    Vimp_Print(string.format("Recalling mark %d yards to the %s in %s: %.02f, %.02f", math.floor(distance), direction, info.name, x, y))
end

Vimp_AddCommand("nav", Navigation)
Vimp_AddCommand("mark", Mark)
Vimp_AddCommand("unmark", Unmark)
Vimp_AddCommand("recall", Recall)
