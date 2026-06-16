local globalBlipsCache = {}
local personalBlipsCache = {}
local globalBlips = GlobalState.filo_blips or {}
local personalBlips = {}

local chosenBlipPos = nil
local chosenBlipSprite = nil
local chosenBlipLabel = nil
local chosenBlipScale = nil
local chosenColor = '0xFFFFFF'
local visibleToAll = false

local function generateLocalID()
    return ('personal_%s_%s'):format(GetGameTimer(), math.random(100000, 999999))
end

local function savePersonalBlips()
    SetResourceKvp('filo_blips', json.encode(personalBlips))
end

local function showSpriteSelector(onPick, backContext)
    local result = lib.inputDialog('Blip Sprite', {
        {
            type = 'number',
            label = 'Blip ID',
            description = 'Enter the blip ID (1-921). https://docs.fivem.net/docs/game-references/blips/',
            required = true,
            min = 1,
            max = 921,
            default = chosenBlipSprite or 1
        }
    })
    
    if result and result[1] then
        chosenBlipSprite = result[1]
        onPick(chosenBlipSprite)
    else
        lib.showContext(backContext)
    end
end

local function showBlipCreator(isAdmin)
    local wPoint = GetFirstBlipInfoId(8)
    local wPos = wPoint and GetBlipInfoIdCoord(wPoint)
    
    local options = {}
    table.insert(options, {
        title = 'Coordinates',
        icon = 'fas fa-location-crosshairs',
        description = chosenBlipPos and ('x: %.2f, y: %.2f, z: %.2f'):format(chosenBlipPos.x, chosenBlipPos.y, chosenBlipPos.z),
        onSelect = function()
            lib.registerContext({
                id = 'blip_coordinates',
                title = 'Blip Coordinates',
                options = {
                    {
                        title = 'Current Position',
                        description = 'Use current position.',
                        onSelect = function()
                            chosenBlipPos = GetEntityCoords(cache.ped)
                            showBlipCreator(isAdmin)
                        end
                    },
                    {
                        title = 'Waypoint Position',
                        description = 'Use waypoint position.',
                        disabled = wPoint == 0,
                        onSelect = function()
                            chosenBlipPos = wPos
                            showBlipCreator(isAdmin)
                        end
                    }
                }
            })
            lib.showContext('blip_coordinates')
        end
    })
    
    table.insert(options, {
        title = 'Name' .. (chosenBlipLabel and (': ' .. chosenBlipLabel) or ''),
        icon = 'fas fa-file-signature',
        description = 'Enter a name for the blip',
        onSelect = function()
            local result = lib.inputDialog('Blip Name', {
                { type = 'input', label = 'Name', required = true, default = chosenBlipLabel }
            })
            if result and result[1] then
                if globalBlipsCache[result[1]] then
                    Notify.SendNotification('Error', 'Blip name already exists.', 'error')
                    repeat
                        result = lib.inputDialog('Blip Name', {
                            { type = 'input', label = 'Name', required = true, default = chosenBlipLabel }
                        })
                    until not globalBlipsCache[result[1]]
                end
                chosenBlipLabel = result[1]
                showBlipCreator(isAdmin)
            end
        end
    })
    
    table.insert(options, {
        title = 'Sprite',
        icon = chosenBlipSprite and ('https://raw.githubusercontent.com/DemiAutomatic/fivem-blip-images/refs/heads/main/blips/%s.webp'):format(chosenBlipSprite) or 'fas fa-location-dot',
        description = 'Select a blip sprite',
        onSelect = function()
            showSpriteSelector(function(i)
                chosenBlipSprite = i
                showBlipCreator(isAdmin)
            end, 'blip_creator')
        end
    })
    
    table.insert(options, {
        title = 'Scale' .. (chosenBlipScale and (': ' .. chosenBlipScale) or ''),
        icon = 'fas fa-up-right-and-down-left-from-center',
        description = 'Set the blip scale',
        onSelect = function()
            local result = lib.inputDialog('Blip Scale', {
                {
                    type = 'slider',
                    label = 'Scale',
                    description = 'Enter the blip scale (0.1 - 3.0)',
                    required = true,
                    min = 0.1,
                    max = 3.0,
                    step = 0.1,
                    default = chosenBlipScale or 1.0
                }
            })
            if result and result[1] then
                chosenBlipScale = result[1]
                showBlipCreator(isAdmin)
            end
        end
    })
    
    table.insert(options, {
        title = 'Color',
        icon = 'fas fa-circle',
        iconColor = string.gsub(chosenColor, '0x', '#'),
        description = 'Select a blip color',
        onSelect = function()
            local input = lib.inputDialog('Blip Color', {
                {
                    type = 'color',
                    label = 'Color',
                    description = 'Select a color for the blip',
                    format = 'hex',
                    default = string.gsub(chosenColor, '0x', '#'),
                    required = true
                }
            })
            if input and input[1] then
                chosenColor = string.gsub(input[1], '#', '0x')
            end
            showBlipCreator(isAdmin)
        end
    })
    
    if isAdmin then
        table.insert(options, {
            title = 'Visible to all',
            icon = visibleToAll and 'far fa-circle-check' or 'far fa-circle',
            description = 'Make this blip visible to all players',
            onSelect = function()
                visibleToAll = not visibleToAll
                showBlipCreator(isAdmin)
            end
        })
    end
    
    table.insert(options, {
        title = 'Create Blip',
        icon = 'fas fa-file-circle-check',
        disabled = not chosenBlipLabel or not chosenBlipPos or not chosenBlipScale or not chosenColor or not chosenBlipSprite,
        onSelect = function()
            if visibleToAll then
                if lib.callback.await('filo_blips:server:createPersistentBlip', nil, {
                    label = chosenBlipLabel,
                    sprite = chosenBlipSprite,
                    color = chosenColor,
                    coords = chosenBlipPos,
                    scale = chosenBlipScale
                }) then
                    Notify.SendNotification('Blip created successfully.', 'The blip has been created and is now visible to all players.', 'success')
                else
                    Notify.SendNotification('Failed to create blip.', 'There was an error creating the blip.', 'error')
                end
            else
                local blipData = {
                    id = generateLocalID(),
                    label = chosenBlipLabel,
                    sprite = chosenBlipSprite,
                    color = chosenColor,
                    coords = chosenBlipPos,
                    scale = chosenBlipScale,
                    category = 'personal'
                }
                personalBlips[blipData.id] = blipData
                savePersonalBlips()
                CreatePersonalBlips()
                Notify.SendNotification('Blip created.', 'Your personal blip has been saved.', 'success')
            end
        end
    })
    
    lib.registerContext({
        id = 'blip_creator',
        title = 'Blip Creator',
        options = options
    })
    lib.showContext('blip_creator')
