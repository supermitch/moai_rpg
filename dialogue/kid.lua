return function(pos, ch)

    dl = '...'  -- NPC dialogue: No answer by default
    chs = {}    -- Player answer choices; No replies by default
    
    if not pos then
        dl = "Hey there."
        chs = { "Hi.", "Don't talk to me." }
        pos = 1
    elseif pos == 1 then
        if ch == 1 then
            dl = "What are you doing out here? Don't you know it's dangerous?"
            chs = { "I'm lost...", "Uhm... hunting." }
        elseif ch == 2 then
            dl = "Oh. Ok. Bye..."
        end
        pos = 2

    elseif pos == 2 then
        if ch == 1 then
            dl = "Well... I got locked out of my house."
            chs = { "That's too bad. See ya later.", "Need help?" }
        elseif ch == 2 then
            dl = "Hunting? Wanna help hunt for my lost key with me?"
            chs = { "Sorry. I'm busy.", "Sure!" }
        end
        pos = 3
    else
        return nil, nil, nil    -- Bad position, or all done talking.
    end

    return dl, chs, pos

end
