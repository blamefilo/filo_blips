Blip = {}
Blips = {}

local blipMeta = {
    __index = function(self, key)
        local data = rawget(self, "_data")
        return data[key]
    end,
    __newindex = function(self, key, value)
        local data = rawget(self, "_data")
        
        if key == "sprite" then
            SetBlipSprite(self.blip, value + 0.0)
        elseif key == "scale" then
            SetBlipScale(self.blip, value)
        elseif key == "color" or key == "colour" then
            SetBlipColour(self.blip, value)
        end
        
        data[key] = value
        if self.setValues then
            self:setValues()
        end
    end
}

function Blip.new(data)
    local self = setmetatable({}, blipMeta) 
    rawset(self, "_data", {})

    self.name = data.name
    self.coords = data.coords
    self.label = data.label
    self.sprite = data.sprite
    self.scale = data.scale or 0.9
    self.color = data.color or data.colour
    self.category = data.category
    self.display = data.display or 4
    self.shortRange = data.shortRange or true
    self.resource = GetInvokingResource()
    self.blip = AddBlipForCoord(self.coords.x, self.coords.y, self.coords.z)

    local key = data.name or #Blips + 1
    if self.category then
        local category = Category.get(self.category)
        if category then
            SetBlipCategory(self.blip, category.id)
        end
    end

    function self:setValues()
        SetBlipCoords(self.blip, self.coords.x, self.coords.y, self.coords.z)
        SetBlipSprite(self.blip, self.sprite)
        SetBlipScale(self.blip, self.scale + 0.0)
        SetBlipColour(self.blip, self.color)
        SetBlipDisplay(self.blip, self.hidden and 0 or self.display)
        SetBlipAsShortRange(self.blip, self.shortRange)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentSubstringPlayerName(self.label)
        EndTextCommandSetBlipName(self.blip)
    end

    function self:hide(state)
        self.hidden = state
    end

    function self:remove()
        RemoveBlip(self.blip)
        Blips[key] = nil
    end

    self:setValues()
    Blips[key] = self
    return self
end

function Blip.get(name)
    for k, v in pairs(Blips) do
        if v.name == name then
            return v
        end
    end
end

function GetBlip(name)
    return Blips[name]
end

function HideBlipCategory(category)
    for _, v in pairs(Blips) do
        if v.category == category then
            v.hidden = true
        end
    end
end

function ShowBlipCategory(category)
    for _, v in pairs(Blips) do
        if v.category == category then
            v.hidden = false
        end
    end
end

function HideBlip(name, state)
    assert(GetBlip(name), 'blip doesn\'t exist.')
    GetBlip(name):hide(state)
end

function CreateBlip(data)
    return Blip.new(data)
end

function DeleteBlip(name)
    assert(GetBlip(name), 'blip doesn\'t exist.')
    GetBlip(name):remove()
end

exports('getBlip', GetBlip)
exports('hideBlipCategory', HideBlipCategory)
exports('showBlipCategory', ShowBlipCategory)
exports('hideBlip', HideBlip)
exports('createBlip', CreateBlip)
exports('deleteBlip', DeleteBlip)