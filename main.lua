mh = require 'lib/math_helper'   -- import helper math module


function setup_screen ()
    -- Set up viewports, layers, maps, etc

    print("Starting up on: [" .. MOAIEnvironment.osBrand .."]")

    screenWidth = MOAIEnvironment.horizontalResolution or 640
    screenHeight = MOAIEnvironment.verticalResolution or 480

    scaleWidth = 16
    scaleHeight = math.floor(scaleWidth * screenHeight / screenWidth)
    print("W:"..scaleWidth.." H:"..scaleHeight)

    MOAISim.openWindow("Window", screenWidth, screenHeight)

    viewport = MOAIViewport.new()
    viewport:setSize(screenWidth, screenHeight)
    viewport:setScale(scaleWidth, scaleHeight)

    char_layer = MOAILayer2D.new()  -- Character layer
    char_layer:setViewport(viewport)

    map_layer = load_map()

    MOAIRenderMgr.pushRenderPass(map_layer)
    MOAIRenderMgr.pushRenderPass(char_layer)

    camera = MOAICamera.new ()
    cam_z = camera:getFocalLength( screenWidth )
    camera:setLoc(0, 0, cam_z)
    map_layer:setCamera(camera)

    MOAIGfxDevice.setClearColor(1, 0.41, 0.70, 1)

end -- setup_screen()

function setup_sound()
    --[[ Initialize Untz ]]--
    MOAIUntzSystem.initialize()
    MOAIUntzSystem.setVolume(1)
end -- setup_sound()

function load_map()
    --[[ Generate a map layer containing all terrain props ]]--

    map_layer = MOAILayer2D.new()
    map_layer:setViewport(viewport)

    local grass_sprite = MOAIGfxQuad2D.new()
    grass_sprite:setTexture("images/grass_1.png")
    grass_sprite:setRect(0, 0, 1, 1)

    local sand_sprite = MOAIGfxQuad2D.new()
    sand_sprite:setTexture("images/sand_1.png")
    sand_sprite:setRect(0, 0, 1, 1)

    map = {{2,2,2,2,2,1,1,1,1,1,1,1,1,1,1,1,1}
          ,{2,2,2,2,1,1,1,1,1,1,1,1,1,1,2,2,2}
          ,{2,2,2,2,1,1,1,1,1,1,1,1,1,2,2,2,2}
          ,{2,2,2,2,2,2,1,1,1,1,1,1,2,2,2,2,2}
          ,{1,2,2,2,2,2,1,1,1,1,1,1,2,2,2,2,2}
          ,{1,2,2,2,2,2,1,1,1,1,1,1,2,2,2,2,2}
          ,{1,1,2,2,2,2,2,1,1,1,1,2,2,2,2,2,2}
          ,{1,1,1,2,2,1,1,1,1,1,1,1,1,2,2,2,2}
          ,{1,1,2,2,2,2,2,1,1,1,1,2,2,2,2,2,2}
          ,{1,1,1,2,2,1,1,1,1,1,1,1,1,2,2,2,2}
          ,{1,1,1,1,1,1,1,1,1,1,1,1,2,2,2,2,2}
          ,{1,1,1,1,1,1,1,1,1,1,1,1,2,2,2,2,2}
          ,{1,1,1,1,1,1,1,1,1,1,1,1,2,2,2,2,2}
          ,{1,1,1,1,1,1,1,1,1,1,1,2,2,2,2,2,2}
          ,{1,1,1,1,1,1,1,1,1,1,1,1,1,1,2,2,2}}

    for i, row in pairs(map) do
        for j, value in pairs(row) do
            local map_prop = MOAIProp2D.new()
            if value == 1 then
                map_prop:setDeck(grass_sprite)
            elseif value == 2 then
                map_prop:setDeck(sand_sprite)
            else
                error("Invalid map value at ("..i..","..j..") = "..value)
                map_prop:setDec(grass_sprite)
            end
            map_prop:setLoc((j-1-scaleWidth/2), (i-1-scaleHeight/2))
            map_layer:insertProp(map_prop)
        end
    end

    return map_layer
end -- load_map()

function coords_rect(obj)
    --[[ Return coordinates as (x, y) for all 4 corners of a horizontally
    aligned rectangle ]]--
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

function attack(attacker, defender)
    --[[ Calculate the damage delt by an attack ]]-- 
    -- Calculate probability of contact based on agility
    -- Base agility is 10. (100 % chance of hitting inanimate object)
    -- Max agility is 100. Minimum is 0.
    local attack_diff = (attacker.agility - 10) / 100
    print ('attack diff', attack_diff)
    local defend_diff = (defender.agility - 10) / 100
    print ('defend diff', defend_diff)

    local strike_percent = attack_diff * defend_diff
    print ('strike percent', strike_percent)

    local damage = 0
    if strike_percent > 0.6 then
        damage = attacker.strength - defender.defence * math.random()
    end
    print ('damage:', damage)
    return damage

end -- attack(attacker, defender)


