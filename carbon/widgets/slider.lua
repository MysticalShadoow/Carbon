local Component = require("carbon.lib.component")
local Slider = setmetatable({}, { __index = Component })
Slider.__index = Slider

function Slider:new(x, y, width, min, max, value, options)
    local instance = setmetatable(Component.new(self, x, y, width, options.size or 20), self)
    instance.min = min or 0
    instance.max = max or 100
    instance.value = value or (min + max) / 2
    instance.options = options or {}
    instance.trackColor = instance.options.trackColor or {0.8, 0.8, 0.8, 1}
    instance.trackHeight = instance.options.trackHeight or 8
    instance.thumbColor = instance.options.thumbColor or {1, 0.5, 0, 1}
    instance.thumbRadius = instance.options.thumbRadius or 10
    instance.size = instance.options.size or 20 -- Added size property
    instance.isDragging = false
    instance.onValueChanged = instance.options.onValueChanged or nil

    -- Calculate initial thumb position
    instance.thumbX = instance.x + ((instance.value - instance.min) / (instance.max - instance.min)) * instance.width

    return instance
end

function Slider:draw()
    -- Draw the track with progress fill
    love.graphics.setColor(self.trackColor)
    love.graphics.rectangle("fill", self.x, self.y + (self.height - self.trackHeight) / 2, self.width, self.trackHeight)
    
    -- Draw the filled part of the track based on the current value
    local fillWidth = ((self.value - self.min) / (self.max - self.min)) * self.width
    love.graphics.setColor(0.3, 0.6, 0.9, 1) -- Progress color
    love.graphics.rectangle("fill", self.x, self.y + (self.height - self.trackHeight) / 2, fillWidth, self.trackHeight)

    -- Draw the thumb
    love.graphics.setColor(self.thumbColor)
    love.graphics.circle("fill", self.thumbX, self.y + self.height / 2, self.thumbRadius)
end

function Slider:update(dt)
    if self.isDragging then
        local mouseX = love.mouse.getX()
        self.thumbX = math.max(self.x + self.thumbRadius, math.min(self.x + self.width - self.thumbRadius, mouseX))
        self.value = self.min + ((self.thumbX - self.x) / self.width) * (self.max - self.min)

        if self.onValueChanged then
            self.onValueChanged(self.value)
        end
    end
end

function Slider:mousepressed(x, y, button)
    if button == 1 and self:isHovered(x, y) then
        self.isDragging = true
    end
end

function Slider:mousereleased(x, y, button)
    if button == 1 then
        self.isDragging = false
    end
end

function Slider:isHovered(x, y)
    local dx = x - self.thumbX
    local dy = y - (self.y + self.height / 2)
    return (dx * dx + dy * dy) <= self.thumbRadius * self.thumbRadius
end

return Slider
