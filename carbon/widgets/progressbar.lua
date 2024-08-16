local Component = require("carbon.lib.component")
local ProgressBar = setmetatable({}, { __index = Component })
ProgressBar.__index = ProgressBar

function ProgressBar:new(x, y, width, height, options)
    local instance = setmetatable(Component.new(self, x, y, width, height), self)
    
    -- Default properties
    instance.minValue = options.minValue or 0
    instance.maxValue = options.maxValue or 100
    instance.currentValue = options.currentValue or 0
    instance.barColor = options.barColor or {0, 0, 1, 1} -- Default bar color
    instance.bgColor = options.bgColor or {0.8, 0.8, 0.8, 1} -- Default background color
    instance.roundness = options.roundness or 0 -- Default roundness
    instance.borderColor = options.borderColor or {0, 0, 0, 1} -- Default border color
    instance.borderWidth = options.borderWidth or 2 -- Default border width
    
    return instance
end


function ProgressBar:draw()
    local box = self:getBoundingBox()
    local x, y = box.left, box.top
    local w, h = box:getWidth(), box:getHeight()

    -- Draw background
    love.graphics.setColor(self.bgColor)
    if self.roundness > 0 then
        love.graphics.rectangle("fill", x, y, w, h, self.roundness)
    else
        love.graphics.rectangle("fill", x, y, w, h)
    end

    -- Calculate the filled width based on the current value
    local fillWidth = (self.currentValue - self.minValue) / (self.maxValue - self.minValue) * w
    love.graphics.setColor(self.barColor)
    if self.roundness > 0 then
        love.graphics.rectangle("fill", x, y, fillWidth, h, self.roundness)
    else
        love.graphics.rectangle("fill", x, y, fillWidth, h)
    end

    -- Draw border
    if self.borderWidth > 0 then
        love.graphics.setColor(self.borderColor)
        love.graphics.setLineWidth(self.borderWidth)
        if self.roundness > 0 then
            love.graphics.rectangle("line", x, y, w, h, self.roundness)
        else
            love.graphics.rectangle("line", x, y, w, h)
        end
    end
end

function ProgressBar:setCurrentValue(value)
    self.currentValue = math.max(self.minValue, math.min(value, self.maxValue))
end

function ProgressBar:setMinValue(value)
    self.minValue = value
    self:setCurrentValue(self.currentValue) -- Adjust currentValue to be within new range
end

function ProgressBar:setMaxValue(value)
    self.maxValue = value
    self:setCurrentValue(self.currentValue) -- Adjust currentValue to be within new range
end

function ProgressBar:setBarColor(color)
    self.barColor = color
end

function ProgressBar:setBgColor(color)
    self.bgColor = color
end

function ProgressBar:setRoundness(roundness)
    self.roundness = roundness
end

function ProgressBar:setBorderColor(color)
    self.borderColor = color
end

function ProgressBar:setBorderWidth(width)
    self.borderWidth = width
end

function ProgressBar:getBoundingBox()
    return {
        left = self.x,
        top = self.y,
        right = self.x + self.width,
        bottom = self.y + self.height,
        getWidth = function(self) return self.right - self.left end,
        getHeight = function(self) return self.bottom - self.top end
    }
end

return ProgressBar
