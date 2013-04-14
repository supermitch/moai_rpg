--[[ Character class ]]

module(..., package.seeall)

Character = {}
Character.__index = Character

function new(name, kind, i, j)
    --[[ Instantiate our class and call loading methods ]]
    local character = Character.instantiate(name, kind)
    character:load_attribs()
    character:load_gfx()
    character.prop:setLoc(map:idx_to_coords(i, j))
    character.i, character.j = i, j
    return character
end

function Character.instantiate(name, kind)
    local character = {}                  -- instance
    setmetatable(character, Character)
    character.name = name
    character.kind = kind
    return character
end

function Character:load_gfx()
    --[[ Load sprite into map ]]
    local texture = MOAITexture.new()
    texture:load('images/'..self.attribs.type..'/'..
                 self.attribs.texture..'.png')
    local sprite = MOAIGfxQuad2D.new()
    sprite:setTexture(texture)
    local w, h = texture:getSize()
    sprite:setRect(-w/32, -h/32, w/32, h/32) -- (w/2) / (16 px/world unit)
    self.prop = MOAIProp2D.new()
    self.prop:setDeck(sprite)
    self.width, self.height = 1, 1
    self.v_x, self.v_y = 0, 0
    self.orientation = 'n'
    self.path = {}
end

function Character:load_attribs()
    --[[ Load attributes into self.attribs ]]
    humans = lib.assload.read('objects/humans/', 'json')
    monsters = lib.assload.read('objects/monsters/', 'json')
    -- Try one, if nil, try the other. TODO: Bug if kinds are not unique!
    self.attribs = humans[self.kind] or monsters[self.kind]
    self.moves_remaining = self.attribs.move_distance or 1
end

-- MOVEMENT COMPONENTS --
-- TODO: Move outside!

function Character:set_speed(dir)
    --[[ Set x and y speeds according to compass direction arg. ]]
    local spd = self.attribs.speed
    local speeds = { n={0,spd}, e={spd,0}, s={0,-spd}, w={-spd,0} }

    self.v_x = speeds[dir][1] or 0
    self.v_y = speeds[dir][2] or 0
end

function Character:update_position()
    --[[ Move the prop according to speed attribute. ]]
    cur_x, cur_y = self.prop:getLoc()
    new_x, new_y = cur_x + self.v_x/60, cur_y + self.v_y/60
    self.prop:setLoc(new_x, new_y)
    self.i, self.j = self:get_cell()
end

function Character:is_moving()
    --[[ Return true if object has velocity. ]]
    if self.v_x ~= 0 or self.v_y ~= 0 then
        return true
    else
        return false
    end
end

function Character:check_destination()
    --[[ A prop method for seeking an (X, Y) world unit location. --]]
    local X, Y = self.prop:getLoc() -- world coords
    if (self.v_y > 0 and Y >= self.destination.y) or
       (self.v_x > 0 and X >= self.destination.x) or
       (self.v_y < 0 and Y <= self.destination.y) or
       (self.v_x < 0 and X <= self.destination.x) then
        self:stop()
        self.last_move_time = MOAISim.getElapsedTime()
    end
end -- check_destination()

