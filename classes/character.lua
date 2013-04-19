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
end

function Character:load_attribs()
    --[[ Load attributes into self.attribs ]]
    humans = lib.assload.read('objects/humans/', 'json')
    monsters = lib.assload.read('objects/monsters/', 'json')
    -- Try one, if nil, try the other. TODO: Bug if kinds are not unique!
    self.attribs = humans[self.kind] or monsters[self.kind]

    -- movement system:
    self.v_x, self.v_y = 0, 0
    self.orientation = 'n'
    self.path = {}
    self.moves_remaining = self.attribs.move_distance or 1

    -- other:
    self.talking = false
end

-- MOVEMENT COMPONENTS --
-- TODO: Move outside!

function Character:set_speed(dir, value)
    --[[ Set x and y speeds according to compass direction arg. ]]
    local spd = value or self.attribs.speed -- use value if provided!
    local speeds = { n={0,1}, e={1,0}, s={0,-1}, w={-1,0} }
    self.v_x = (speeds[dir][1] or 0) * spd
    self.v_y = (speeds[dir][2] or 0) * spd
    self.orientation = dir
end

function Character:update_position()
    --[[ Move the prop according to speed attribute. ]]
    local x, y = self.prop:getLoc()
    local dt = 1/60 -- time step, assuming 60 fps
    local dx, dy = self.v_x * dt, self.v_y * dt

    --[[ If we have a destination, we would rather not overshoot it
    so we only move the lesser of either dx (our intended step) or the 
    distance required to hit destination. ]]
    local gapx, gapy = dx, dy
    if self.destination and self.destination.x and self.destination.y then
        gapx, gapy = self.destination.x - x, self.destination.y - y
    end

    local sign = 1
    if dx < 0 or dy < 0 then
        sign = -1
    end
    dx = sign * math.min( math.abs(dx), math.abs(gapx) )
    dy = sign * math.min( math.abs(dy), math.abs(gapy) )
    local new_x, new_y = x + dx, y + dy
    self.prop:setLoc(new_x, new_y)
    self.i, self.j = self:get_cell()
end

function Character:is_moving()
    --[[ Return true if object has non-zero x or y velocity. ]]
    if self.v_x ~= 0 or self.v_y ~= 0 then
        return true
    end
    return false
end

function Character:check_destination()
    --[[ A prop method for seeking an (X, Y) world unit location. --]]
    if self:is_moving() then
        local X, Y = self.prop:getLoc() -- world coords
        if (self.v_y > 0 and Y >= self.destination.y) or
           (self.v_x > 0 and X >= self.destination.x) or
           (self.v_y < 0 and Y <= self.destination.y) or
           (self.v_x < 0 and X <= self.destination.x) then
           return true
        end
    end
    return false
end -- check_destination()