function make_dude(X, Y, speed)
    -- Main character render --
    local texture = MOAITexture.new()
    texture:load( 'images/dude_1.png' )
    local w, h = texture:getSize()

    local sprite = MOAIGfxQuad2D.new()
    sprite:setTexture( texture )
    sprite:setRect(-w/32, -h/32, w/32, h/32) --i.e. (w/2) / (16 px/world unit)

    dude = MOAIProp2D.new()
    dude:setDeck(sprite)
    dude:setLoc(X, Y)

    dude.speed = speed
    dude.health = 20
    dude.strength = 5
    dude.defence = 6
    dude.agility = 2

    dude.width = 1
    dude.height = 1

    char_layer:insertProp(dude)

    function dude:move(x, y)
        local X_cur, Y_cur = self:getLoc()
        local X, Y = char_layer:wndToWorld( x, y )
        local time = mh.distance(X, Y, X_cur, Y_cur) / self.speed
        function thread_func()
            self.move_action = self:seekLoc( X, Y, time, MOAIEaseType.LINEAR )
            MOAICoroutine.blockOnAction ( self.move_action )
            MOAICoroutine.blockOnAction ( self:moveRot(360, 0.3) )
        end

        self.thread = MOAICoroutine.new()
        self.thread:run( thread_func )
    end

    function dude:stop()
        if self.move_action ~= nil and self.move_action:isBusy() then
            self.move_action:stop()
        end
    end

    return dude
        

end -- function make_dude ()


function make_monster(X, Y, speed, monster_type)

    -- Slime character render --
    local texture = MOAITexture.new()
    texture:load( 'images/slime_1.png' )
    local w, h = texture:getSize()
    local sprite = MOAIGfxQuad2D.new()
    sprite:setTexture( texture )
    sprite:setRect(-w/32, -h/32, w/32, h/32) --i.e. (w/2) / (16 px/world unit)
    local prop = MOAIProp2D.new()
    prop:setDeck(sprite)
    prop:setLoc(X, Y)
    prop.speed = speed
    prop.monster_type = monster_type
    prop.health = 10
    prop.strength = 2
    prop.defence = 5
    prop.agility = 1
    prop.width = 1
    prop.height = 1

    char_layer:insertProp(prop)
    return prop
    
end -- function make_slime ()


function make_item(X, Y, item_type)

    local texture = MOAITexture.new()
    texture:load( 'images/sword_1.png' )
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
    dude = make_dude(0, 0, 3)  -- Hero

    monsters = {
        make_monster(5, 5, 2, 'slime')       -- Slime 1
        , make_monster(-3, -2, 1.5, 'slime')   -- Slime 2
        , make_monster(-1, 4, 2.4, 'slime')    -- Slime 3
    }

    items = {
        make_item(5, 0, 'sword')
    }
end -- setup_world()

function play_sound(sound_name)
    --[[ Play a given sound file ]]--
    local sound = MOAIUntzSound.new()
    -- TODO Load sounds when we set up world, not when we need to play them
    if sound_name == 'item pickup' then sound:load('sounds/buckle.wav')
    elseif sound_name == 'game over' then sound:load('sounds/neck_snap.wav')
    end
    sound:setLooping(false)
    sound:setPosition(0)
    sound:setVolume(1)
    sound:play()
    return nil
end -- play_sound(sound_name)


function move_prop(prop_obj)
    -- TODO Turn this into a method of monster object
    local X_cur, Y_cur = prop_obj:getLoc()
    local X = math.random(-1,1)
    local Y = math.random(-1,1)
    local dist = mh.distance(X, Y, X_cur, Y_cur)
    local time = dist / prop_obj.speed
    prop_obj:moveLoc(X, Y, time, MOAIEaseType.LINEAR)
end -- move_prop(prop_obj)

function game_loop ()
    local frames = 0
    while not game_over do
        coroutine.yield ()
        frames = frames + 1
        if frames == 90 then
            frames = 0
            for i, monster in ipairs(monsters) do
                move_prop(monster)
            end
        end
        if MOAIInputMgr.device.mouseLeft:down () then
            if dude.move_action ~= nil and dude.move_action:isBusy() then
                dude.move_action:stop()
            end
            dude:move(MOAIInputMgr.device.pointer:getLoc())
        end
        for i, monster in ipairs (monsters) do
            if collide_rect(monster, dude) then
                print('Slime killed you!')
                print('Game over.')
                char_layer:removeProp(dude)
                play_sound('game over')
                game_over = true
                break
            end
        end 
        for i, item in ipairs(items) do
            if collide_rect(item, dude) then
                print("You found a sword!")
                char_layer:removeProp(item)
                table.remove(items, i)
                play_sound('item pickup')
                break
            end
        end
        --x, y = dude:getLoc()           
        -- camera:setLoc(x, y, cam_z)
    end -- while not gameOver
    os.exit(0)
end -- game_loop()

function main()
    game_over = false
    print("Setting up screen...")
    setup_screen ()
    print("Loading sounds...")
    setup_sound ()
    print("Setting up world...")
    setup_world ()
    print("done.")

    print("Welcome to Ancestors.")
    mainThread = MOAICoroutine.new ()
    mainThread:run ( game_loop )
end -- main()

main() -- Run program
