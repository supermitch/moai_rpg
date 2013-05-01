local pos = ... -- Incoming arguments: position

dl = '...'          -- The speaker's reply to the conversation
--[[ Optional answer choices of the form: { choice_1, pos_1, choice_2, pos_2 }
The position arguments are the paragraph to which the selected choice will lead. ]]
chs = { nil, nil }
--[[ nxt argument is used only if choices are not presented, as a shortcut. nxt = 2
is equivalent to chs = { nil, 2 }, which means the conversation moves to paragraph 2,
although no choices are presented to the speaker. ]]
nxt = nil

if pos == nil then
    dl = "Hey there."
    chs = {
        "Hi.", 1,
        "Don't talk to me.", 2
    }

elseif pos == 1 then
    dl = "What are you doing out here? Don't you know it's dangerous?"
    chs = {
        "I'm lost...", 1.1,
        "Uhm... hunting.", 1.2
    }

elseif pos == 1.1 then
    dl = "Me too. Actually, I lost my key... Will you help me find it?"
    if objects.hero.has_key then
        chs = {
            "Is this your key?", 1.11,
            "I'll keep my eye out...", 1.12
        }
    else
        chs = {
            "Yes.", 1.13,
            "Nope.", 1.14
        }
    end

elseif pos == 1.11 then
    dl = "You found it! Thanks so much! Follow me!"
    print("Key removed from inventory.")
    lib.sounds.play_sound('pickup_metal')
    nxt = 4

elseif pos == 1.12 then
    dl = "Ok, please let me know if you find it."
    nxt = 3

elseif pos == 1.13 then
    dl = "Great!\nActually, I'm kinda scared. I'll stay here, ok? Let me know if you find it."
    nxt = 3

elseif pos == 1.14 then
    dl = "Oh, ok. I guess I'll keep looking then..."
    nxt = 1.21

elseif pos == 1.2 then
    dl = "Hunting? Cool... I'm locked out of my house..."
    chs = { '...', 1.21 }
    
elseif pos == 1.21 then
    dl = "Wanna help me hunt for my lost key?"
    if objects.hero.has_key then
        chs = {
            "Is this your key?", 1.11,
            "I'll keep my eye out...", 1.12
        }
    else
        chs = {
            "Yes.", 1.13,
            "Nope.", 1.14
        }
    end

elseif pos == 2 then
    dl = "Oh. Ok. Bye..."
    nxt = nil   -- restarts

elseif pos == 3 then
    dl = "Any luck?"
    if objects.hero.has_key then
        chs = {
            "I found it.", 1.11,
            "Not yet.", 2
        }
    else
        chs = {
            "Not yet.", 3
        }
    end

elseif pos == 4 then
    dl = "Follow me!"
    nxt = 4

elseif pos == 5 then
    dl = "Thanks again!"
    nxt = 5

else    -- Position is bad
    print("Bad dialogue position:", pos)
end

--[[ We can use nxt as a shortcut to our next paragraph,
 if we don't have actual choices to present. ]]
if chs[2] == nil then
    chs = { nil, nxt }
end
return dl, chs
