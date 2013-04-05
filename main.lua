helpers = {}    -- Basic helper functions library
helpers.math = require 'lib/helpers/math'  -- math function
helpers.string = require 'lib/helpers/string' -- string function
helpers.table = require 'lib/helpers/table' -- table functions
helpers.json = require 'lib/helpers/json'           -- JSON tools

lib = {}
lib.sounds = require 'lib/sound_manager'    -- Sound effects / Music manager
lib.assload = require 'lib/asset_loader'    -- Load external data files

classes = {}
classes.rect = require 'classes/rect'       -- Rectangle class
classes.map = require 'classes/map'         -- Map class
classes.objects = require 'classes/objects' -- Objects (set) class
classes.char = require 'classes/character'  -- Character class
classes.item = require 'classes/item'       -- Item/object class


function pick_viewport(viewports, x, y)
    --[[ Returns the name of the viewport under the given (x, y) position.
    viewports is a table of viewport objects, which must have a .rect
    attribute. (x, y) coords are in screen units. --]]
    for k, vp in pairs(viewports) do
        if vp.rect:collide_point(x, y) then
            return vp.name
        end
    end
    return nil
end

function pick_hotspot(hotspots, x, y)
    --[[ Given a table of hotspots, returns the hotspot name (which is the
    table key) for the hotspot under the (x, y) coordinate. Returns nil if
    there is no hotspot under that point.--]]
    for key, hotspot in pairs(hotspots) do
        if hotspot:collide_point(x, y) then
            return key
        end
    end
    return nil
end

function set_cont_hotspots(vp_rect)
    --[[ Generate a table of hotspots. Hotspots are simply Rectangles
    (should also allow for circles, or whatever). The hotspots table
    key (e.g. '.up' or '.select') is the hotspot name.
    vp_rect argument is the dimensions of the viewport containing the
    hotspots, which can be useful if dealing with offsets.--]]

    -- unused, but could be used to determine offsets
    local left, top, right, bottom = vp_rect:get_edges()
    local hotspots = {}
    -- left, top, right, bottom
    local up = classes.rect.Rectangle.new(77, 528, 110, 562)
    local dn = classes.rect.Rectangle.new(77, 594, 110, 626)
    local lf = classes.rect.Rectangle.new(45, 561, 77, 594)
    local rt = classes.rect.Rectangle.new(110, 562, 143, 594)
    local selec = classes.rect.Rectangle.new(180, 573, 242, 611)
    local start = classes.rect.Rectangle.new(241, 570, 308, 610)
    local B = classes.rect.Rectangle.new(338, 552, 396, 612)
    local A = classes.rect.Rectangle.new(405, 552, 462, 612)

    hotspots.up = up
    hotspots.down = dn
    hotspots.left = lf
    hotspots.right = rt
    hotspots.B = B
    hotspots.A = A
    hotspots.select = selec
    hotspots.start = start

    return hotspots
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
    camera = MOAICamera2D.new()

    -- Set up map viewport
    local map_rect = classes.rect.Rectangle.new(0, 0, screen_width, map_height)
    map_viewport = MOAIViewport.new()
    map_viewport:setSize( map_rect:get_edges() )
    map_viewport:setScale(scale_width, scale_height)
    map_viewport.rect = map_rect
    map_viewport.name = 'map'

    -- Build map layer
    map = classes.map.Map.new('World')
    map:load_level(map_viewport, 'maps/world.json')
    map.layer:setCamera(camera)
    MOAIRenderMgr.pushRenderPass(map.layer)
   
    -- Build objects/entities layer
    objects = classes.objects.Objects.new('World')
    objects:load_level(map_viewport, 'maps/world.json')
    objects.layer:setCamera(camera)
    MOAIRenderMgr.pushRenderPass(objects.layer)

    -- Set up controls viewport
    local cont_rect = classes.rect.Rectangle.new(0, map_height, screen_width,
                                   map_height + cont_height)
    cont_viewport = MOAIViewport.new()
    cont_viewport:setSize( cont_rect:get_edges() )
    cont_viewport:setScale( screen_width, cont_height )
    cont_viewport.rect = cont_rect
    cont_viewport.name = 'controller'

    cont_hotspots = set_cont_hotspots(cont_viewport.rect)

    -- Viewports container table
    viewports = { map_viewport, cont_viewport }

    -- Build controls layer
    cont_layer = load_controller(cont_viewport)
    MOAIRenderMgr.pushRenderPass(cont_layer)

    -- Set clear color (crashes certain setups?)
    MOAIGfxDevice.setClearColor(1, 0.41, 0.70, 1)