function Character:update()
    --[[ We'd like to call update once per frame. ]]
    if self:is_moving() then
        self:check_destination()
    end
    if self.moves_remaining <= 0 then
        self:rest()
    else
        self:move()
    end
    self:update_position()
end


function Character:stop()
    --[[ Shortcut, sets object's velocity to zero. ]]
    self.v_x, self.v_y = 0, 0
end

function Character:rebound()
    --[[ Bounce backwards from current direction vector. --]]
    local X, Y = self.prop:getLoc()
    local dir = { n={0,1}, e={1,0}, s={0,-1}, w={-1,0} }
    local new_X = X - dir[self.orientation][1] * 0.5
    local new_Y = Y - dir[self.orientation][2] * 0.5
    self.prop:setLoc(new_X, new_Y)
end -- rebound(self)

function Character:re_move()
    --[[ Move to last known good location. --]]
    self.prop:setLoc( self:get_last_loc() )
end -- re_move(self)

function Character:get_last_loc()
    --[[ Simply return last known location as an (X, Y) coord. --]]
    return self.last_X, self.last_Y
end -- get_last_loc()

function Character:set_last_loc()
    --[[ Save current location as last known good location. --]]
    self.last_X, self.last_Y = self.prop:getLoc()
end -- set_last_loc(self)

function Character:get_cell()
    --[[ Return objects's current (i, j) map coordinates ]]
    return map:coords_to_idx(self.prop:getLoc())
end

function Character:cell_move(direction)
    --[[ Add the cell in the given direction to the path. ]]
    if self.moves_remaining <= 0 or self:is_moving() then return false end

    local delta = { n={-1,0}, e={0,1}, s={1,0}, w={0,-1} } 
    local i, j = self:get_cell() 
    local next_i = i + (delta[direction][1] or 0)
    local next_j = j + (delta[direction][2] or 0)

    if map.grid[next_i] ~= nil and map.grid[next_i][next_j] ~= nil then
        if map.grid[next_i][next_j].walkable then
            self.path = { { next_i, next_j, direction } }
            return true
        else
            if self.kind == 'hero' then
                print('not walkable at: ['..next_i..']['..next_j..']')
                lib.sounds.play_sound('blip')
            end
            return false
        end
    end
end

function Character:random_move()
    --[[ Tries to add a random neighbouring cell to the move path.
    You need to have moves available in order to add a new one. ]]
    if self.moves_remaining <= 0 or self:is_moving() then return false end

    local i, j = self:get_cell()
    local attempts = 0
    while attempts < 10 do
        attempts = attempts + 1
        local direction = {'n', 'e', 's', 'w'}
        local dir = direction[math.random(1, 4)]
        local delta = { n={-1,0}, e={0,1}, s={1,0}, w={0,-1} } 
        local next_i, next_j = i + delta[dir][1], j + delta[dir][2]

        if map.grid[next_i] ~= nil and map.grid[next_i][next_j] ~= nil then
            if map.grid[next_i][next_j].walkable then
                self.path = { { next_i, next_j, dir } }
                return true
            end
        end
    end
end

function Character:move()
    --[[ Perform the next move in our path list. ]]
    if self:is_moving() then return nil end
    if self.path and # self.path > 0 then -- Some moves remain
        local move = table.remove(self.path, 1) -- pop last path item
        local i, j, direction = unpack(move)
        local X, Y = map:idx_to_coords(i, j)
        self.destination = { x=X, y=Y } -- set a destination
        self:set_speed(direction)       -- set velocity
        self.moves_remaining = self.moves_remaining - 1
    end
end
    
function Character:rest()
    --[[ Returns true if not enough time has passed since our last movement ]]
    if self.attribs.rest == nil or self.attribs.rest == 0 then
        self.moves_remaining = self.attribs.move_distance
        return false
    end
    local last_move = self.last_move_time or 0
    if MOAISim.getElapsedTime() - last_move < self.attribs.rest then
        return true     -- resting
    else
        self.moves_remaining = self.attribs.move_distance
        return false    -- refreshed!
    end
end


function Character:talk()
    --[[ Attempt to talk to whatever is facing your character, depending
    on last move direction. ]]
    local talking = false
    local cur_i, cur_j = self:get_cell() 
    local di, dj = map:compass_cell_offset(self.orientation)
    local new_i, new_j = cur_i + di, cur_j + dj
    for i, npc in ipairs(objects.humans) do
        local npc_i, npc_j = npc:get_cell()
        if npc_i == new_i and npc_j == new_j then    -- is our neighbour!
            print("Talking to ".. npc.name)
            talking = true
            talkbox:setString("Hi there!")
            ui_layer:insertProp(talkbox)
            break
        end
    end
    if not talking then
        print("(You're talking to yourself again...)")
    end
    return nil
end



