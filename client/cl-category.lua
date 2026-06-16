Category = {}
Categories = {}
Category.__index = Category

local function generateNewCategoryId()
    local categoriesCount = 11
    for _ in pairs(Categories) do categoriesCount += 1 end

    if categoriesCount + 1 > 133 then 
        return
    end

    return categoriesCount + 1
end

function Category.new(data)
    assert(not Categories[data.name], ('category %s already exists'):format(data.name))

    local newId = data.id or generateNewCategoryId()
    assert(newId, 'cannot register any more categories')

    local self = setmetatable({}, Category)
    self.name = data.name
    self.label = data.label
    self.id = newId

    AddTextEntry('BLIP_CAT_' .. self.id, self.label)

    function self:remove()
        for _, blip in pairs(Blips) do
            if blip.category == self.name then
                SetBlipCategory(blip.blip, -1)
            end
        end

        Categories[self.name] = nil
        self = nil
    end

    Categories[data.name] = self
    return self
end

function Category.get(name)
    return Categories[name]
end

function GetCategory(name)
    return Categories[name]
end

function CreateCategory(data)
    return Category.new(data)
end

function DeleteCategory(name)
    assert(GetCategory(name), 'category doesn\'t exist.')
    
    GetCategory(name):remove()
end

-- CreateCategory({
--     name = 'testcategory',
--     label = 'Test Cat'
-- })

exports('getCategory', GetCategory)
exports('createCategory', CreateCategory)
exports('deleteCategory', DeleteCategory)