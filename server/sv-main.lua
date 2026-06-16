local blipKVP = json.decode(GetResourceKvpString('filo_blips')) or {}
local validBlipImages = {}

CreateThread(function()
    for i = 1, 921 do
        local spriteUrl = ('https://raw.githubusercontent.com/DemiAutomatic/fivem-blip-images/refs/heads/main/blips/%s.webp'):format(i)
        PerformHttpRequest(spriteUrl, function(httpCode)
            if httpCode == 200 then
                validBlipImages[i] = true
            end
        end, 'GET')
    end

    local packed = msgpack.pack(blipKVP)
    SetStateBagValue('global', 'filo_blips', packed, #packed, true)
end)

local function setBlipStatebag()
    local packed = msgpack.pack(blipKVP)
    SetStateBagValue('global', 'filo_blips', packed, #packed, true)
    SetResourceKvp('filo_blips', json.encode(blipKVP))
end

lib.callback.register('filo_blips:server:getValidBlipImages', function(source)
    return msgpack.pack(validBlipImages)
end)

lib.callback.register('filo_blips:server:createPersistentBlip', function(source, data)
    local src = source
    if not Framework.GetIsFrameworkAdmin(src) then return end
    
    local id = GenerateUniqueID(blipKVP)
    local kvpData = {
        id = id,
        label = data.label,
        coords = data.coords,
        color = data.color,
        sprite = data.sprite,
        scale = data.scale
    }

    blipKVP[id] = kvpData
    setBlipStatebag()
    return true
end)

lib.callback.register('filo_blips:server:editPersistentBlip', function(source, data)
    local src = source
    if not Framework.GetIsFrameworkAdmin(src) then return end
    if not blipKVP[data.id] then return end
    blipKVP[data.id] = {
        label = data.newLabel,
        coords = data.coords,
        color = data.color,
        sprite = data.sprite,
        scale = data.scale,
        global = true
    }
    setBlipStatebag()
    return true
end)

lib.callback.register('filo_blips:server:deletePersistentBlip', function(source, data)
    local src = source
    if not Framework.GetIsFrameworkAdmin(src) then return end

    if not blipKVP[data.id] then return end
    blipKVP[data.id] = nil

    setBlipStatebag()
    return true
end)

lib.addCommand(Config.Command, {
    help = 'Open blip creator menu.',
}, function(source, args)
    local src = source
    TriggerClientEvent('filo_blips:client:showBlipsMenu', src, Framework.GetIsFrameworkAdmin(src))
end)