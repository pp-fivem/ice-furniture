local spawnedFurniture = {}
local updateText = false
local editmode = false
local showText = false

local function generateUniqueId()
    if lib.string and lib.string.random then
        return lib.string.random("Aa.1^", 15)
    end

    local random = {}
    local characters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"

    for _ = 1, 15 do
        local randomIndex = math.random(1, #characters)
        table.insert(random, string.sub(characters, randomIndex, randomIndex))
    end

    return table.concat(random)
end

function Furnish(furnitureData, entity)
    local playerPos = GetEntityCoords(cache.ped) - vec3(0.0, 0.0, 1.0)
    local alreadySpawned = entity ~= nil
    local minZ = playerPos.z

    entity = entity or (function()
        lib.requestModel(joaat(furnitureData.object), 200)
        return CreateObject(joaat(furnitureData.object), playerPos.x, playerPos.y, playerPos.z, true, false, false)
    end)()

    SetEntityCollision(entity, false, false)
    SetEntityAlpha(entity, 200, true)

    local moveAmount = 0.0025
    local rotateAmount = 0.2
    local multiplier = 1.0
    local rotationOrder = 3
    local returnData = nil
    while returnData == nil do
        local entityRotation = GetEntityRotation(entity)

        local text = {
            locale("furni_multiplier", multiplier),
            locale("furni_reset"),
            locale("furni_move"),
            locale("furni_rotate", math.floor(entityRotation.x), math.floor(entityRotation.y),
                math.floor(entityRotation.z)),
            locale("furni_changerotate"),
            locale("furni_height"),
            locale("furni_bring"),
            locale("furni_confirm"),
            locale("furni_cancel"),
        }

        if updateText then
            if lib.isTextUIOpen() then
                lib.hideTextUI()
            end

            lib.showTextUI(table.concat(text))
            updateText = false
        end

        if not showText then
            lib.showTextUI(table.concat(text))
            showText = true
        end

        DisableControlAction(0, 24, true)
        DisableControlAction(0, 25, true)
        DisableControlAction(0, 47, true)

        if IsControlJustReleased(0, 201) then -- ENTER
            returnData = {
                pos = GetEntityCoords(entity),
                rotation = GetEntityRotation(entity),
                model = furnitureData.object
            }

            if not alreadySpawned then
                DeleteObject(entity)
            else
                SetEntityNoCollisionEntity(cache.ped, entity, true)
                SetEntityAlpha(entity, 255, true)
            end
        end

        if IsControlJustReleased(0, 202) then -- BACKSPACE / ESC
            if not alreadySpawned then
                DeleteObject(entity)
            else
                SetEntityNoCollisionEntity(cache.ped, entity, true)
                SetEntityAlpha(entity, 255, true)
            end
            returnData = false
        end

        if IsDisabledControlJustReleased(0, 47) then -- G
            updateText = true
            local coords = GetEntityCoords(cache.ped)
            SetEntityCoords(entity, coords.x, coords.y, coords.z, false, false, false, false)
        end

        if IsControlJustReleased(0, 74) then -- H
            updateText = true
            ---@diagnostic disable-next-line: missing-parameter
            SetEntityRotation(entity, 0.0, 0.0, 0.0)
        end

        if IsControlJustReleased(0, 211) then -- TAB
            updateText = true
            rotationOrder = rotationOrder + 1
            if rotationOrder > 3 then rotationOrder = 1 end
        end

        if IsControlPressed(0, 44) then -- Q
            updateText = true
            if multiplier >= Config.SpeedMultiplier.min then
                multiplier = multiplier - 0.1
                Wait(50)
            end
        end
        if IsControlPressed(0, 38) then -- E
            updateText = true
            if multiplier < Config.SpeedMultiplier.max then
                multiplier = multiplier + 0.1
                Wait(50)
            end
        end

        local move = moveAmount * multiplier
        local rot = rotateAmount * multiplier

        if IsControlPressed(0, 172) then -- UP
            local coords = GetOffsetFromEntityInWorldCoords(entity, 0.0, -move, 0.0)
            SetEntityCoords(entity, coords.x, coords.y, coords.z, false, false, false, false)
        end
        if IsControlPressed(0, 173) then -- DOWN
            local coords = GetOffsetFromEntityInWorldCoords(entity, 0.0, move, 0.0)
            SetEntityCoords(entity, coords.x, coords.y, coords.z, false, false, false, false)
        end
        if IsControlPressed(0, 174) then -- LEFT
            local coords = GetOffsetFromEntityInWorldCoords(entity, -move, 0.0, 0.0)
            SetEntityCoords(entity, coords.x, coords.y, coords.z, false, false, false, false)
        end
        if IsControlPressed(0, 175) then -- RIGHT
            local coords = GetOffsetFromEntityInWorldCoords(entity, move, 0.0, 0.0)
            SetEntityCoords(entity, coords.x, coords.y, coords.z, false, false, false, false)
        end

        if IsControlPressed(0, 15) then -- SCROLL UP
            local coords = GetOffsetFromEntityInWorldCoords(entity, 0.0, 0.0, move)
            SetEntityCoords(entity, coords.x, coords.y, coords.z, false, false, false, false)
        end

        if IsControlPressed(0, 14) then -- SCROLL DOWN
            local coords = GetOffsetFromEntityInWorldCoords(entity, 0.0, 0.0, -move)
            if coords.z >= minZ then
                SetEntityCoords(entity, coords.x, coords.y, coords.z, false, false, false, false)
            end
        end

        if IsDisabledControlPressed(0, 24) then -- LMB
            updateText = true
            local curRotation = GetEntityRotation(entity)
            local rotation = { 0.0, 0.0, 0.0 }
            rotation[rotationOrder] = rot
            ---@diagnostic disable-next-line: missing-parameter, param-type-mismatch
            SetEntityRotation(entity, curRotation + vec3(rotation[1], rotation[2], rotation[3]))
        end
        if IsDisabledControlPressed(0, 25) then -- RMB
            updateText = true
            local curRotation = GetEntityRotation(entity)
            local rotation = { 0.0, 0.0, 0.0 }
            rotation[rotationOrder] = -rot
            ---@diagnostic disable-next-line: missing-parameter, param-type-mismatch
            SetEntityRotation(entity, curRotation + vec3(rotation[1], rotation[2], rotation[3]))
        end

        Wait(5)
    end

    lib.hideTextUI()
    showText = false
    updateText = false

    return returnData
end

exports('Furnish', Furnish)

function OpenOwnedFurnitureMenu(place)
    local ownedFurniture = lib.callback.await('ice-furniture:server:getOwnedFurniture', false)
    local uniqueId = generateUniqueId()
    local furnitureOptions = {}

    if not next(ownedFurniture) then
        lib.notify({ description = locale("notify_nofurniture"), type = "error" })
        return
    end

    for _, furniture in pairs(ownedFurniture) do
        local furnSell = GetFurnitureData(furniture.object)
        furnitureOptions[#furnitureOptions + 1] = {
            title = furnSell.label .. ' | x' .. furniture.amount,
            icon = Config.Icons[furnSell.category],
            description = locale("menu_place"),
            onSelect = function()
                local furnitureData = Furnish(furnSell)
                if furnitureData then
                    if furnSell.category == "Storage" then
                        TriggerServerEvent('ice-furniture:server:spawnNewFurniture', furnitureData, place, uniqueId)
                    else
                        TriggerServerEvent('ice-furniture:server:spawnNewFurniture', furnitureData, place)
                    end
                    TriggerServerEvent("ice-furniture:server:removeFurniture", furnitureData.model)
                end
            end
        }
    end

    lib.registerContext({
        id = 'ice-furniture:client:owned_furniture',
        title = locale("furni_menu_title"),
        menu = "ice-furniture:client:mainMenu",
        options = furnitureOptions
    })
    lib.showContext('ice-furniture:client:owned_furniture')
end

exports('OpenOwnedFurnitureMenu', OpenOwnedFurnitureMenu)

function DespawnFurniture(id)
    if id and spawnedFurniture[id] then
        DeleteEntity(spawnedFurniture[id])
        spawnedFurniture[id] = nil
        return
    end

    if not spawnedFurniture or not next(spawnedFurniture) then
        return
    end

    for _, entity in pairs(spawnedFurniture) do
        DeleteEntity(entity)
    end

    spawnedFurniture = {}
end

RegisterNetEvent("ice-furniture:client:spawnFurniture", function(objects, new, edited)
    if not new and not edited then
        DespawnFurniture()
    end

    for _, v in pairs(objects) do
        if spawnedFurniture[v.id] then
            DespawnFurniture(v.id)
        end

        Wait(100)

        local coords = json.decode(v.pos)
        local rotation = json.decode(v.rotation)
        lib.requestModel(v.model, 500)
        local entity = CreateObject(v.model, coords.x, coords.y, coords.z, false, false, true)
        FreezeEntityPosition(prop, true)

        spawnedFurniture[v.id] = entity

        local furniture = GetFurnitureData(v.model)

        local options = {
            {
                label = locale("furni_target_move"),
                icon = 'fas fa-up-down-left-right',
                canInteract = function()
                    return editmode
                end,
                onSelect = function(info)
                    local edited = Furnish(furniture, info.entity)
                    if edited then
                        TriggerServerEvent('ice-furniture:server:editExistingFurniture', edited, v.location, v.id)
                        return
                    end

                    SetEntityCollision(info.entity, true, true)
                    SetEntityCoords(info.entity, coords.x, coords.y, coords.z, false, false, false, false)
                    ---@diagnostic disable-next-line: missing-parameter
                    SetEntityRotation(info.entity, rotation.x, rotation.y, rotation.z)
                    SetEntityAlpha(info.entity, 255, false)
                end
            },
            {
                label = locale("furni_target_delete"),
                icon = 'fas fa-trash',
                canInteract = function()
                    return editmode
                end,
                onSelect = function()
                    local check = lib.alertDialog({
                        header = locale("furni_delete_header", furniture.label),
                        content = locale("furni_delete_content"),
                        centered = true,
                        cancel = true
                    })

                    if check == "confirm" then
                        TriggerServerEvent("ice-furniture:server:removeExistingFurniture", v.id, v.location, v.model)
                    end
                end
            },
        }

        if v.uniqueId then
            options[#options + 1] = {
                label = locale("furni_target_open"),
                icon = 'fas fa-box',
                onSelect = function()
                    TriggerServerEvent("m-housing:server:openStash", v.uniqueId, v.location, v.model)
                    exports.ox_inventory:openInventory('stash', v.location .. "_" .. v.uniqueId)
                end
            }
        end

        exports.ox_target:addLocalEntity(entity, options)

        ---@diagnostic disable-next-line: missing-parameter
        SetEntityRotation(entity, rotation.x, rotation.y, rotation.z)
        SetEntityCoords(entity, coords.x, coords.y, coords.z, false, false, false, false)
    end
end)

function ToggleEditMode()
    editmode = not editmode
    lib.notify({ description = locale(editmode and "editmode_on" or "editmode_off"), type = "info" })
end

exports('ToggleEditMode', ToggleEditMode)

function OpenFurnitureMenu(id)
    local options = {
        {
            title = locale("main_menu_decorate"),
            icon = "fas fa-couch",
            onSelect = function()
                OpenOwnedFurnitureMenu(id)
            end
        },
        {
            title = locale("main_menu_buy"),
            icon = "fas fa-money-bill-transfer",
            onSelect = OpenShop
        },
        {
            title = locale("main_menu_edit"),
            icon = "fas fa-wand-magic-sparkles",
            onSelect = ToggleEditMode
        },
    }

    lib.registerContext({
        id = 'ice-furniture:client:mainMenu',
        title = locale("main_menu_title"),
        options = options
    })

    lib.showContext('ice-furniture:client:mainMenu')
end

exports('OpenFurnitureMenu', OpenFurnitureMenu)
RegisterNetEvent("ice-furniture:client:despawnFurniture", DespawnFurniture)