end

local function showManageBlipsMenu(isAdmin)
    local options = {}
    
    local function manageBlip(blipData, blipType)
        local function showManageOptions()
            local wPoint = GetFirstBlipInfoId(8)
            local wPos = wPoint and GetBlipInfoIdCoord(wPoint)
            
            lib.registerContext({
                id = 'manage_blip_options',
                title = blipData.label,
                options = {
                    {
                        title = 'Name: ' .. blipData.label,
                        icon = 'fas fa-file-signature',
                        description = 'Rename this blip',
                        onSelect = function()
                            local result = lib.inputDialog('Rename Blip', {
                                { type = 'input', label = 'Name', required = true, default = blipData.label }
                            })
                            if result and result[1] then
                                blipData.newLabel = result[1]
                                blipData.label = result[1]
                                showManageOptions()
                            end
                        end
                    },
                    {
                        title = 'Sprite',
                        icon = blipData.sprite and ('https://raw.githubusercontent.com/DemiAutomatic/fivem-blip-images/refs/heads/main/blips/%s.webp'):format(blipData.sprite) or 'fas fa-location-dot',
                        description = 'Change the blip sprite',
                        onSelect = function()
                            showSpriteSelector(function(i)
                                blipData.sprite = i
                                showManageOptions()
                            end, 'manage_blip_options')
                        end
                    },
                    {
                        title = 'Scale' .. (blipData.scale and (': ' .. blipData.scale) or ''),
                        icon = 'fas fa-up-right-and-down-left-from-center',
                        description = 'Change the blip scale',
                        onSelect = function()
                            local result = lib.inputDialog('Blip Scale', {
                                {
                                    type = 'slider',
                                    label = 'Scale',
                                    description = 'Set the blip scale (0.1 - 3.0)',
                                    required = true,
                                    min = 0.1,
                                    max = 3.0,
                                    step = 0.1,
                                    default = blipData.scale or 1.0
                                }
                            })
                            if result and result[1] then
                                blipData.scale = result[1]
                                showManageOptions()
                            end
                        end
                    },
                    {
                        title = 'Color',
                        icon = 'fas fa-circle',
                        iconColor = string.gsub(blipData.color or '0xFFFFFF', '0x', '#'),
                        description = 'Change the blip color',
                        onSelect = function()
                            local input = lib.inputDialog('Blip Color', {
                                {
                                    type = 'color',
                                    label = 'Color',
                                    description = 'Select a new color for the blip',
                                    format = 'hex',
                                    default = string.gsub(blipData.color or '0xFFFFFF', '0x', '#'),
                                    required = true
                                }
                            })
                            if input and input[1] then
                                local hexValue = tonumber(string.gsub(input[1], '#', '0x') .. 'FF')
                                blipData.color = hexValue
                                showManageOptions()
                            end
                        end
                    },
                    {
                        title = 'Coordinates',
                        icon = 'fas fa-location-crosshairs',
                        description = blipData.coords and ('x: %.2f, y: %.2f, z: %.2f'):format(blipData.coords.x, blipData.coords.y, blipData.coords.z) or 'Not set',
                        onSelect = function()
                            lib.registerContext({
                                id = 'edit_blip_coordinates',
                                title = 'Change Coordinates',
                                options = {
                                    {
                                        title = 'Current Position',
                                        description = 'Move blip to your current position.',
                                        onSelect = function()
                                            blipData.coords = GetEntityCoords(cache.ped)
                                            showManageOptions()
                                        end
                                    },
                                    {
                                        title = 'Waypoint Position',
                                        description = 'Move blip to your waypoint.',
                                        disabled = wPoint == 0,
                                        onSelect = function()
                                            blipData.coords = wPos
                                            showManageOptions()
                                        end
                                    }
                                }
                            })
                            lib.showContext('edit_blip_coordinates')
                        end
                    },
                    {
                        title = 'Save Changes',
                        icon = 'fas fa-floppy-disk',
                        onSelect = function()
                            if blipType == 'global' then
                                if lib.callback.await('filo_blips:server:editPersistentBlip', nil, {
                                    id       = blipData.id,
                                    newLabel = blipData.newLabel or blipData.label,
                                    coords   = blipData.coords,
                                    color    = blipData.color,
                                    sprite   = blipData.sprite
                                }) then
                                    Notify.SendNotification('Blip updated.', 'Changes saved and applied to all players.', 'success')
                                else
                                    Notify.SendNotification('Error', 'Failed to save blip changes.', 'error')
                                end
                            elseif blipType == 'personal' then
                                personalBlips[blipData.id] = blipData
                                savePersonalBlips()
                                CreatePersonalBlips()
                                Notify.SendNotification('Blip updated.', 'Your personal blip has been updated.', 'success')
                            end
                            showManageBlipsMenu(isAdmin)
                        end
                    },
                    {
                        title = 'Delete Blip',
                        icon = 'fas fa-trash',
                        description = blipType == 'global' and 'Remove this blip for all players' or 'Remove this personal blip',
                        onSelect = function()
                            local confirmed = lib.alertDialog({
                                header = 'Delete Blip',
                                content = ('Are you sure you want to delete **%s**?'):format(blipData.label),
                                centered = true,
                                cancel = true
                            })
                            if confirmed ~= 'confirm' then return end
                            
                            if blipType == 'global' then
                                if lib.callback.await('filo_blips:server:deletePersistentBlip', nil, {
                                    id = blipData.id
                                }) then
                                    Notify.SendNotification('Blip deleted.', 'The blip has been removed for all players.', 'success')
                                    globalBlips[blipData.id] = nil
                                    globalBlipsCache[blipData.id] = nil
                                    DeleteBlip(blipData.id)
                                else
                                    Notify.SendNotification('Error', 'Failed to delete blip.', 'error')
                                end
                            elseif blipType == 'personal' then
                                personalBlips[blipData.id] = nil
                                savePersonalBlips()
                                DeleteBlip(blipData.id)
                                personalBlipsCache[blipData.id] = nil
                                Notify.SendNotification('Blip deleted.', 'Your personal blip has been removed.', 'success')
                            end
                        end
                    }
                }
            })
            lib.showContext('manage_blip_options')
        end
        
        showManageOptions()
    end
    
    if isAdmin then
        for k, v in pairs(globalBlips) do
            table.insert(options, {
                title = v.label,
                icon = v.sprite and ('https://raw.githubusercontent.com/DemiAutomatic/fivem-blip-images/refs/heads/main/blips/%s.webp'):format(v.sprite) or 'fas fa-location-dot',
                description = 'Global blip',
                onSelect = function()
                    manageBlip(lib.table.clone(v), 'global')
                end
            })
        end
    end
    
    for k, v in pairs(personalBlips) do
        table.insert(options, {
            title = v.label,
            icon = v.sprite and ('https://raw.githubusercontent.com/DemiAutomatic/fivem-blip-images/refs/heads/main/blips/%s.webp'):format(v.sprite) or 'fas fa-location-dot',
            description = 'Personal blip',
            onSelect = function()
                manageBlip(lib.table.clone(v), 'personal')
            end
        })
    end
    
    if #options < 1 then
        Notify.SendNotification('Error', 'No blips found.', 'error')
        return
    end
    
    lib.registerContext({
        id = 'manage_blips',
        title = 'Manage Blips',
        options = options
    })
    lib.showContext('manage_blips')
