local ROTATION_INCREMENT                      = 0.1

local currentEntity, currentObject, currentId = nil, nil, 0
local entityHeading                           = 0

local function deleteCurrentEntity()
    if currentEntity then
        DeleteEntity(currentEntity)
        currentEntity = nil
    end
end

local function spawnLocalObject(model)
    deleteCurrentEntity()
    lib.requestModel(model)

    local forwardPos = GetEntityForwardVector(cache.ped)
    local pos = GetEntityCoords(cache.ped) + forwardPos * 1.5

    local obj = CreateObjectNoOffset(model, pos.x, pos.y, pos.z, false, false, false)
    FreezeEntityPosition(obj, true)
    SetEntityCollision(obj, false, false)
    currentEntity = obj

    return obj
end

local function rotateEntity()
    while currentEntity do
        Wait(5)
        SetEntityHeading(currentEntity, entityHeading + ROTATION_INCREMENT)
        entityHeading = entityHeading + ROTATION_INCREMENT
    end
end

local function map(array, callback)
    local result = {}
    for i, v in ipairs(array) do
        result[i] = callback(v, i)
    end
    return result
end

local openMenu = lib.addKeybind({
    name = 'furnituremenu',
    description = locale("shop_keybind_desc"),
    defaultKey = 'F',
    onPressed = function()
        if currentId == 0 then return end
        lib.showContext("ice-furniture:client:shop" .. currentId)
        lib.hideTextUI()
    end
})
openMenu:disable(true)

local buyItem = lib.addKeybind({
    name = 'buyfurni',
    description = locale("shop_keybind_desc"),
    defaultKey = 'E',
    onPressed = function()
        if currentId == 0 then return end
        local success = lib.callback.await("ice-furniture:server:buyFurniture", false, currentObject)

        if success then
            lib.notify({ description = locale("furni_bought"), type = "success" })
            lib.showContext("ice-furniture:client:shop" .. currentId)
            lib.hideTextUI()
        end
    end
})
buyItem:disable(true)

local function openContext(id)
    local config = Config.Furniture[id]
    local elements = map(config.furniture, function(v)
        return {
            title = v.label,
            onSelect = function()
                currentObject = v.object
                spawnLocalObject(currentObject)
                openMenu:disable(false)
                buyItem:disable(false)
                lib.showTextUI(("Open Menu: %s  \nBuy: %s"):format(
                    GetControlInstructionalButton(0, joaat('+furnituremenu') | 0x80000000, true):sub(3),
                    GetControlInstructionalButton(0, joaat('+buyfurni') | 0x80000000, true):sub(3)
                ))
                rotateEntity()
            end,
        }
    end)

    if not next(elements) then return end

    lib.registerContext({
        id = "ice-furniture:client:shop" .. id,
        title = config.label,
        menu = "ice-furniture:client:shop",
        onExit = deleteCurrentEntity,
        options = elements
    })
    lib.showContext("ice-furniture:client:shop" .. id)
    openMenu:disable(true)
    buyItem:disable(true)
end

local function openCurrentContext(id)
    currentId = id
    lib.hideTextUI()
    openContext(id)
end

function OpenShop()
    local elements = map(Config.Furniture, function(v, k)
        return {
            title = v.label,
            onSelect = function()
                openCurrentContext(k)
            end,
        }
    end)

    if not next(elements) then return end

    lib.registerContext({
        id = "ice-furniture:client:shop",
        title = locale("shop_menu_title"),
        menu = "ice-furniture:client:mainMenu",
        onExit = deleteCurrentEntity,
        options = elements
    })
    lib.showContext("ice-furniture:client:shop")
end