function Character:stop()
    --[[ Shortcut, sets object's velocity to zero. ]]
    self.v_x, self.v_y = 0, 0
    self.destination.x, self.destination.y = nil, nil
    self.last_move_time = MOAISim.getElapsedTime()
end

function Character:update()
    --[[ We'd like to call update once per frame. ]]
    if self:check_destination() then
        self:stop()
    end
    if self.moves_remaining <= 0 then
        self:rest()
    else
        self:move()
    end
    self:update_position()
end

function Character:rebound()
    --[[ Bounce backwards from current direction vector. --]]
    local X, Y = self.prop:getLoc()
    -- Use the cell offset as a shortcut to getting direction vector
    local di, dj = map:compass_cell_offset(self.orientation)
    local new_X = X - di 
    local new_Y = Y - dj
    self.prop:setLoc(new_X, new_Y)
end -- rebound(self)

function Character:push(target)

    print('pushing...')
    target:stop()

    -- Find out where we were headed, which is where target IS
    local dest_x, dest_y = self.destination.x, self.destination.y
    local dest_i, dest_j = map:coords_to_idx(dest_x, dest_y)
    -- Find the cell in the same direction as us
    local di, dj = map:compass_cell_offset(self.orientation)
    local next_i, next_j = dest_i + di, dest_j + dj
    local push_X, push_Y = map:idx_to_coords(next_i, next_j)
    print(push_X, push_Y)
    print(target.prop:getLoc())
    print(push_X, push_Y)

    target.moves_remaining = 0
    target.destination = { x=push_X, y=push_Y } -- set a destina
    -- set speed to just above ours. Push them out of the way!
    target:set_speed(self.orientation, self.attribs.speed * 1.2)
    
end

function Character:move_back()
    --[[ Bounce backwards from current direction vector. --]]
    local direction = map:compass_opposite(self.orientation)

    -- Find out where we were headed
    local dest_x, dest_y = self.destination.x, self.destination.y
    local dest_i, dest_j = map:coords_to_idx(dest_x, dest_y)
    -- Find the cell in the opposite direction (probably where we are now!)
    local di, dj = map:compass_cell_offset(direction)
    local next_i, next_j = dest_i + di, dest_j + dj

    if map.grid[next_i] ~= nil and map.grid[next_i][next_j] ~= nil then
        if map.grid[next_i][next_j].walkable then
            local X, Y = map:idx_to_coords(next_i, next_j)
            self:stop()
            self.destination = { x=X, y=Y } -- set a destination
            self:set_speed(direction)       -- set velocity

        else
            if self.kind == 'hero' then
                print('not walkable at: ['..next_i..']['..next_j..']')
                lib.sounds.play_sound('blip')
            end
            return false
        end
    end
    return nil
end -- rebound(self)

function Character:re_move()
    --[[ Move to last known good location. --]]
    self.prop:setLoc( self:get_last_loc() )
end -- re_move(self)

function Character:get_cell()
    --[[ Return objects's current (i, j) map coordinates ]]
    return map:coords_to_idx(self.prop:getLoc())
end

function Character:cell_move(direction)
    --[[ Add the cell in the given direction to the path. ]]
    if self.moves_remaining <= 0 or self:is_moving() then return false end

    local i, j = self:get_cell()    -- The cell we're in
    local di, dj = map:compass_cell_offset(direction)
    local next_i, next_j = i + di, j + dj

    if map:walkable(next_i, next_j) then
        self.path = { { next_i, next_j, direction } }
        return true
    else
        if self.kind == 'hero' then
            lib.sounds.play_sound('blip')
        end
    end
end

function Character:random_move()
    --[[ Tries to add a random neighbouring cell to the move path.
    You need to have moves available in order to add a new one. ]]
    local i, j = self:get_cell()
    local attempts = 0
    while attempts < 10 do
        attempts = attempts + 1
        local direction = {'n', 'e', 's', 'w'}
        local dir = direction[math.random(1, 4)]
        local di, dj = map:compass_cell_offset(dir)
        local next_i, next_j = i + di, j + dj
        if map:walkable(next_i, next_j) then
            return { next_i, next_j, dir }
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
    else
        if self.attribs.move_type == 'random' then
            self.path = { self:random_move() }
        end
    end
end
    
function Character:rest()
    --[[ Returns true if not enough time has passed since our last movement ]]
    if self.asleep then -- Rip Van Winkle
        return true
    end
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
    local i, j = self:get_cell() 
    local di, dj = map:compass_cell_offset(self.orientation)
    local next_i, next_j = i + di, j + dj   -- cell in front of us
    for i, npc in ipairs(objects.humans) do
        local npc_i, npc_j = npc:get_cell()
        if npc_i == next_i and npc_j == next_j then    -- is our neighbour!
            print("Talking to ".. npc.name)
            self.talking = true
            break
        end
    end
    if not self.talking then
        print("(You're talking to yourself again...)")
    else

            local gfxQuad = MOAIGfxQuad2D.new ()
            gfxQuad:setTexture("images/ui/textbox_main.png")
            gfxQuad:setRect(-220, -120, 220, -220)

            local prop = MOAIProp2D.new()
            prop:setDeck(gfxQuad)
            ui_layer:insertProp(prop)

            local box = add_textbox('', -210, -220, 210, -120)
            box:setString("Hi there!\nHow do textboxes work?\nFuck!?")
            ui_layer:insertProp(box)

    end
    return nil
end



