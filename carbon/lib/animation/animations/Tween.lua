local Tween = {}
Tween.__index = Tween

-- Define some common easing functions
local EasingFunctions = {
    linear = function(t) return t end,
    easeInQuad = function(t) return t * t end,
    easeOutQuad = function(t) return t * (2 - t) end,
    easeInOutQuad = function(t) return t < 0.5 and 2 * t * t or -1 + (4 - 2 * t) * t end,
    -- Add more easing functions as needed
}

-- Tween constructor
function Tween:new(target, duration, properties, easing)
    local instance = setmetatable({}, self)
    instance.target = target
    instance.duration = duration
    instance.properties = properties
    instance.elapsed = 0
    instance.startValues = {}
    instance.endValues = {}
    instance.active = true
    instance.easing = EasingFunctions[easing] or EasingFunctions.linear -- Default to linear easing

    -- Initialize start and end values
    for key, endValue in pairs(properties) do
        if key ~= "width" and key ~= "height" then -- Exclude size properties
            instance.startValues[key] = target[key] or 0
            instance.endValues[key] = endValue
        end
    end

    return instance
end

-- Update method for the tween
function Tween:update(dt)
    if not self.active then return end

    self.elapsed = self.elapsed + dt
    local progress = math.min(self.elapsed / self.duration, 1)
    local easedProgress = self.easing(progress)

    for key, startValue in pairs(self.startValues) do
        local endValue = self.endValues[key]
        self.target[key] = startValue + (endValue - startValue) * easedProgress
    end

    -- Deactivate tween if it has completed
    if progress >= 1 then
        self.active = false
    end
end

-- Apply method for the tween
function Tween:apply(target)
    self.target = target
end

-- Check if the tween has finished
function Tween:isFinished()
    return not self.active
end

return Tween
