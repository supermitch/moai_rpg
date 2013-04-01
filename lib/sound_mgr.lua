module(..., package.seeall)

function setup_sound()
    --[[ Initialize Untz ]]--
    MOAIUntzSystem.initialize()
    MOAIUntzSystem.setVolume(1)
    sounds = load_sounds('sounds/')
    return nil
end -- setup_sound()

function load_sounds(path)
    --[[ Load files in a given path into a sounds table. ]]--
    local sounds = {}
    sound = MOAIUntzSound.new()
    sound:load(path..'pickup_metal.wav'); sounds['pickup_metal'] = sound
    sound = MOAIUntzSound.new();
    sound:load(path..'kill.wav'); sounds['kill'] = sound;
    sound = MOAIUntzSound.new()
    sound:load(path..'clang.aiff')
    sound.volume = 0.7
    sounds['clang'] = sound
    sound = MOAIUntzSound.new()
    sound:load(path..'swish.wav'); sounds['swish'] = sound
    sound = MOAIUntzSound.new()
    sound:load(path..'clunk.wav'); sounds['clunk'] = sound
    sound = MOAIUntzSound.new()
    sound:load(path..'blip.wav')
    sound.position = 0.16
    sound.volume = 0.9
    sound.replay = false
    sounds['blip'] = sound
    return sounds
end -- load_sounds(path)

function play_sound(name)
    --[[ Play file out of our sounds table. ]]--

    if sounds[name].replay == false and sounds[name]:isPlaying() then
        -- Don't play it again if replay is false
        return nil
    else
        sounds[name]:setLooping(false)
        sounds[name]:setPosition(sounds[name].position or 0)
        sounds[name]:setVolume(sounds[name].volume or 1)
        sounds[name]:play()
    end
    return nil
end -- play_sound(name)
