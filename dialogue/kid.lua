local pos, ch = ... -- Incoming arguments: position and choice

dl = '...'  -- NPC dialogue: No answer by default
chs = nil   -- Player answer choices; No replies by default
nxt = nil   -- Next paragraph. Nothing (conversation is over) by default

if not pos then
    dl = "Hey there."
    chs = { "Hi.", "Don't talk to me." }
    nxt = 1
elseif pos == 1 then
    if ch == 1 then
        dl = "What are you doing out here? Don't you know it's dangerous?"
        chs = { "I'm lost...", "Uhm... hunting." }
    elseif ch == 2 then
        dl = "Oh. Ok. Bye..."
    end
    nxt = 2

elseif pos == 2 then
    if ch == 1 then
        dl = "Me too. Actually, I lost my key... Will you help me find it?"
        if objects.hero.has_key then
            chs = { "Is this your key?", "I'll keep my eye out..." }
        else
            chs = { "Sure!", "Sorry. I'm busy." }
        end
    elseif ch == 2 then
        dl = "Hunting? Wanna help hunt for my lost key with me?"
        chs = { "Help? Sure.", "No thanks. See ya later." }
    end
    nxt = 3

elseif pos == 3 then
    if objects.hero.has_key then
        dl = "Oh you found it! Thank you so much. Follow me!"
    else
        dl = "Thanks a lot. Uh, I am scared of monsters though... You go ahead. I'll wait here."
    end
else    -- Position must be bad
    return nil, nil, nil
end

return dl, chs, nxt
