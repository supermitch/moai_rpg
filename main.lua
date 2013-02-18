mh = require 'math_helper'   -- import helper math module

function load_map()

    map_layer = MOAILayer2D.new()
    map_layer:setViewport(viewport)

    grass_sprite = MOAIGfxQuad2D.new()
    grass_sprite:setTexture("images/grass_1.png")
    grass_sprite:setRect(0, 0, 1, 1)

    sand_sprite = MOAIGfxQuad2D.new()
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
            map_prop = MOAIProp2D.new()
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

function setup_screen ()

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
end

function setup_world ()
    -- Main character render --
    sprite = MOAIGfxQuad2D.new()
    sprite:setTexture("images/dude_1.png")
    sprite:setRect(-0.5, -0.5, 0.5, 0.5)

    dude = MOAIProp2D.new()
    dude:setDeck(sprite)
    dude:setLoc(0, 0)
    dude.speed = 3
    dude.thread = MOAICoroutine.new()
   
    function dude:move(x, y)
        if self.thread == nil then
            print("No thread found")
        else
            print(MOAICoroutine.currentThread())
            print("stopping thread")
            self.thread:stop()
            print(MOAICoroutine.currentThread())
        end
        self.thread:run (
            function()
                X_cur, Y_cur = self:getLoc()
                X, Y = char_layer:wndToWorld(x, y)
                dist = mh.distance(X, Y, X_cur, Y_cur)
                time = dist / slime.speed
                MOAICoroutine.blockOnAction (
                    self:seekLoc(X, Y, time, MOAIEaseType.LINEAR)
                )
            end
        )
    end

    char_layer:insertProp(dude)

    -- Slime character render --
    slime_sprite = MOAIGfxQuad2D.new()
    slime_sprite:setTexture("images/slime_1.png")
    slime_sprite:setRect(-0.5, -0.5, 0.5, 0.5)

    slime = MOAIProp2D.new()
    slime:setDeck(slime_sprite)
    slime:setLoc(5, 5)
    slime.speed = 2
    char_layer:insertProp(slime)
    
    slime2 = MOAIProp2D.new()
    slime2:setDeck(slime_sprite)
    slime2:setLoc(-3, -2)
    slime2.speed = 1.5
    char_layer:insertProp(slime2)

    MOAIGfxDevice.setClearColor(1, 0.41, 0.70, 1)

end -- function setup_world()


function move_prop(prop_obj)
    X_cur, Y_cur = prop_obj:getLoc()
    X = math.random(-1,1)
    Y = math.random(-1,1)
    dist = mh.distance(X, Y, X_cur, Y_cur)
    time = dist / prop_obj.speed
    prop_obj:moveLoc(X, Y, time, MOAIEaseType.LINEAR)
end

function main ()
    gameOver = false
    setup_screen ()
    setup_world ()

    mainThread = MOAICoroutine.new ()
    mainThread:run (function () -- Game loop
        local frames = 0
        while not gameOver do
            coroutine.yield ()
            frames = frames + 1
            if frames == 90 then
                frames = 0
                move_prop(slime)
                move_prop(slime2)
            end
            if MOAIInputMgr.device.mouseLeft:down () then
                dude:move(MOAIInputMgr.device.pointer:getLoc())
            end
        end
    end)
end

main() -- Run program
