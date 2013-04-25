module(..., package.seeall)

function chat_window()
    return nil
end
         
function chat_window(dlg)

    local gfxQuad = MOAIGfxQuad2D.new ()
    gfxQuad:setTexture("assets/images/ui/textbox_main.png")
    gfxQuad:setRect(-220, -120, 220, -220)

    local prop = MOAIProp2D.new()
    prop:setDeck(gfxQuad)
    ui_layer:insertProp(prop)

    local box = lib.ui.corner_box('', -210, -123, 420, 90)
    box:setString("Hi there!\nHow do textboxes work?\nFuck!?")
    ui_layer:insertProp(box)

    return box
end

function converse(name)
    print("talking to "..name)
    local loaded_chunk = assert(loadfile('dialogue/'..name..'.lua'))
    local dialogue = loaded_chunk()
    local pos = nil
    local choice = nil
    while true do
        dlg, choices, pos = dialogue(pos, choice)
        if choices then
            print("him:", dlg)
            print("you:", choices[1])
            choice = 1
        else
            break
        end
    end
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

