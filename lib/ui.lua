module(..., package.seeall)

         
function chat_window(dlg, choices)

    local gfxQuad = MOAIGfxQuad2D.new ()
    gfxQuad:setTexture("assets/images/ui/textbox_main.png")
    gfxQuad:setRect(-220, -100, 220, -200)

    local prop = MOAIProp2D.new()
    prop:setDeck(gfxQuad)
    ui_layer:insertProp(prop)

    local box = lib.ui.corner_box('', -210, -105, 420, 90)
    box:setString(dlg)
    ui_layer:insertProp(box)

    for i, choice in ipairs(choices) do
        local gfxQuad = MOAIGfxQuad2D.new ()
        gfxQuad:setTexture("assets/images/ui/textbox_choice.png")
        local offset = (i - 1) * (220 + 3)
        gfxQuad:setRect(-220 + offset, -205, -3 + offset, -240)

        local prop = MOAIProp2D.new()
        prop:setDeck(gfxQuad)
        ui_layer:insertProp(prop)

        offset = (i - 1) * (210 + 12)
        local box = lib.ui.corner_box('', -210 + offset, -208, 200, 29)
        box:setString(choice)
        ui_layer:insertProp(box)
    end

    return box
end

function corner_box(text, left, top, width, height)
    --[[ Note that because y is flipped, top is the the bottom of the visible
    screen and bottom is at the top! ]]
    local box = MOAITextBox.new()
    box:setString(text)
    box:setFont(font)
    box:setRect(left, top - height, left + width, top)
    box:setYFlip(true)
    --box:setColor(1, 0.2, 0, 1)
    return box
end

function center_box(text, center_x, center_y, width, height)
    local box = MOAITextBox.new()
    box:setString(text)
    box:setFont(font)
    -- box:setRect( left, top, right, bottom )
    -- Remember to convert to UI layer units (position * 32)
    box:setRect(center_x*32 - width/2, center_y*32 - height/2,
                center_x*32 + width/2, center_y*32 + height/2)
    box:setYFlip(true) -- Remember top is now bottom!!
    box:setAlignment(MOAITextBox.CENTER_JUSTIFY)
    return box
end

