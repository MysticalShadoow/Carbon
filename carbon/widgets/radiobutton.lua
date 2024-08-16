local Component = require("carbon.lib.component")
local RadioButton = setmetatable({}, { __index = Component })
RadioButton.__index = RadioButton

-- Constructor for RadioButton
function RadioButton:new(x, y, size, options)
    local instance = setmetatable(Component.new(self, x, y, size, size), self)
    instance.size = size
    instance.isChecked = options.isChecked or false
    instance.backgroundColor = options.backgroundColor or {1, 1, 1, 1}
    instance.checkedBackgroundColor = options.checkedBackgroundColor or {0.8, 0.8, 0.8, 1}
    instance.borderColor = options.borderColor or {0, 0, 0, 1}
    instance.checkedBorderColor = options.checkedBorderColor or {0, 0, 0, 1}
    instance.borderWidth = options.borderWidth or 2
    instance.buttonColor = options.buttonColor or {0, 0, 1, 1} -- Color of the filled part
    instance.checkColor = options.checkColor or {0, 0, 0, 1}
    instance.text = options.text or ""
    instance.font = love.graphics.newFont(14)
    instance.fontColor = options.fontColor or {0, 0, 0, 1}
    instance.animationDelay = options.animationDelay or 0.1
    instance.animationSmoothness = options.animationSmoothness or 0.1
    instance.roundness = options.roundness or 10
    instance.isHovered = false
    instance.isPressed = false
    instance.onCheckChanged = options.onCheckChanged or function() end
    instance.textDrawable = love.graphics.newText(instance.font, instance.text)
    instance:updateDrawable()
    instance.animationProgress = 0
    instance.animationTime = 0
    return instance
end

function RadioButton:updateDrawable()
    self.textDrawable = love.graphics.newText(self.font, self.text)
    self.textWidth = self.textDrawable:getWidth()
    self.textHeight = self.textDrawable:getHeight()
end

function RadioButton:update(dt)
    if self.isPressed then
        self.animationTime = self.animationTime + dt
        if self.animationTime >= self.animationDelay then
            self.animationProgress = math.min(self.animationProgress + self.animationSmoothness, 1)
            self.animationTime = self.animationTime - self.animationDelay
        end
    elseif not self.isChecked then
        self.animationProgress = math.max(self.animationProgress - self.animationSmoothness, 0)
    end
end

function RadioButton:draw()
    local box = self:getBoundingBox()
    local x, y = box.left, box.top
    local w, h = box:getWidth(), box:getHeight()

    -- Draw the radio button background
    if self.isChecked then
        love.graphics.setColor(self.checkedBackgroundColor)
    else
        love.graphics.setColor(self.backgroundColor)
    end
    love.graphics.circle("fill", x + w / 2, y + h / 2, w / 2, self.roundness)

    -- Draw the radio button border
    if self.isChecked then
        love.graphics.setColor(self.checkedBorderColor)
    else
        love.graphics.setColor(self.borderColor)
    end
    love.graphics.setLineWidth(self.borderWidth)
    love.graphics.circle("line", x + w / 2, y + h / 2, w / 2, self.roundness)

    -- Draw the filled part (if checked) with animation
    if self.isChecked then
        love.graphics.setColor(self.buttonColor)
        love.graphics.circle("fill", x + w / 2, y + h / 2, (w / 2) * self.animationProgress)
    end

    -- Draw the check mark
    if self.isChecked then
        love.graphics.setColor(self.checkColor)
        local checkSize = w * 0.6
        love.graphics.setLineWidth(self.borderWidth * 2)
        love.graphics.circle("line", x + w / 2, y + h / 2, checkSize / 2)
    end

    -- Draw the text
    if self.text ~= "" then
        love.graphics.setColor(self.fontColor)
        love.graphics.draw(self.textDrawable, x + w + 10, y + (h - self.textHeight) / 2)
    end
end

function RadioButton:mousepressed(x, y, button)
    if button == 1 then
        local box = self:getBoundingBox()
        if x >= box.left and x <= box.right and y >= box.top and y <= box.bottom then
            self.isChecked = not self.isChecked
            self.onCheckChanged(self.isChecked)
        end
    end
end

function RadioButton:mousemoved(x, y)
    local box = self:getBoundingBox()
    self.isHovered = x >= box.left and x <= box.right and y >= box.top and y <= box.bottom
end

function RadioButton:setBackgroundColor(color)
    self.backgroundColor = color
end

function RadioButton:setCheckedBackgroundColor(color)
    self.checkedBackgroundColor = color
end

function RadioButton:setBorderColor(color)
    self.borderColor = color
end

function RadioButton:setCheckedBorderColor(color)
    self.checkedBorderColor = color
end

function RadioButton:setBorderWidth(width)
    self.borderWidth = width
end

function RadioButton:setButtonColor(color)
    self.buttonColor = color
end

function RadioButton:setCheckColor(color)
    self.checkColor = color
end

function RadioButton:setText(text)
    self.text = text
    self:updateDrawable()
end

function RadioButton:setFont(font)
    self.font = font
    self:updateDrawable()
end

function RadioButton:setAnimationDelay(delay)
    self.animationDelay = delay
end

function RadioButton:setAnimationSmoothness(smoothness)
    self.animationSmoothness = smoothness
end

function RadioButton:setRoundness(roundness)
    self.roundness = roundness
end

function RadioButton:getBoundingBox()
    return {
        left = self.x,
        top = self.y,
        right = self.x + self.size,
        bottom = self.y + self.size,
        getWidth = function(self) return self.right - self.left end,
        getHeight = function(self) return self.bottom - self.top end
    }
end

return RadioButton
