module(..., package.seeall)

ui_objects = {chat_window = nil, choice_windows = { nil, nil} }

conversation = false
active_conversation = { speaker = nil, listener = nil }

function event_dispatch(key_down)
    if active_conversation.speaker then
        if key_down == 'b' or key_down == 'B' then
            lib.ui.select_option(2)
        elseif key_down == 'v' or key_down == 'V' then
            lib.ui.select_option(1)
        elseif key_down == 'esc' then
            lib.ui.close_dialogue()
            active_conversation = { speaker = nil, listener = nil }
            conversation = false
        end
        return nil
    end

end

function converse()
    --[[ Loads a dialogue file with a given position and choice (which could both be nil)
    and returns the spoken dialogue and new choices, if any. ]]

    -- Load the dialogue function
    local speaker = active_conversation.speaker
    local listener = active_conversation.listener

    local dialogue = assert(loadfile('dialogue/'.. listener ..'.lua'))
    local text, replies = dialogue(speaker.para[listener])
    if replies[1] == nil then   -- no choices, just a paragraph destination
        speaker.para[listener] = replies[2]
    end
    speaker.replies[listener] = replies
    lib.ui.show_dialogue(text, replies)
end

function select_option(choice)
    local speaker = active_conversation.speaker
    local listener = active_conversation.listener
   
    if choice == 1 and speaker.replies[listener][1] ~= nil then
        speaker.para[listener] = speaker.replies[listener][2] -- The actual paragraph number
        close_dialogue()    -- Remove current dialogue
        converse() -- start next dialogue given selected choice
    elseif choice == 2 and speaker.replies[listener][3] ~= nil then
        speaker.para[listener] = speaker.replies[listener][4] -- para number
        close_dialogue()    -- Remove current dialogue
        converse() -- start next dialogue given selected choice
    end
end

function show_dialogue(dlg, replies)
    --[[ Displays a dialogue text in a main chat window and accompanying replies. ]]
    local prop, box = chat_window(dlg)
    ui_objects.chat_window = { prop, box }
    if replies ~= nil then
        if replies[1] then
            prop, box = choice_window(1, replies[1])
            ui_objects.choice_windows[1] = { prop, box }
        end
        if replies[3] then
            prop, box = choice_window(2, replies[3])
            ui_objects.choice_windows[2] = { prop, box }
        end
    end
end

function close_dialogue()
    --[[ if ui_objects chat_window and choice_windows exist, we delete them and
    remove their props (texture and textbox) from the ui_layer. ]]
    local main = ui_objects.chat_window
    if main ~= nil then
        ui_layer:removeProp(main[1])
        ui_layer:removeProp(main[2])
        ui_objects.chat_window = nil
    end
    local choice_1 = ui_objects.choice_windows[1]
    if choice_1 ~= nil then
        ui_layer:removeProp(choice_1[1])
        ui_layer:removeProp(choice_1[2])
        ui_objects.choice_windows[1] = nil
    end

    local choice_2 = ui_objects.choice_windows[2]
    if choice_2 ~= nil then
        ui_layer:removeProp(choice_2[1])
        ui_layer:removeProp(choice_2[2])
        ui_objects.choice_windows[2] = nil
    end
    return nil
end


function chat_window(text)
    --[[ Displays the main chat window.
    Returns the prop and the textbox it creates. ]]

    local gfxQuad = MOAIGfxQuad2D.new ()
    gfxQuad:setTexture("assets/images/ui/textbox_main.png")
    gfxQuad:setRect(-220, -100, 220, -200)

    local prop = MOAIProp2D.new()
    prop:setDeck(gfxQuad)
    ui_layer:insertProp(prop)

    local box = lib.ui.corner_box('', -210, -105, 420, 90)
    box:setString(text)
    ui_layer:insertProp(box)

    return prop, box
end

function choice_window(loc, choice)
    --[[ Displays the choices chat window with given text in either location A or B.
    Returns the prop and the textbox it creates. ]]

    local x = nil
    local y = -205
    if loc == 1 then
        x = -220
    elseif loc == 2 then
        x = 3
    end

    local gfxQuad = MOAIGfxQuad2D.new ()
    gfxQuad:setTexture("assets/images/ui/textbox_choice.png")
    local offset = 223
    gfxQuad:setRect(x, -205, x + 217, -240)

    local prop = MOAIProp2D.new()
    prop:setDeck(gfxQuad)
    ui_layer:insertProp(prop)

    local box = lib.ui.corner_box('', x + 10, y - 3, 200, 29)
    box:setString(choice)
    ui_layer:insertProp(box)

    return prop, box
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