end -- setup_screen()


function load_controller(controls_viewport)
    -- Create our controller layer with prop
    -- TODO: Also set our hotpots here
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


function coords_rect(obj)
    --[[ Return coordinates as (x, y) for all 4 corners of a horizontally
    aligned rectangle. Objects needs a getLoc() method, plus width &
    height values. --]]
    local X, Y = obj.prop:getLoc()    -- object's center
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
    --[[ Find out if two rectangles are intersecting. Corner 1 is top-left,
    then count clockwise. --]]
    local a_x1, a_y1, a_x2, a_y2, a_x3, a_y3, a_x4, a_y4 = coords_rect(obj_a)
    local b_x1, b_y1, b_x2, b_y2, b_x3, b_y3, b_x4, b_y4 = coords_rect(obj_b)
    
    if a_x3 > b_x1 and a_x1 < b_x3 then -- Check X collision first
        if a_y3 > b_y1 and a_y1 < b_y3 then -- Check Y collision second
            return true
        end 
    end
    return false
end -- collide_rect(obj1, obj2)


function calc_hit(attack, defend)
    --[[ Given agilities of attacker and defender, calculate whether
    the attack was a hit or a miss. --]]

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
    --[[ Given strength and defence values, calculate the actual hit
    damage, and return it. --]]

    -- 20 % variability on strength & defence
    local str = strength + strength * (math.random()*2-1) * 0.2
    local def = defence + defence * (math.random()*2-1) * 0.2

    -- Scale damage by % difference with defence
    local damage = str + str * (str - def) / def
    -- Up to 25 % bonus on damage
    damage = helpers.math.round(damage + damage * math.random() * 0.25, 2)
    if damage > 0 then
        return damage
    else
        return 0
    end
end -- calc_damage(strength, defence)


function attack(attacker, defender)
    --[[ Attack function. Given an attacker and a defender, calculate
    hit probably, then calculate damage, finally calculate new health.
    Play appropriate sounds and return messages. --]]

    if calc_hit(attacker.attribs.agility, defender.attribs.agility) then
        io.write(helpers.string.firstToUpper(attacker.name).." hit! ")
        local damage = calc_damage(attacker.attribs.strength,
                                   defender.attribs.defence)
        if damage then
            lib.sounds.play_sound('clang')
            print(helpers.string.firstToUpper(defender.name)..
                  " lost "..damage.." health!")
            defender.attribs.health = defender.attribs.health - damage
        else
            lib.sounds.play_sound('clunk')
            print(helpers.string.firstToUpper(defender.name).."blocked!")
        end
    else
        lib.sounds.play_sound('swish')
        print(helpers.string.firstToUpper(attacker.name).." missed!")
    end
    return defender.attribs['health']
end -- attack(attacker, defender)



function track_pointer(x, y)
    --[[ Mouse pointer callback. --]]
    mouseX, mouseY = x, y
end

function left_mouse(down)
    --[[ Mouse left button callback. If click is down, set key_down
    to hotspot name. If key is up, set key_down = '' --]]

    if down then
        local x, y  = MOAIInputMgr.device.pointer:getLoc()
        local X, Y = objects.layer:wndToWorld(x, y)

        local vp_name = pick_viewport(viewports, x, y)
        if vp_name == 'map' then
            --[[if hero:isMoving() then
                objects.hero:stop()
            end
            objects.hero:move(X, Y) --]]
        elseif vp_name == 'controller' then
            hotspot = pick_hotspot(cont_hotspots, x, y)
            if helpers.table.is_in(hotspot,
                {'up', 'down', 'left', 'right'}) then
                key_down = hotspot
                print('key_down: ', key_down)
                if not objects.hero.is_moving then
                    objects.hero:move_cell(key_down)
                end
            elseif hotspot == 'start' then
                os.exit(0)
            else
                print ("Controller: "..(hotspot or 'nil'))
            end
        end
    else
        key_down = ''
        print('key_down: ', key_down)
    end
    return key_down
