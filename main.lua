mh = require 'lib/helpers/math_helper'      -- helper math module
sh = require 'lib/helpers/string_helper'    -- helper string module
sm = require 'lib/sound_mgr'                -- sound effects manager
rect = require 'lib/rect'                   -- Rectangle class

function pick_viewport(viewports, x, y)
    for k, vp in pairs(viewports) do
        if vp.rect:collide_point(x, y) then
            return vp.name
        end
    end
end

function setup_screen ()
    -- Set up viewports, layers, maps, etc

    print("Starting up on: [" .. MOAIEnvironment.osBrand .."]")

    screen_width = 512
    map_height = 512
    cont_height = 128

    screen_width = MOAIEnvironment.horizontalResolution or screen_width
    screen_height = MOAIEnvironment.verticalResolution or
                    (map_height + cont_height)

    scale_width = 16
    scale_height = math.floor(scale_width * map_height / screen_width)
    print("W:"..scale_width.." H:"..scale_height)

    MOAISim.openWindow("Ancestors", screen_width, screen_height)

    -- Set up map viewport
    local map_rect = rect.Rectangle.new(0, 0, screen_width, map_height)
    map_viewport = MOAIViewport.new()
    map_viewport:setSize( map_rect:get_edges() )
    map_viewport:setScale(scale_width, scale_height)
    map_viewport.rect = map_rect
    map_viewport.name = 'map'

        -- Build map layer
    map_table = build_map_table()   -- Lightweight map array
    map_layer = load_map(map_viewport)
    MOAIRenderMgr.pushRenderPass(map_layer)

        -- Build character layer
    char_layer = MOAILayer2D.new()
    char_layer:setViewport(map_viewport)
    MOAIRenderMgr.pushRenderPass(char_layer)
    
    -- Set up controls viewport
    local cont_rect = rect.Rectangle.new(0, map_height, screen_width,
                                   map_height + cont_height)
    cont_viewport = MOAIViewport.new()
    cont_viewport:setSize( cont_rect:get_edges() )
    cont_viewport:setScale( screen_width, cont_height )
    cont_viewport.rect = cont_rect
    cont_viewport.name = 'controller'

    viewports = { map_viewport, cont_viewport }

    cont_layer = load_controller(cont_viewport)
    MOAIRenderMgr.pushRenderPass(cont_layer)

    MOAIGfxDevice.setClearColor(1, 0.41, 0.70, 1)

end -- setup_screen()


function build_map_table()

    map_table = {}

    function map_table:insert_entry(map_prop, i, j)
        local entry = {}

        entry.name = map_prop.name
        entry.X, entry.Y = map_prop:getLoc()
        entry.walkable = map_prop.walkable
        entry.width = 1
        entry.height = 1

        function entry:getLoc()
            return self.X, self. Y
        end

        if self[i] == nil then self[i] = {} end -- Ensure row exists first
        self[i][j] = entry
        return nil
    end

    function map_table:get_coords(X, Y)
        cur_min = math.huge
        for i, row in ipairs(self) do
            for j, entry in ipairs(row) do
                local dist = mh.distance(X, Y, entry:getLoc())
                if dist < cur_min then
                    cur_min = dist
                    cur_coords_i = i
                    cur_coords_j = j
                end
            end
        end
        return cur_coords_i, cur_coords_j
    end

    function map_table:get_entry(X, Y)
        i, j = self:get_coords(X, Y)
        if i == nil or j == nil then return nil end
        return self[i][j]
    end

    return map_table
end

function load_controller(controls_viewport)

    local ui = MOAIGfxQuad2D.new()
    ui:setTexture("images/ui/controller.png")
    ui:setRect(-256, -64, 256, 64)

    local ui_prop = MOAIProp2D.new()
    ui_prop:setDeck(ui)
    ui_prop:setLoc(0, 0)

    local control_layer = MOAILayer2D.new()
    control_layer:setViewport(controls_viewport)
    control_layer:insertProp(ui_prop)

    return control_layer
