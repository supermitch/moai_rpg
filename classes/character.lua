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
end

function Character:set_speed(direction)
    if direction == 'n' then
        self.v_x, self.v_y = 0, self.attribs.speed
    elseif direction == 'e' then
        self.v_x, self.v_y = self.attribs.speed, 0
    elseif direction == 's' then
        self.v_x, self.v_y = 0, -self.attribs.speed
    elseif direction == 'w' then
        self.v_x, self.v_y = -self.attribs.speed, 0
    else
        self.v_x, self.v_y = 0, 0
    end
    return self.v_x, self.v_y
end

function Character:move()
    --[[ Move the prop according to speed attribute ]]
    cur_x, cur_y = self.prop:getLoc()
    new_x, new_y = cur_x + self.v_x/60, cur_y + self.v_y/60
    self.prop:setLoc(new_x, new_y)
    self.i, self.j = self:get_cell()
end

function Character:load_attribs()
    --[[ Load attributes into self.attribs ]]
    humans = lib.assload.read('objects/humans/', 'json')
    monsters = lib.assload.read('objects/monsters/', 'json')
    -- Try one, if nil, try the other. TODO: Bug if kinds are not unique!
    self.attribs = humans[self.kind] or monsters[self.kind]
end

-- MOVEMENT COMPONENTS --
-- TODO: Move outside!

function Character:update()
    --[[ We'd like to call update once per frame. ]]
    if self:is_moving() then
        self:check_destination()
    end
    self:move()
end

function Character:check_destination()
    --[[ A prop method for seeking an (X, Y) world unit location. --]]
    local X, Y = self.prop:getLoc() -- world coords
    if self.v_y > 0 and Y >= self.destination.y then
        self:stop()
    elseif self.v_x > 0 and X >= self.destination.x then
        self:stop()
    elseif self.v_y < 0 and Y <= self.destination.y then
        self:stop()
    elseif self.v_x < 0 and X <= self.destination.x then
        self:stop()
    end
end -- check_destination()

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
    --[[ Move the character by a map tile, along the grid. ]]
    local i, j = self:get_cell() 
    local next_i, next_j = i, j
    if direction == 'n' then
        next_i = i - 1
    elseif direction == 's' then
        next_i = i + 1
    elseif direction == 'w' then
        next_j = j - 1
    elseif direction == 'e' then
        next_j = j + 1
    else
        direction = nil
    end
    if direction ~= nil then self.orientation = direction end

    local tile = map.grid[next_i][next_j]
    if tile.walkable then
        if not self:is_moving() then
            local dest_x, dest_y = map:idx_to_coords(next_i, next_j)
            self.destination = { x=dest_x, y=dest_y }
            self:set_speed(self.orientation)
        end
    else
        print('not walkable at: ['..next_i..']['..next_j..']')
        lib.sounds.play_sound('blip')
    end
end

function Character:is_moving()
    --[[ Return true if object has velocity. ]]
    if self.v_x ~= 0 or self.v_y ~= 0 then
        return true
    else
        return false
    end
end

function Character:stop()
    --[[ Shortcut, sets object's velocity to zero. ]]
    self.v_x, self.v_y = 0, 0
end

function Character:random_move()
    --[[ Perform the next move in our path list ]]
    if self.path and # self.path > 0 then -- Some moves remain
        if self:is_moving() then
            -- do nothing, it's already happening!
        else
            local move = table.remove(self.path, 1) -- pop last item
            local X, Y = map:idx_to_coords(move[1], move[2])
            local direction = move[3]
            self.destination = { x=X, y=Y }
            self:cell_move(direction)
        end
    else    -- We have no more moves in our path
        if not self:is_moving() and not self:is_resting() then
            self.path = self:plan_moves()   -- fill out path with new moves
        end
    end
end
    
function Character:plan_moves()
    local cur_i, cur_j = self:get_cell()
    local path = {}
    local moves_remaining = self.attribs.move_distance
    local attempts = 0  -- if character gets stuck
    while moves_remaining > 0 and attempts < 20 do
        attempts = attempts + 1
        local dir = math.random(1,4)
        local di, dj = 0, 0
        if dir == 1 then di = 1
        elseif dir == 2 then di = -1
        elseif dir == 3 then dj = 1
        elseif dir == 4 then dj = -1
        end
        local direction = {'n', 'e', 's', 'w'}
        local next_i, next_j = (cur_i + di), (cur_j + dj)
        if map.grid[next_i] ~= nil and map.grid[next_i][next_j] ~= nil
        and map.grid[next_i][next_j].walkable then
            table.insert(path, { next_i, next_j, direction[dir] })
            moves_remaining = moves_remaining - 1
            cur_i, cur_j = next_i, next_j
        end
    end
    return path
end -- Character:random_move()

function Character:is_resting()
    --[[ Returns true if not enough time has passed since our last movement ]]
    last_move = self.last_move_time or 0
    if self.attribs.rest == nil then self.attribs.rest = 0 end
    if MOAISim.getElapsedTime() - last_move < self.attribs.rest then
        return true -- resting
    else
        return false -- no longer resting
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



