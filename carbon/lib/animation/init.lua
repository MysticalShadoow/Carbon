-- animation.lua
local AnimationLibrary = {}

AnimationLibrary.Tween = require("carbon.lib.animation.animations.Tween")

-- Store all animations globally or in a dedicated manager
AnimationLibrary.animations = {}

function AnimationLibrary.defaultIsFinished()
    return false
end

-- Update the library to use this default method if an animation lacks one
function AnimationLibrary.update(dt)
    for i = #AnimationLibrary.animations, 1, -1 do
        local anim = AnimationLibrary.animations[i]
        anim:update(dt)
        if (anim.isFinished and anim:isFinished()) or not anim.isFinished then
            table.remove(AnimationLibrary.animations, i)
        end
    end
end


return AnimationLibrary