end

function handle_keyboard(key, down)
    --[[ Keyboard callback function. Sets key_down to appropriate direction,
    for movement. Other stuff not implemented, other than os.exit(0)! --]]

    if not down then 
        key_down = ''
        return key_down
    end

    if key == 65 or key == 97 then      -- a (left)
        key_down = 'left'
    elseif key == 68 or key == 100 then -- d (right)
        key_down = 'right'
    elseif key == 73 or key == 105 then -- i (inventory)
        print("Inventory")
        key_down = 'i'
    elseif key == 80 or key == 112 then -- p (pause)
        print("Pause")
        key_down = 'p'
    elseif key == 81 or key == 113 then -- q (quit)
        os.exit(0)
        key_down = 'q'
    elseif key == 83 or key == 115 then -- s (down)
        key_down = 'down'
    elseif key == 87 or key == 119 then -- w (up)
        key_down = 'up'
    elseif key == 27 then               -- Esc (quit)
        os.exit(0)
        key_down = 'esc'
    elseif key == 32 then               -- Space (attack)
        print("Attack")
        key_down = 'space'
    else
        print("Key pressed: "..string.char(tostring(key)), key)
        key_down = ''
    end
    return key_down
end


function game_loop ()
    local frames = 0

    if MOAIInputMgr.device.keyboard then
        MOAIInputMgr.device.keyboard:setCallback(handle_keyboard)
    else
        print("No keyboard found.")
    end

    MOAIInputMgr.device.pointer:setCallback(track_pointer)
    MOAIInputMgr.device.mouseLeft:setCallback(left_mouse)

    key_down = ''
    while not game_over do
        camera:seekLoc(objects.hero.prop:getLoc())
        coroutine.yield ()
        frames = frames + 1
        if frames == 45 then
            frames = 0
            for i, monster in ipairs(objects.monsters) do
                monster:random_move()
            end
        end
        if helpers.table.is_in(key_down, {'up', 'down', 'left', 'right'}) then
            objects.hero:move_cell(key_down)
        end
        for i, monster in ipairs (objects.monsters) do
            if collide_rect(monster, objects.hero) then
                if objects.hero:isMoving() then
                    objects.hero.move_action:stop()
                    attack(objects.hero, monster)
                    monster:rebound()
                else
                    attack(monster, objects.hero)
                    objects.hero:rebound()
                end
                if objects.hero.attribs.health <= 0 then
                    print("You died! Game over.")
                    objects.layer:removeProp(objects.hero.prop)
                    lib.sounds.play_sound('kill')
                    game_over = true
                    break
                elseif monster.attribs.health <= 0 then
                    print('You killed the '..monster.name..'!')
                    objects.layer:removeProp(monster.prop)
                    lib.sounds.play_sound('kill')
                    table.remove(objects.monsters, i)
                    break
                end
            end
        end 
        for i, item in ipairs(objects.items) do
            if collide_rect(item, objects.hero) then
                print("You found a sword!")
                objects.layer:removeProp(item.prop)
                table.remove(objects.items, i)
                lib.sounds.play_sound('pickup_metal')
                break
            end
        end
        objects.hero:set_last_loc()
    end -- while not gameOver
end -- game_loop()


function main()
    --[[ Run the game ]]--
    print('----------------------------')
    print('-=        ANCESTORS       =-')
    print('----------------------------')

    game_over = false

    print("Setting up screen...")
    setup_screen ()

    print("Loading sounds...")
    lib.sounds.setup_sound()

    print("done.\n Welcome to Ancestors.")

    mainThread = MOAICoroutine.new ()
    mainThread:run ( game_loop )
    
end -- main()

main() -- Run program
