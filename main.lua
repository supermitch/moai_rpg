helpers = {}    -- Basic helper functions library
helpers.math = require 'lib/helpers/math'       -- math function
helpers.string = require 'lib/helpers/string'   -- string function
helpers.table = require 'lib/helpers/table'     -- table functions
helpers.json = require 'lib/helpers/json'       -- JSON tools

lib = {}
lib.sounds = require 'lib/sound_manager'    -- Sound effects / Music manager
lib.assload = require 'lib/asset_loader'    -- Load external data files
lib.ui = require 'lib/ui'                   -- UI manager

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
    
    math.randomseed( os.time() )

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
    MOAISim.setStep (1 / 60)

-- MOAIDebugLines.setStyle(MOAIDebugLines.TEXT_BOX, 1, 1, 1, 1, 1)
-- MOAIDebugLines.setStyle(MOAIDebugLines.TEXT_BOX_LAYOUT, 1, 0, 0, 1, 1)
-- MOAIDebugLines.setStyle(MOAIDebugLines.TEXT_BOX_BASELINES, 1, 1, 0, 0, 1)


    camera = MOAICamera2D.new()
    ui_camera = MOAICamera2D.new()

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

    -- Set up text/UI viewport
    ui_vp = MOAIViewport.new()
    ui_vp:setSize(map_rect:get_edges() )
    ui_vp:setScale(screen_width, map_height)
    -- Set up text/UI layer
    ui_layer = MOAILayer2D.new()
    ui_layer:setViewport(ui_vp)
    MOAIRenderMgr.pushRenderPass(ui_layer)
    
    text_layer = MOAILayer2D.new()
    text_layer:setViewport(ui_vp)
    text_layer:setCamera(ui_camera)
    MOAIRenderMgr.pushRenderPass(text_layer)

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

    font = MOAIFont.new()
    charcodes = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz"..
                "0123456789 .,:;!?<>()[]{}|&/-+_~'`/"..'"'
    font:loadFromTTF('assets/fonts/candal.ttf', charcodes, 8, 163)
    font:setDefaultSize(8, 163)

    fps_box = lib.ui.corner_box('FPS', -250, 250, 150, 50)
    ui_layer:insertProp(fps_box)

end -- setup_screen()


function load_controller(controls_viewport)
    -- Create our controller layer with prop
    -- TODO: Also set our hotpots here
    local ui = MOAIGfxQuad2D.new()
    ui:setTexture("assets/images/ui/controller.png")
    ui:setRect(-256, -64, 256, 64)

    local ui_prop = MOAIProp2D.new()
    ui_prop:setDeck(ui)
    ui_prop:setLoc(0, 0)

    local control_layer = MOAILayer2D.new()
    control_layer:setViewport(controls_viewport)
    control_layer:insertProp(ui_prop)

    return control_layer
end

function update_fps(fps)
    fps_box:setString('fps: ' .. helpers.math.round(fps, 2) )
end

function show_points(x, y, value)
    local sign = ''
    local color = {0.7, 0, 0, 1}
    if value > 0 then -- Healing
        sign = '+'
        color = {0, 0.5, 0, 1}
    end
    box = lib.ui.center_box(sign..tostring(value), x, y+0.5, 50, 30)
    box:setColor(unpack(color))

    function box:launch ()
        self.thread = MOAIThread:new ()
        self.thread:run (
            function ()
    MOAIThread.blockOnAction(self:moveLoc(0,10,0,0.5,MOAIEaseType.SOFT_SMOOTH))
    text_layer:removeProp(self)
            end)
    end
    
    text_layer:insertProp(box)

    box:launch()
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
    local y1 = Y + obj.height / 2
    local y2 = y1
    local y3 = Y - obj.height / 2
    local y4 = y3
    --[[if obj.kind == 'hero' then
        print(X, Y)
        print('1', helpers.math.round(x1,2), helpers.math.round(y1,2))
        print('2', helpers.math.round(x2,2), helpers.math.round(y2,2))
        print('3', helpers.math.round(x3,2), helpers.math.round(y3,2))
        print('4', helpers.math.round(x4,2), helpers.math.round(y4,2))
    end]]
    return x1, y1, x2, y2, x3, y3, x4, y4
end -- coords_rect(obj)