end


function load_map(map_viewport)
    --[[ Generate a map layer containing all terrain props ]]--

    map_layer = MOAILayer2D.new()
    map_layer:setViewport(map_viewport)

    local grass = MOAIGfxQuad2D.new()
    grass:setTexture("images/maps/grass_1.png")
    grass:setRect(-0.5, -0.5, 0.5, 0.5)

    local sand = MOAIGfxQuad2D.new()
    sand:setTexture("images/maps/sand_1.png")
    sand:setRect(-0.5, -0.5, 0.5, 0.5)

    local grass_rock = MOAIGfxQuad2D.new()
    grass_rock:setTexture("images/maps/rock_1.png")
    grass_rock:setRect(-0.5, -0.5, 0.5, 0.5)

    local sand_rock = MOAIGfxQuad2D.new()
    sand_rock:setTexture("images/maps/rock_2.png")
    sand_rock:setRect(-0.5, -0.5, 0.5, 0.5)

    map = {{4,2,2,2,2,1,1,1,1,1,1,1,1,1,1,1}
          ,{2,2,2,2,1,1,1,1,1,1,1,1,1,1,2,2}
          ,{2,2,2,2,1,1,1,1,1,1,1,1,1,2,2,2}
          ,{2,2,2,2,2,2,1,1,1,1,1,1,2,2,2,2}
          ,{1,2,2,2,2,2,1,1,3,1,1,1,2,2,2,4}
          ,{1,2,2,2,2,2,1,1,1,1,1,1,2,2,4,4}
          ,{1,1,2,2,2,2,2,1,1,1,1,2,2,4,4,4}
          ,{2,1,2,1,2,1,2,1,2,1,2,1,2,4,4,4}
          ,{1,1,2,2,2,2,2,1,1,1,1,2,2,4,2,4}
          ,{1,1,1,2,2,1,1,1,1,1,1,1,1,2,2,2}
          ,{1,1,1,1,1,1,3,1,3,1,1,1,2,2,2,2}
          ,{1,1,1,1,1,3,3,1,1,1,1,1,2,2,2,2}
          ,{1,1,1,1,1,1,1,1,1,1,1,1,2,2,2,2}
          ,{1,1,1,1,1,1,1,1,1,1,1,1,2,2,2,2}
          ,{3,1,1,1,1,1,1,1,1,1,1,2,2,2,2,2}
          ,{3,3,1,1,1,1,1,1,1,1,1,1,1,1,2,2}}

    for i, row in pairs(map) do
        for j, value in pairs(row) do
            local map_prop = MOAIProp2D.new()
            if value == 1 then
                map_prop:setDeck(grass)
                map_prop.name = 'grass'
            elseif value == 2 then
                map_prop:setDeck(sand)
                map_prop.name = 'sand'
            elseif value == 3 then
                map_prop:setDeck(grass_rock)
                map_prop.name = 'grass_rock'
                map_prop.walkable = false
            elseif value == 4 then
                map_prop:setDeck(sand_rock)
                map_prop.name = 'sand_rock'
                map_prop.walkable = false
            else
                error("Invalid map value at ("..i..","..j..") = "..value)
                map_prop:setDeck(grass)
            end
            if map_prop.walkable == nil then
                map_prop.walkable = true
            end
            map_prop:setLoc((j-1-scale_width/2), (scale_height/2-(i-1)))
            map_layer:insertProp(map_prop)
            
            map_table:insert_entry(map_prop, i, j)
        end
    end
    
    function map_layer:get_prop(X, Y)
        local partition = self:getPartition()
        return partition:propForPoint(X, Y, 0)
    end 

    return map_layer
end -- load_map()

