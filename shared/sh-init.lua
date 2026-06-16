Bridge = exports.community_bridge:Bridge()

for key, value in pairs(Bridge) do
    if key ~= "Entity" and key ~= "MySQL" then
        load(key .. " = ...") (value)
    end
end


function GenerateUniqueID(tbl)
    local id = lib.string.random('AAAA1111')
    if tbl and tbl[id] then
        repeat id = lib.string.random('AAAA1111') until not tbl[id]
    end
    return id
end

function DebugPrint(...)
    if Config.Debug then
        print(...)
    end
end