function collide_rect(obj_a, obj_b)
    --[[ Find out if two rectangles are intersecting. Corner 1 is top-left,
    then move clockwise. --]]
    local a_x1, a_y1, a_x2, a_y2, a_x3, a_y3, a_x4, a_y4 = coords_rect(obj_a)
    local b_x1, b_y1, b_x2, b_y2, b_x3, b_y3, b_x4, b_y4 = coords_rect(obj_b)
    
    if a_x3 > b_x1 and a_x1 < b_x3 then -- Check X collision first
        if a_y3 < b_y1 and a_y1 > b_y3 then -- Check Y collision second
            --print('a', a_x1, a_y1, a_x3, a_y3)
            --print('b', b_x1, b_y1, b_x3, b_y3)
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
    damage = helpers.math.round(damage + damage * math.random() * 0.25, 0)
    if damage > 0 then
        return -1 * damage  -- negative
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
            local x, y = defender.prop:getLoc()
            show_points(x, y, damage)
                                 
            defender.attribs.health = defender.attribs.health + damage
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
    elseif key == 66 or key == 98 then  -- b (left)
        print('b')
        key_down = 'B'
        lib.ui.event_dispatch(key_down)
    elseif key == 68 or key == 100 then -- d (right)
        key_down = 'right'
    elseif key == 73 or key == 105 then -- i (inventory)
        print("Inventory")
        key_down = 'i'
    elseif key == 80 or key == 112 then -- p (pause)
        print("Pause")
        key_down = 'p'
        objects.hero:stop()
    elseif key == 81 or key == 113 then -- q (quit)
        os.exit(0)
        key_down = 'q'
    elseif key == 83 or key == 115 then -- s (down)
        key_down = 'down'
    elseif key == 84 or key == 116 then -- t (talk)
        key_down = 'talk'
        objects.hero:talk()
    elseif key == 86 or key == 118 then -- v (A button)
        print('v')
        key_down = 'v'
        lib.ui.event_dispatch(key_down)
    elseif key == 87 or key == 119 then -- w (up)
        key_down = 'up'
    elseif key == 27 then               -- Esc (quit)
        key_down = 'esc'
        lib.ui.event_dispatch(key_down)
    elseif key == 32 then               -- Space (attack)
        print("Attack")
        key_down = 'space'
    else
        print("Key pressed: "..string.char(tostring(key)), key)
        key_down = ''
    end
    return key_down
end

function collide_objects(obj1, obj2)

    local pusher, target = obj1, obj2   -- assume
    if obj1.attribs.strength < obj2.attribs.strength then
        pusher, target = obj2, obj1
    end

    if pusher:is_moving() and not target:is_moving() then
        if not pusher:push(target) then
            pusher:move_back()
        end
    elseif not pusher:is_moving() and target:is_moving() then
        target:move_back()
    end

    if pusher:is_moving() and target:is_moving() then
        if pusher.v_x * target.v_y ~= 0 then -- perpendicular
            -- Do something?
            -- pusher:push(target)
        elseif pusher.v_y * target.v_x ~= 0 then -- perpendicular
            -- Do something?
            -- pusher:push(target)
        else
            if not pusher:push(target) then
                pusher:move_back()
            end
        end
    end
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
        hero_X, hero_Y = objects.hero.prop:getLoc()
        camera:seekLoc(hero_X, hero_Y)
        ui_camera:seekLoc(hero_X * 32, hero_Y * 32)
        update_fps( MOAISim:getPerformance() )
        coroutine.yield ()

        objects.hero:update()

        for i, npc in ipairs(objects.humans) do
            if collide_rect(npc, objects.hero) then
                collide_objects(npc, objects.hero)
            end
            for j, monster in ipairs(objects.monsters) do
                if collide_rect(npc, monster) then
                    collide_objects(npc, monster)
                end
            end
            npc:update()
        end

        for i, monster in ipairs (objects.monsters) do

            if collide_rect(monster, objects.hero) then
                if objects.hero:is_moving() then
                    objects.hero:stop()
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
                    print('You killed the '.. monster.name ..'!')
                    objects.layer:removeProp(monster.prop)
                    lib.sounds.play_sound('kill')
                    table.remove(objects.monsters, i)
                    break
                end
            end
            monster:update()
        end

        for i, item in ipairs(objects.items) do
            if item.i == objects.hero.i and item.j == objects.hero.j then
                print('You found a '.. item.name ..'!')
                if item.kind == 'key' then
                    objects.hero.has_key = true
                end
                objects.layer:removeProp(item.prop)
                table.remove(objects.items, i)
                lib.sounds.play_sound('pickup_metal')
                break
            end
        end
   
        if helpers.table.is_in(key_down, {'up', 'right', 'down', 'left'}) then
            local direction = {up='n', right='e', down='s', left='w'}
            objects.hero:cell_move(direction[key_down])
        end

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