function coords_rect(obj)
    --[[ Return coordinates as (x, y) for all 4 corners of a horizontally
    aligned rectangle. Objects needs a getLoc() method, plus width &
    height values. ]]--
    local X, Y = obj:getLoc()    -- object's center
    local x1 = X - obj.width / 2
    local x2 = X + obj.width / 2
    local x3 = x2
    local x4 = x1
    local y1 = Y - obj.height / 2
    local y2 = y1
    local y3 = Y + obj.height / 2
    local y4 = y3
    return x1, y1, x2, y2, x3, y3, x4, y4
end -- coords_rect(obj)

function collide_rect(obj_a, obj_b)
    --[[ Find out if two rectangles are intersecting. ]]--
    local a_x1, a_y1, a_x2, a_y2, a_x3, a_y3, a_x4, a_y4 = coords_rect(obj_a)
    local b_x1, b_y1, b_x2, b_y2, b_x3, b_y3, b_x4, b_y4 = coords_rect(obj_b)
    
    if a_x3 >= b_x1 and a_x1 <= b_x3 then -- Check X collision first
        if a_y3 >= b_y1 and a_y1 <= b_y3 then -- Check Y collision second
            return true
        end 
    end
    return false
end -- collide_rect(obj1, obj2)


function calc_hit(attack, defend)
    --[[ Given agilities of attacker and defender, calculate whether
    the attack was a hit or a miss. ]]--

    -- Calculate probability of contact based on agility
    -- Agility from 0 to 100 pts +/- 20 % random adjustment
    local atk_agil = attack + attack * (math.random()*2-1) * 0.2
    local def_agil = defend + defend * (math.random()*2-1) * 0.2
    
    local strike_percent = 75 + (atk_agil - 10) - (def_agil - 10)

    local strike_roll = math.random()*100
    if strike_roll <= strike_percent then
        return true
    else
        return false
    end
end -- calc_hit(attack, defend)


function calc_damage(strength, defence)
    -- 20 % variability on strength & defence
    local str = strength + strength * (math.random()*2-1) * 0.2
    local def = defence + defence * (math.random()*2-1) * 0.2

    -- Scale damage by % difference with defence
    local damage = str + str * (str - def) / def
    -- Up to 25 % bonus on damage
    damage = mh.round(damage + damage * math.random() * 0.25, 2)
    if damage > 0 then
        return damage
    else
        return 0
    end
end -- calc_damage(strength, defence)


function attack(attacker, defender)

    if calc_hit(attacker.attribs.agility, defender.attribs.agility) then
        io.write(sh.firstToUpper(attacker.name).." hit! ")
        local damage = calc_damage(attacker.attribs.strength,
                                   defender.attribs.defence)
        if damage then
            sm.play_sound('clang')
            print(sh.firstToUpper(defender.name).." lost "..damage.." health!")
            defender.attribs.health = defender.attribs.health - damage
        else
            sm.play_sound('clunk')
            print(sh.firstToUpper(defender.name).."blocked!")
        end
    else
        sm.play_sound('swish')
        print(sh.firstToUpper(attacker.name).." missed!")
    end
    return defender.attribs['health']
end -- attack(attacker, defender)


function seek_location(self, x, y)
    --[[ A prop method for seeking an (x,y) location. ]]--
    local X_cur, Y_cur = self:getLoc()
    local X, Y = char_layer:wndToWorld( x, y )
    local distance = mh.distance(X, Y, X_cur, Y_cur)
    if distance <= 0 then return nil end
    local time = distance / self.attribs.speed
    self.dir_x = (X - X_cur) / distance -- X unit vector component
    self.dir_y = (Y - Y_cur) / distance -- Y unit vector component

    function thread_func()
        self.move_action = self:seekLoc( X, Y, time, MOAIEaseType.LINEAR )
        MOAICoroutine.blockOnAction ( self.move_action )
    end
    self.thread = MOAICoroutine.new()
    self.thread:run( thread_func )
end -- seek_location(x, y)


