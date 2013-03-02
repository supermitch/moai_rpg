module(..., package.seeall)

function setup_sound()
    --[[ Initialize Untz ]]--
    MOAIUntzSystem.initialize()
    MOAIUntzSystem.setVolume(1)
    load_sounds('sounds/')
    return nil
end -- setup_sound()

function load_sounds(path)
    --[[ Load files in a given path into a sounds table. ]]--
    sounds = {}
    sound = MOAIUntzSound.new()
    sound:load(path..'pickup_metal.wav'); sounds['pickup_metal'] = sound
    sound = MOAIUntzSound.new();
    sound:load(path..'kill.wav'); sounds['kill'] = sound;
    sound = MOAIUntzSound.new()
    sound:load(path..'clang.aiff'); sounds['clang'] = sound
    sound = MOAIUntzSound.new()
    sound:load(path..'swish.wav'); sounds['swish'] = sound
    sound = MOAIUntzSound.new()
    sound:load(path..'clunk.wav'); sounds['clunk'] = sound
    return nil
end -- load_sounds(path)

function play_sound(name)
    --[[ Play file out of our sounds table. ]]--
    sounds[name]:setLooping(false)
    sounds[name]:setPosition(0)
    sounds[name]:setVolume(1)
    sounds[name]:play()
    return nil
end -- play_sound(name)
