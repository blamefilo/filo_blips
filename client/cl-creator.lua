local globalBlipsCache = {}
local personalBlipsCache = {}
local globalBlips = GlobalState.filo_blips or {}
local personalBlips = {}

local draft = {
    pos    = nil,
    sprite = nil,
    label  = nil,
    scale  = nil,
    color  = '0xFFFFFF',
    global = false,
}

local function genLocalID()
    return ('personal_%s_%s'):format(GetGameTimer(), math.random(100000, 999999))
end

local function savePersonalBlips()
    SetResourceKvp('filo_blips', json.encode(personalBlips))
end

local function hexToIcon(hex)   return string.gsub(hex or '0xFFFFFF', '0x', '#') end
local function iconToHex(icon)  return string.gsub(icon, '#', '0x') end
local function spriteIcon(id)
    return id and ('https://raw.githubusercontent.com/DemiAutomatic/fivem-blip-images/refs/heads/main/blips/%s.webp'):format(id)
           or 'fas fa-location-dot'
end

local function getWaypoint()
    local wp = GetFirstBlipInfoId(8)
    return wp ~= 0 and wp, wp ~= 0 and GetBlipInfoIdCoord(wp)
end

local function notify(title, msg, kind) Notify.SendNotification(title, msg, kind) end

local function pickSprite(onPick, backCtx)
    local result = lib.inputDialog('Blip Sprite', {{
        type = 'number', label = 'Blip ID', required = true,
        description = 'Enter the blip ID (1-921). https://docs.fivem.net/docs/game-references/blips/',
        min = 1, max = 921, default = draft.sprite or 1
    }})
    if result and result[1] then onPick(result[1])
    else lib.showContext(backCtx) end
end

local function coordMenu(ctxId, title, onPick, backFn)
    local _, wPos = getWaypoint()
    lib.registerContext({
        id = ctxId, title = title,
        options = {
            {
                title = 'Current Position', description = 'Use your current position.',
                onSelect = function() onPick(GetEntityCoords(cache.ped)) end
            },
            {
                title = 'Waypoint Position', description = 'Use your waypoint.',
                disabled = not wPos,
                onSelect = function() onPick(wPos) end
            }
        }
    })
    lib.showContext(ctxId)
end

-- ──────────────────────── blip creator ───────────────────────

local function showBlipCreator(isAdmin)
    local options = {
        {
            title = 'Coordinates',
            icon = 'fas fa-location-crosshairs',
            description = draft.pos and ('x: %.2f, y: %.2f, z: %.2f'):format(draft.pos.x, draft.pos.y, draft.pos.z),
            onSelect = function()
                coordMenu('blip_coord_pick', 'Blip Coordinates', function(pos)
                    draft.pos = pos
                    showBlipCreator(isAdmin)
                end)
            end
        },
        {
            title = draft.label and ('Name: ' .. draft.label) or 'Name',
            icon = 'fas fa-file-signature',
            description = 'Enter a name for the blip',
            onSelect = function()
                local result
                repeat
                    result = lib.inputDialog('Blip Name', {{ type = 'input', label = 'Name', required = true, default = draft.label }})
                until not result or not result[1] or not globalBlipsCache[result[1]]
                if result and result[1] then
                    draft.label = result[1]
                    showBlipCreator(isAdmin)
                end
            end
        },
        {
            title = 'Sprite',
            icon = spriteIcon(draft.sprite),
            description = 'Select a blip sprite',
            onSelect = function()
                pickSprite(function(i) draft.sprite = i; showBlipCreator(isAdmin) end, 'blip_creator')
            end
        },
        {
            title = draft.scale and ('Scale: ' .. draft.scale) or 'Scale',
            icon = 'fas fa-up-right-and-down-left-from-center',
            description = 'Set the blip scale',
            onSelect = function()
                local result = lib.inputDialog('Blip Scale', {{
                    type = 'slider', label = 'Scale', required = true,
                    description = 'Enter the blip scale (0.1 - 3.0)',
                    min = 0.1, max = 3.0, step = 0.1, default = draft.scale or 1.0
                }})
                if result and result[1] then draft.scale = result[1]; showBlipCreator(isAdmin) end
            end
        },
        {
            title = 'Color',
            icon = 'fas fa-circle',
            iconColor = hexToIcon(draft.color),
            description = 'Select a blip color',
            onSelect = function()
                local input = lib.inputDialog('Blip Color', {{
                    type = 'color', label = 'Color', format = 'hex', required = true,
                    description = 'Select a color for the blip',
                    default = hexToIcon(draft.color)
                }})
                if input and input[1] then draft.color = iconToHex(input[1]) end
                showBlipCreator(isAdmin)
            end
        },
    }

    if isAdmin then
        options[#options + 1] = {
            title = 'Visible to all',
            icon = draft.global and 'far fa-circle-check' or 'far fa-circle',
            description = 'Make this blip visible to all players',
            onSelect = function() draft.global = not draft.global; showBlipCreator(isAdmin) end
        }
    end

    local canCreate = draft.label and draft.pos and draft.scale and draft.color and draft.sprite
    options[#options + 1] = {
        title = 'Create Blip',
        icon = 'fas fa-file-circle-check',
        disabled = not canCreate,
        onSelect = function()
            if draft.global then
                local ok = lib.callback.await('filo_blips:server:createPersistentBlip', nil, {
                    label = draft.label, sprite = draft.sprite,
                    color = draft.color, coords = draft.pos, scale = draft.scale
                })
                notify(ok and 'Blip created successfully.' or 'Failed to create blip.',
                       ok and 'The blip is now visible to all players.' or 'There was an error creating the blip.',
                       ok and 'success' or 'error')
            else
                local blipData = {
                    id       = genLocalID(),
                    label    = draft.label,
                    sprite   = draft.sprite,
                    color    = draft.color,
                    coords   = draft.pos,
                    scale    = draft.scale,
                    category = 'personal'
                }
                personalBlips[blipData.id] = blipData
                savePersonalBlips()
                CreatePersonalBlips()
                notify('Blip created.', 'Your personal blip has been saved.', 'success')
            end
        end
    }

    lib.registerContext({ id = 'blip_creator', title = 'Blip Creator', options = options })
    lib.showContext('blip_creator')
