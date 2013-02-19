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

end -- function setup_screen ()


function load_map()

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
end -- function load_map()

function make_dude(X, Y, speed)
    -- Main character render --
    local sprite = MOAIGfxQuad2D.new()
    sprite:setTexture("images/dude_1.png")
    sprite:setRect(-0.5, -0.5, 0.5, 0.5)

    dude = MOAIProp2D.new()
    dude.speed = speed
    dude:setDeck(sprite)
    dude:setLoc(X, Y)
  
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
    local sprite = MOAIGfxQuad2D.new()
    sprite:setTexture("images/slime_1.png")
    sprite:setRect(-0.5, -0.5, 0.5, 0.5)

    local prop = MOAIProp2D.new()
    prop:setDeck(sprite)
    prop:setLoc(X, Y)
    prop.speed = speed
    prop.monster_type = monster_type

    char_layer:insertProp(prop)

    return prop
    
end -- function make_slime ()


function make_item(X, Y, item_type)

    local sprite = MOAIGfxQuad2D.new()
    sprite:setTexture("images/sword_1.png")
    sprite:setRect(-0.5, -0.5, 0.5, 0.5)

    local prop = MOAIProp2D.new()
    prop:setDeck(sprite)
    prop:setLoc(X, Y)
    prop.item_type = item_type

    char_layer:insertProp(prop)

    return prop
    
end -- function make_slime ()

function setup_world ()

    dude = make_dude(0, 0, 3)  -- Hero

    monsters = {
        make_monster(5, 5, 2, 'slime')       -- Slime 1
        , make_monster(-3, -2, 1.5, 'slime')   -- Slime 2
        , make_monster(-1, 4, 2.4, 'slime')    -- Slime 3
    }

    items = {
        make_item(5, 0, 'sword')
    }
end -- function setup_world()


function move_prop(prop_obj)
    -- TODO Turn this into a method of monster object
    local X_cur, Y_cur = prop_obj:getLoc()
    local X = math.random(-1,1)
    local Y = math.random(-1,1)
    local dist = mh.distance(X, Y, X_cur, Y_cur)
    local time = dist / prop_obj.speed
    prop_obj:moveLoc(X, Y, time, MOAIEaseType.LINEAR)
end

function game_loop ()
        local frames = 0
        while not gameOver do
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
            --x, y = dude:getLoc()           
            -- camera:setLoc(x, y, cam_z)
        end
    end

function main ()
    gameOver = false
    setup_screen ()
    setup_world ()

    mainThread = MOAICoroutine.new ()
    mainThread:run ( game_loop )
end

main() -- Run program