function rebound(self)
    --[[ Bounce backwards from current direction vector. ]]--
    local X_cur, Y_cur = self:getLoc()
    local X_new = X_cur - self.dir_x * 0.5  -- rebound by 1/2 world units
    local Y_new = Y_cur - self.dir_y * 0.5
    self:setLoc(X_new, Y_new)
end -- rebound(self)


function re_move(self)
    --[[ Put into last known good location. ]]--
    self:setLoc( self:get_last_loc() )
end -- re_move(self)


function get_last_loc(self)
    return self.last_X, self.last_Y
end -- get_last_loc()


function set_last_loc(self)
    self.last_X, self.last_Y = self:getLoc()
    return nil
end -- set_last_loc(self)


function make_dude(X, Y, name)
    -- Main character render --
    local texture = MOAITexture.new()
    texture:load( 'images/chars/dude_1.png' )
    local w, h = texture:getSize()
    local sprite = MOAIGfxQuad2D.new()
    sprite:setTexture( texture )
    sprite:setRect(-w/32, -h/32, w/32, h/32) --i.e. (w/2) / (16 px/world unit)

    dude = MOAIProp2D.new()
    dude:setDeck(sprite)
    dude:setLoc(X, Y)
    dude.width = 1
    dude.height = 1
    dude.dir_x = 0
    dude.dir_y = 0
    dude.name = name

    local attrib_table = {}
    attrib_table = { speed = 3
        , move_distance = 0 
        , health = 20
        , strength = 5
        , defence = 6
        , agility = 3 }
    dude.attribs = attrib_table

    -- Prop Methods --
    dude.move = seek_location -- old method using seekLoc()
    dude.rebound = rebound
    dude.set_last_loc = set_last_loc
    dude.get_last_loc = get_last_loc
    dude.re_move = re_move

    function dude:isMoving()
        if self.move_action ~= nil and self.move_action:isBusy() then
            return true
        end
    end

    function dude:stop()
        if self:isMoving() then
            self.move_action:stop()
        end
    end

    char_layer:insertProp(dude)
    return dude

end -- function make_dude ()


function make_monster(X, Y, name)

    -- Slime character render --
    local texture = MOAITexture.new()
    texture:load( 'images/monsters/slime_1.png' )
    local w, h = texture:getSize()
    local sprite = MOAIGfxQuad2D.new()
    sprite:setTexture( texture )
    sprite:setRect(-w/32, -h/32, w/32, h/32) --i.e. (w/2) / (16 px/world unit)
    local prop = MOAIProp2D.new()
    prop:setDeck(sprite)
    prop:setLoc(X, Y)
    prop.width = 1
    prop.height = 1
    dude.dir_x = 0
    dude.dir_y = 0
    prop.name = name
    
    local attrib_table = { speed = 2
        , move_distance = 2
        , health = 10
        , strength = 2
        , defence = 5
        , agility = 1
    }
    prop.attribs = attrib_table

    -- Prop Methods --
    prop.move = seek_location
    prop.rebound = rebound
    prop.re_move = re_move
    prop.set_last_loc = set_last_loc

    function prop:random_move()
        local X_cur, Y_cur = self:getLoc()
        local dX = self.attribs['move_distance'] * (math.random() * 2 - 1)
        local dY = self.attribs['move_distance'] * (math.random() * 2 - 1)
        local x, y = char_layer:worldToWnd(X_cur + dX, Y_cur + dY)
        self:move (x, y)
    end -- prop:random_move()

    char_layer:insertProp(prop)
    return prop
    
end -- function make_slime ()


function make_item(X, Y, item_type)

    local texture = MOAITexture.new()
    texture:load( 'images/items/sword_1.png' )
    local w, h = texture:getSize()
    local sprite = MOAIGfxQuad2D.new()
    sprite:setTexture( texture )
    sprite:setRect(-w/32, -h/32, w/32, h/32) --i.e. (w/2) / (16 px/world unit)

    local prop = MOAIProp2D.new()
    prop:setDeck(sprite)
    prop:setLoc(X, Y)
    prop.item_type = item_type

    prop.width = 1
    prop.height = 1
    char_layer:insertProp(prop)

    return prop
    