end

-- ──────────────────────── manage blips ───────────────────────

local function showManageBlipsMenu(isAdmin)
    local function manageBlip(blipData, blipType)
        local function showManageOptions()
            lib.registerContext({
                id = 'manage_blip_options',
                title = blipData.label,
                options = {
                    {
                        title = 'Name: ' .. blipData.label,
                        icon = 'fas fa-file-signature',
                        description = 'Rename this blip',
                        onSelect = function()
                            local result = lib.inputDialog('Rename Blip', {{ type = 'input', label = 'Name', required = true, default = blipData.label }})
                            if result and result[1] then blipData.newLabel = result[1]; blipData.label = result[1]; showManageOptions() end
                        end
                    },
                    {
                        title = 'Sprite',
                        icon = spriteIcon(blipData.sprite),
                        description = 'Change the blip sprite',
                        onSelect = function()
                            pickSprite(function(i) blipData.sprite = i; showManageOptions() end, 'manage_blip_options')
                        end
                    },
                    {
                        title = blipData.scale and ('Scale: ' .. blipData.scale) or 'Scale',
                        icon = 'fas fa-up-right-and-down-left-from-center',
                        description = 'Change the blip scale',
                        onSelect = function()
                            local result = lib.inputDialog('Blip Scale', {{
                                type = 'slider', label = 'Scale', required = true,
                                description = 'Set the blip scale (0.1 - 3.0)',
                                min = 0.1, max = 3.0, step = 0.1, default = blipData.scale or 1.0
                            }})
                            if result and result[1] then blipData.scale = result[1]; showManageOptions() end
                        end
                    },
                    {
                        title = 'Color',
                        icon = 'fas fa-circle',
                        iconColor = hexToIcon(blipData.color),
                        description = 'Change the blip color',
                        onSelect = function()
                            local input = lib.inputDialog('Blip Color', {{
                                type = 'color', label = 'Color', format = 'hex', required = true,
                                description = 'Select a new color for the blip',
                                default = hexToIcon(blipData.color)
                            }})
                            if input and input[1] then
                                blipData.color = tonumber(iconToHex(input[1]) .. 'FF')
                                showManageOptions()
                            end
                        end
                    },
                    {
                        title = 'Coordinates',
                        icon = 'fas fa-location-crosshairs',
                        description = blipData.coords
                            and ('x: %.2f, y: %.2f, z: %.2f'):format(blipData.coords.x, blipData.coords.y, blipData.coords.z)
                            or 'Not set',
                        onSelect = function()
                            coordMenu('edit_blip_coordinates', 'Change Coordinates', function(pos)
                                blipData.coords = pos
                                showManageOptions()
                            end)
                        end
                    },
                    {
                        title = 'Save Changes',
                        icon = 'fas fa-floppy-disk',
                        onSelect = function()
                            if blipType == 'global' then
                                local ok = lib.callback.await('filo_blips:server:editPersistentBlip', nil, {
                                    id       = blipData.id,
                                    newLabel = blipData.newLabel or blipData.label,
                                    coords   = blipData.coords,
                                    color    = blipData.color,
                                    sprite   = blipData.sprite
                                })
                                notify(ok and 'Blip updated.' or 'Error',
                                       ok and 'Changes saved and applied to all players.' or 'Failed to save blip changes.',
                                       ok and 'success' or 'error')
                            else
                                personalBlips[blipData.id] = blipData
                                savePersonalBlips()
                                CreatePersonalBlips()
                                notify('Blip updated.', 'Your personal blip has been updated.', 'success')
                            end
                            showManageBlipsMenu(isAdmin)
                        end
                    },
                    {
                        title = 'Delete Blip',
                        icon = 'fas fa-trash',
                        description = blipType == 'global' and 'Remove this blip for all players' or 'Remove this personal blip',
                        onSelect = function()
                            if lib.alertDialog({
                                header = 'Delete Blip',
                                content = ('Are you sure you want to delete **%s**?'):format(blipData.label),
                                centered = true, cancel = true
                            }) ~= 'confirm' then return end

                            if blipType == 'global' then
                                local ok = lib.callback.await('filo_blips:server:deletePersistentBlip', nil, { id = blipData.id })
                                if ok then
                                    globalBlips[blipData.id] = nil
                                    globalBlipsCache[blipData.id] = nil
                                    DeleteBlip(blipData.id)
                                end
                                notify(ok and 'Blip deleted.' or 'Error',
                                       ok and 'The blip has been removed for all players.' or 'Failed to delete blip.',
                                       ok and 'success' or 'error')
                            else
                                personalBlips[blipData.id] = nil
                                personalBlipsCache[blipData.id] = nil
                                savePersonalBlips()
                                DeleteBlip(blipData.id)
                                notify('Blip deleted.', 'Your personal blip has been removed.', 'success')
                            end
                            showManageBlipsMenu(isAdmin)
                        end
                    }
                }
            })
            lib.showContext('manage_blip_options')
        end
        showManageOptions()
    end

    local options = {}

    if isAdmin then
        for _, v in pairs(globalBlips) do
            options[#options + 1] = {
                title = v.label, icon = spriteIcon(v.sprite), description = 'Global blip',
                onSelect = function() manageBlip(lib.table.clone(v), 'global') end
            }
        end
    end

    for _, v in pairs(personalBlips) do
        options[#options + 1] = {
            title = v.label, icon = spriteIcon(v.sprite), description = 'Personal blip',
            onSelect = function() manageBlip(lib.table.clone(v), 'personal') end
        }
    end

    if #options < 1 then notify('Error', 'No blips found.', 'error'); return end

    lib.registerContext({ id = 'manage_blips', title = 'Manage Blips', options = options })
    lib.showContext('manage_blips')
