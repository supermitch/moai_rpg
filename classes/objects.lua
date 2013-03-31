--[[ Objects/Entities class ]]

module(..., package.seeall)

Objects = {}
Objects.__index = Objects

function Objects.new(name)
    local objects = {}                  -- instance
    setmetatable(objects, Objects)
    objects.name = name or 'default'
    objects.hero = {}                   -- Init empty grid
    objects.npcs = {}
    objects.monsters= {}
    objects.items = {}
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
    
    local objects_array = helpers.json.read_json_file(level)

    self:load_objects(objects_array)    -- Objects and characters
end

function Objects:load_objects (objects_array)
    --[[ Set up our items, hero, monsters, etc, in the world.
    TODO: This should be a part of the objects making module. --]]

    print("loading objects..")
    self.hero = classes.char.new('Ross', 'hero')
    self.hero.prop:setLoc(map:idx_to_coords(8, 9))
    self.layer:insertProp(self.hero.prop)

    self.monsters = {
        classes.char.new('slime1', 'slime'),
        classes.char.new('slime2', 'slime'),
        classes.char.new('slime3', 'slime')
    }
    for k, entry in ipairs(self.monsters) do
        entry.prop:setLoc(map:idx_to_coords( math.random(2,12),
                                            math.random(2,17) ))
        self.layer:insertProp(entry.prop)
    end

    self.items = {
        classes.item.new('dull sword', 'sword')
    }
    for k, entry in ipairs(self.items) do
        entry.prop:setLoc(map:idx_to_coords(4, 7))
        self.layer:insertProp(entry.prop)
    end
end -- setup_world()
