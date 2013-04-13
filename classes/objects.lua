--[[ Objects/Entities class ]]

module(..., package.seeall)

Objects = {}
Objects.__index = Objects

function Objects.new(name)
    local objects = {}                  -- instance
    setmetatable(objects, Objects)
    objects.name = name or 'default'
    objects.items = {}
    objects.npcs = {}
    objects.monsters= {}
    objects.hero = {}                   -- Init empty grid
    return objects
end

function Objects:get_name()
    --[[ Return name ]]
    return self.name
end


function Objects:load_level(objects_viewport, level)
    -- Loads a level matrix into the objects layer
    self.layer = MOAILayer2D.new()
    self.layer:setViewport(objects_viewport)
    
    local objects_array = helpers.json.decode_file(level)

    self:load_objects(objects_array)    -- Objects and characters
end

function Objects:load_objects (objects_array)
    --[[ Set up our items, hero, monsters, etc, in the world.
    TODO: This should be a part of the objects making module. --]]

    print("loading objects..")

    self.items = {
        classes.item.new('dull sword', 'sword', 16, 12),
        classes.item.new('gold key', 'key', 23, 23)
    }
    for k, entry in ipairs(self.items) do
        self.layer:insertProp(entry.prop)
    end

    self.humans = {
        classes.char.new('strange kid', 'kid', 30, 19)
    }
    for k, entry in ipairs(self.humans) do
        self.layer:insertProp(entry.prop)
    end

    self.monsters = {
        classes.char.new('slime', 'slime', 10, 14),
        classes.char.new('slime', 'slime', 15, 10),
        classes.char.new('slime', 'slime', 20, 22),
        classes.char.new('spider', 'spider', 28, 13),
    }
    --self.monsters = {}
    for k, entry in ipairs(self.monsters) do
        self.layer:insertProp(entry.prop)
    end

    self.hero = classes.char.new('Ross', 'hero', 30, 21)
    self.layer:insertProp(self.hero.prop)


end -- setup_world()