end -- function make_slime ()

function setup_world ()
    --[[ Set up our items and characters in the world ]]--
    dude = make_dude(0, 0, 'Hero', 3)  -- Hero

    monsters = { 
        make_monster(5, 5, 'slime', 2)       -- Slime 1
        , make_monster(-3, -2, 'slime', 1.5)   -- Slime 2
        , make_monster(-1, 4, 'slime', 2.4)    -- Slime 3
    }

    items = {
        make_item(3, 0, 'sword')
    }
end -- setup_world()


function game_loop ()
    local frames = 0

    if MOAIInputMgr.device.keyboard then
        print("Keyboard found.")
        MOAIInputMgr.device.keyboard:setCallback (
            function (key, down)
                if down == true then
                    print("Key pressed: "..string.char(tostring(key)))
                end
            end
        )
    else
        print("No keyboard...")
    end

    while not game_over do
        coroutine.yield ()
        frames = frames + 1
        if frames == 45 then
            frames = 0
            for i, monster in ipairs(monsters) do
                monster:random_move()
            end
        end
        
        if MOAIInputMgr.device.mouseLeft:down () then
            local dest_x, dest_y  = MOAIInputMgr.device.pointer:getLoc()
            local dest_X, dest_Y = char_layer:wndToWorld(dest_x, dest_y)

            local vp_name = pick_viewport(viewports, dest_x, dest_y)
            if vp_name == 'map' then
                local entry = map_table:get_entry(dest_X, dest_Y)
                if entry.walkable then
                    print(entry.name, "walkable")
                else
                    print(entry.name, "blocked")
                    sm.play_sound('blip')
                end
                if dude:isMoving() then
                    dude.move_action:stop()
                end
                dude:move(dest_x, dest_y)
            elseif vp_name == 'controller' then
                print ("controller")
            end
        end
        for i, monster in ipairs (monsters) do
            if collide_rect(monster, dude) then
                if dude:isMoving() then
                    dude.move_action:stop()
                    attack(dude, monster)
                    monster:rebound()
                else
                    attack(monster, dude)
                    dude:rebound()
                end
                if dude.attribs.health <= 0 then
                    print("You died! Game over.")
                    char_layer:removeProp(dude)
                    sm.play_sound('kill')
                    game_over = true
                    break
                elseif monster.attribs.health <= 0 then
                    print('You killed the '..monster.name..'!')
                    char_layer:removeProp(monster)
                    sm.play_sound('kill')
                    table.remove(monsters, i)
                    break
                end
            end
        end 
        for i, item in ipairs(items) do
            if collide_rect(item, dude) then
                print("You found a sword!")
                char_layer:removeProp(item)
                table.remove(items, i)
                sm.play_sound('pickup_metal')
                break
            end
        end

        for i, row in ipairs(map_table) do
            for j, entry in ipairs(row) do
                if not entry.walkable then
                    if collide_rect(entry, dude) then
                        if dude:isMoving() then
                            dude:stop()
                            dude:re_move()
                        end
                        break
                    end
                end
            end
        end
        --x, y = dude:getLoc()           
        dude:set_last_loc()
        -- camera:setLoc(x, y, cam_z)
    end -- while not gameOver
    os.exit(0)
end -- game_loop()

function main()
    game_over = false
    print("Setting up screen...")
    setup_screen ()
    print("Loading sounds...")
    sm.setup_sound()
    print("Setting up world...")
    setup_world ()
    print("done.")

    print("Welcome to Ancestors.")
    mainThread = MOAICoroutine.new ()
    mainThread:run ( game_loop )
end -- main()

main() -- Run program