end

local function showBlipsMenu(isAdmin)
    local options = {}
    table.insert(options, {
        title = 'Create Blip',
        icon = 'fas fa-location-dot',
        onSelect = function()
            showBlipCreator(isAdmin)
        end
    })
    
    table.insert(options, {
        title = 'Manage Blips',
        icon = 'fas fa-circle',
        onSelect = function()
            showManageBlipsMenu(isAdmin)
        end
    })
    
    lib.registerContext({
        id = 'blips_menu',
        title = 'Blips',
        options = options
    })
    lib.showContext('blips_menu')
end

RegisterNetEvent('filo_blips:client:showBlipsMenu', function(isAdmin)
    chosenBlipPos = nil
    chosenBlipLabel = nil
    chosenBlipSprite = nil
    chosenBlipScale = nil
    chosenColor = '0xFFFFFF'
    visibleToAll = false
    
    showBlipsMenu(isAdmin)
end)

function CreateBlips(blips, type)
    local foundBlips = {}
    for _, v in pairs(blips) do
        if not (type == 'global' and globalBlipsCache[v.id]) and not (type == 'personal' and personalBlipsCache[v.id]) then
            local hexValue = tonumber(v.color .. 'FF')
            local blip = CreateBlip({
                name = v.id,
                label = v.label,
                color = hexValue,
                sprite = v.sprite,
                coords = v.coords,
                category = v.category or type
            })
            
            if type == 'global' then
                globalBlipsCache[v.id] = blip
            elseif type == 'personal' then
                personalBlipsCache[v.id] = v
            end
            foundBlips[v.id] = true
        elseif (type == 'global' and globalBlipsCache[v.id] and not lib.table.matches(globalBlipsCache[v.id], v)) or (type == 'personal' and personalBlipsCache[v.id] and not lib.table.matches(personalBlipsCache[v.id], v)) then
            local blip = GetBlip(v.id)
            for key, value in pairs(v) do
                blip[key] = value
            end
            foundBlips[v.id] = true
        else
            foundBlips[v.id] = true
        end
    end
    
    if type == 'global' then
        for id in pairs(globalBlipsCache) do
            if not foundBlips[id] then
                globalBlipsCache[id] = nil
                DeleteBlip(id)
            end
        end
    elseif type == 'personal' then
        for id in pairs(personalBlipsCache) do
            if not foundBlips[id] then
                personalBlipsCache[id] = nil
                DeleteBlip(id)
            end
        end
    end
end

function CreateGlobalBlips()
    CreateBlips(globalBlips, 'global')
end

function CreatePersonalBlips()
    CreateBlips(personalBlips, 'personal')
end

AddStateBagChangeHandler('filo_blips', 'global', function(bagName, key, value)
    globalBlips = value
    CreateGlobalBlips()
end)

AddEventHandler('onResourceStart', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end
    CreateGlobalBlips()
    CreatePersonalBlips()
end)