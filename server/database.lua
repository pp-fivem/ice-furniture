DB = {}

---@param pos vector3
---@param rotation number
---@param id string | number
---@return number
function DB.UpdateFurnitureObject(pos, rotation, id)
    return MySQL.update.await("UPDATE furniture_objects SET pos = ?, rotation = ? WHERE id = ?",
        { json.encode(pos), json.encode(rotation), id })
end

---@param citizenid string
---@param object string
---@return number
function DB.GetFurnitureObjectAmount(citizenid, object)
    return MySQL.scalar.await("SELECT `amount` FROM `player_furnitures` WHERE `identifier` = ? AND `object` = ?",
        { citizenid, object }) or 0
end

---@param citizenid string
---@param object number | string
---@param amount number
---@return number
function DB.DeleteFurnitureObject(citizenid, object, amount)
    if amount == 1 then
        return MySQL.update.await("DELETE FROM `player_furnitures` WHERE `object` = ? AND `identifier` = ?",
            { object, citizenid })
    end

    return MySQL.update.await("UPDATE `player_furnitures` SET `amount` = ? WHERE `object` = ? AND `identifier` = ?",
        { amount - 1, object, citizenid })
end

---@param citizenid string
---@return QueryResult|{ [number]: { [string]: unknown  }}
function DB.GetOwnedFurniture(citizenid)
    return MySQL.query.await("SELECT * FROM `player_furnitures` WHERE identifier = ?", { citizenid })
end

---@param location string
---@return QueryResult|{ [number]: { [string]: unknown  }}
function DB.GetLocationFurniture(location)
    return MySQL.query.await("SELECT * FROM furniture_objects WHERE location = ?", { location })
end

---@param location string
---@param pos vector3
---@param rotation number
---@param model number | string
---@return number
function DB.AddNewFurnitureObject(location, pos, rotation, model, uniqueId)
    return MySQL.insert.await(
        "INSERT INTO furniture_objects (location, pos, rotation, model, uniqueId) VALUES (?, ?, ?, ?, ?)",
        { location, json.encode(pos), json.encode(rotation), model, uniqueId })
end

---@param citizenid string
---@param object string
---@param amount number
---@return number
function DB.AddFurniture(citizenid, object, amount)
    if not amount then amount = 1 end
    local amount2 = DB.GetFurnitureObjectAmount(citizenid, object)


    if not amount2 then
        return MySQL.insert.await("INSERT INTO `player_furnitures` (identifier, object, amount) VALUES (?, ?, ?)",
            { citizenid, object, amount })
    end


    return MySQL.update.await("UPDATE `player_furnitures` SET `amount` = ? WHERE `object` = ? AND `identifier` = ?",
        { amount2 + amount, object, citizenid })
end
