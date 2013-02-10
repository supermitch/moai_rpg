function load_map()

    map_layer = MOAILayer2D.new()
    map_layer:setViewport(viewport)

    grass_sprite = MOAIGfxQuad2D.new()
    grass_sprite:setTexture("images/grass_1.png")
    grass_sprite:setRect(0, 0, 1, 1)

    sand_sprite = MOAIGfxQuad2D.new()
    sand_sprite:setTexture("images/sand_1.png")
    sand_sprite:setRect(0, 0, 1, 1)

    map = {{2,2,2,2,2,1,1,1,1,1}
          ,{2,2,2,2,1,1,1,1,1,1}
          ,{2,2,2,2,1,1,1,1,1,1}
          ,{2,2,2,2,2,2,1,1,1,1}
          ,{1,2,2,2,2,2,1,1,1,1}
          ,{1,1,2,2,2,2,2,1,1,1}
          ,{1,1,1,2,2,1,1,1,1,1}
          ,{1,1,1,1,1,1,1,1,1,1}
          ,{1,1,1,1,1,1,1,1,1,1}
          ,{1,1,1,1,1,1,1,1,1,1}}

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
            map_prop:setLoc((i-1-scaleWidth/2), (j-1-scaleHeight/2))
            map_layer:insertProp(map_prop)
        end
    end

    return map_layer
end -- function load_map()

function main()


    print("Starting up on: [" .. MOAIEnvironment.osBrand .."]")

    screenWidth = MOAIEnvironment.horizontalResolution or 640
    screenHeight = MOAIEnvironment.verticalResolution or 480

    scaleWidth = 10
    scaleHeight = math.floor(scaleWidth * screenHeight / screenWidth)
    print("W: "..scaleWidth.." H:"..scaleHeight)

    MOAISim.openWindow("Window", screenWidth, screenHeight)

    viewport = MOAIViewport.new()
    viewport:setSize(screenWidth, screenHeight)
    viewport:setScale(scaleWidth, scaleHeight)

    layer = MOAILayer2D.new()
    layer:setViewport(viewport)

    map_layer = load_map()

    MOAIRenderMgr.pushRenderPass(map_layer)
    MOAIRenderMgr.pushRenderPass(layer)

    sprite = MOAIGfxQuad2D.new()
    sprite:setTexture("images/dude_1.png")
    sprite:setRect(-0.5, -0.5, 0.5, 0.5)

    prop = MOAIProp2D.new()
    prop:setDeck(sprite)
    prop:setLoc(0, 0)

    layer:insertProp(prop)
    --[[
    chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ'

    font = MOAIFont.new()
    font:loadFromTTF('fonts/Menlo.ttc', chars, 120, 72)

    
    text = MOAITextBox.new()
    text:setString('Hello world')
    text:setFont(font)
    text:setTextSize(120, 72)
    text:setYFlip(true)
    text:setRect(-300, -200, 300, 200)
    text:setAlignment(MOAITextBox.CENTER_JUSTIFY, MOAITextBox.CENTER_JUSTIFY)

    layer:insertProp(text)
    --]]
    MOAIGfxDevice.setClearColor(1, 0.41, 0.70, 1)

    function handleClickOrTouch(x, y)
        prop:setLoc(layer:wndToWorld(x, y))
    end

    if MOAIInputMgr.device.pointer then
        MOAIInputMgr.device.mouseLeft:setCallback(
            function (isMouseDown)
                if (isMouseDown) then
                    handleClickOrTouch(MOAIInputMgr.device.pointer:getLoc())
                end
                -- Do nothing on mouseUp
            end
        )
        MOAIInputMgr.device.mouseRight:setCallback(
            function (isMouseDown)
                if (isMouseDown) then
                    MOAIGfxDevice.setClearColor(math.random(0, 1),
                                                math.random(0, 1),
                                                math.random(0, 1))
                end
            end
        )
    else    -- If it isnt' a mouse, it's a touch screen
        MOAIInputMgr.device.touch:setCallback(
            function (eventType, idx, x, y, tapCount)
                if (tapCount > 1) then
                    MOAIGfxDevice.setClearColor(math.random(0, 1),
                                                math.random(0, 1),
                                                math.random(0, 1))
                elseif eventType == MOAITouchSensor.TOUCH_DOWN then
                    handleClickOrTouch(x, y)
                end
            end
        )
    end

end -- function main()

main()  -- run program
