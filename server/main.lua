local peopleInsideLocation = {}

function GetIdentifier(source)
    return exports.qbx_core:GetPlayer(source).PlayerData.citizenid
end

function RemoveFurniture(source, object)
    local identifier = GetIdentifier(source)
    if not identifier then return end
    local amount = DB.GetFurnitureObjectAmount(identifier, object)

    DB.DeleteFurnitureObject(identifier, object, amount)
end

RegisterNetEvent('ice-furniture:server:removeFurniture', function(object)
    local src = source
    RemoveFurniture(src, object)
end)

lib.callback.register('ice-furniture:server:getOwnedFurniture', function()
    local src = source
    local identifier = GetIdentifier(src)
    if not identifier then return end

    return DB.GetOwnedFurniture(identifier)
end)

RegisterServerEvent('ice-furniture:server:editExistingFurniture', function(newData, location, id)
    DB.UpdateFurnitureObject(newData.pos, newData.rotation, id)

    if not peopleInsideLocation[location] or not next(peopleInsideLocation) then
        return
    end

    for v, _ in pairs(peopleInsideLocation[location]) do
        TriggerClientEvent("ice-furniture:client:spawnFurniture", v, {
            {
                id = id,
                location = location,
                pos = json.encode(newData.pos),
                rotation = json.encode(newData.rotation),
                model = newData.model
            }
        }, false, true)
    end
end)

RegisterServerEvent('ice-furniture:server:removeExistingFurniture', function(id, location, object)
    local src = source
    local identifier = GetIdentifier(src)

    MySQL.update.await('DELETE FROM furniture_objects WHERE id = ?', { id })
    DB.AddFurniture(identifier, object, 1)

    if location and peopleInsideLocation[location] then
        for v, _ in pairs(peopleInsideLocation[location]) do
            TriggerClientEvent("ice-furniture:client:despawnFurniture", v, id)
        end
    end
end)

RegisterServerEvent('ice-furniture:server:despawnFurniture', function(location)
    local src = source

    if location and peopleInsideLocation[location] then
        peopleInsideLocation[location][src] = nil
    end

    TriggerClientEvent("ice-furniture:client:despawnFurniture", src)
end)

RegisterNetEvent("ice-furniture:server:spawnNewFurniture", function(data, location, uniqueId)
    local insertId = DB.AddNewFurnitureObject(location, data.pos, data.rotation, data.model, uniqueId)

    if not peopleInsideLocation[location] or not next(peopleInsideLocation) then
        return
    end

    for v, _ in pairs(peopleInsideLocation[location]) do
        TriggerClientEvent("ice-furniture:client:spawnFurniture", v, {
            {
                id = insertId,
                location = location,
                pos = json.encode(data.pos),
                rotation = json.encode(data.rotation),
                model = data.model
            }
        }, true, false)
    end
end)

RegisterServerEvent('ice-furniture:server:spawnFurniture', function(location)
    local src = source
    if not src then return end

    if not peopleInsideLocation[location] then
        peopleInsideLocation[location] = {}
    end

    peopleInsideLocation[location][src] = true

    local furniture = DB.GetLocationFurniture(location)
    TriggerClientEvent("ice-furniture:client:spawnFurniture", src, furniture, false, false)
end)


lib.callback.register('ice-furniture:server:buyFurniture', function(source, object)
    return DB.AddFurniture(GetIdentifier(source), object, 1)
end)
