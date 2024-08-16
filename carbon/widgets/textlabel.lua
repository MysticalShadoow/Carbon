local Component = require("carbon.lib.component")
local TextLabel = setmetatable({}, { __index = Component })
TextLabel.__index = TextLabel

function TextLabel:new(x, y, width, height, text, options)
    local instance = setmetatable(Component.new(self, x, y, width, height), self)
    instance.text = text or ""
    instance.font = options.font or love.graphics.newFont(14)
    instance.textColor = options.textColor or {0, 0, 0, 1} -- Default text color
    instance.bgColor = options.bgColor or {1, 1, 1, 1} -- Default background color
    instance.roundness = options.roundness or 0 -- Default roundness
    instance.stroke = options.hasStroke or false -- Toggle for stroke
    instance.strokeColor = options.strokeColor or {0, 0, 0, 1} -- Default stroke color
    instance.strokeWidth = options.strokeWidth or 1 -- Default stroke width
    instance.gradient = options.gradient or nil -- Default no gradient
    instance.textDrawable = love.graphics.newText(instance.font, instance.text)
    
    return instance
end

function TextLabel:updateDrawable()
    self.textDrawable = love.graphics.newText(self.font, self.text)
end

function TextLabel:draw()
    local box = self:getBoundingBox()
    local x, y = box.left, box.top
    local w, h = box:getWidth(), box:getHeight()

    -- Draw background color or gradient
    if self.gradient then
        local gradientMesh = love.graphics.newMesh({
            {0, 0, 0, 0, self.gradient[1][1], self.gradient[1][2], self.gradient[1][3], self.gradient[1][4]},
            {w, 0, 1, 0, self.gradient[2][1], self.gradient[2][2], self.gradient[2][3], self.gradient[2][4]},
            {w, h, 1, 1, self.gradient[3][1], self.gradient[3][2], self.gradient[3][3], self.gradient[3][4]},
            {0, h, 0, 1, self.gradient[4][1], self.gradient[4][2], self.gradient[4][3], self.gradient[4][4]},
        }, "fan")
        love.graphics.draw(gradientMesh, x, y)
    else
        love.graphics.setColor(self.bgColor)
        if self.roundness > 0 then
            love.graphics.rectangle("fill", x, y, w, h, self.roundness)
        else
            love.graphics.rectangle("fill", x, y, w, h)
        end
    end

    -- Draw stroke if enabled
    if self.stroke then
        love.graphics.setColor(self.strokeColor)
        love.graphics.setLineWidth(self.strokeWidth)
        if self.roundness > 0 then
            love.graphics.rectangle("line", x, y, w, h, self.roundness)
        else
            love.graphics.rectangle("line", x, y, w, h)
        end
    end

    -- Draw text
    love.graphics.setColor(self.textColor)
    love.graphics.draw(self.textDrawable, x + (w - self.textDrawable:getWidth()) / 2, y + (h - self.textDrawable:getHeight()) / 2)
end

function TextLabel:setText(text)
    self.text = text
    self:updateDrawable()
end

function TextLabel:setFont(font)
    self.font = font
    self:updateDrawable()
end

function TextLabel:setTextColor(color)
    self.textColor = color
end

function TextLabel:setBgColor(color)
    self.bgColor = color
end

function TextLabel:setRoundness(roundness)
    self.roundness = roundness
end

function TextLabel:setHasStroke(hasStroke)
    self.hasStroke = hasStroke
end

function TextLabel:setStrokeColor(color)
    self.strokeColor = color
end

function TextLabel:setStrokeWidth(width)
    self.strokeWidth = width
end

function TextLabel:setGradient(gradient)
    self.gradient = gradient
end

function TextLabel:getBoundingBox()
    return {
        left = self.x,
        top = self.y,
        right = self.x + self.width,
        bottom = self.y + self.height,
        getWidth = function(self) return self.right - self.left end,
        getHeight = function(self) return self.bottom - self.top end
    }
end

return TextLabel