end

local function showBlipsMenu(isAdmin)
    lib.registerContext({
        id = 'blips_menu', title = 'Blips',
        options = {
            { title = 'Create Blip',  icon = 'fas fa-location-dot', onSelect = function() showBlipCreator(isAdmin) end },
            { title = 'Manage Blips', icon = 'fas fa-circle',       onSelect = function() showManageBlipsMenu(isAdmin) end }
        }
    })
    lib.showContext('blips_menu')
end

RegisterNetEvent('filo_blips:client:showBlipsMenu', function(isAdmin)
    draft.pos    = nil
    draft.label  = nil
    draft.sprite = nil
    draft.scale  = nil
    draft.color  = '0xFFFFFF'
    draft.global = false
    showBlipsMenu(isAdmin)
end)

function CreateBlips(blips, blipType)
    local blipCache = blipType == 'global' and globalBlipsCache or personalBlipsCache
    local found = {}

    for _, v in pairs(blips) do
        found[v.id] = true
        if not blipCache[v.id] then
            local blip = CreateBlip({
                name     = v.id,
                label    = v.label,
                color    = tonumber(v.color .. 'FF'),
                sprite   = v.sprite,
                coords   = v.coords,
                category = v.category or blipType
            })
            blipCache[v.id] = blipType == 'global' and blip or v
        elseif not lib.table.matches(blipCache[v.id], v) then
            local blip = GetBlip(v.id)
            for k, val in pairs(v) do blip[k] = val end
        end
    end

    for id in pairs(blipCache) do
        if not found[id] then
            blipCache[id] = nil
            DeleteBlip(id)
        end
    end
end

function CreateGlobalBlips()   CreateBlips(globalBlips,   'global')   end
function CreatePersonalBlips() CreateBlips(personalBlips, 'personal') end

AddStateBagChangeHandler('filo_blips', 'global', function(_, _, value)
    globalBlips = value
    CreateGlobalBlips()
end)

AddEventHandler('onResourceStart', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end
    CreateGlobalBlips()
    CreatePersonalBlips()
end)