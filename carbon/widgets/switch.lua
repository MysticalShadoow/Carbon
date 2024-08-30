local Component = require("carbon.lib.component")
local Switch = setmetatable({}, { __index = Component })
Switch.__index = Switch

function Switch:new(x, y, size, options)
    local instance = setmetatable(Component.new(self, x, y, size * 2, size), self)  -- Width is twice the height by default
    instance.size = size or 30  -- Default size
    instance.width = instance.size * 2
    instance.height = instance.size
    instance.isChecked = options.isChecked or false
    instance.backgroundColor = options.backgroundColor or {0.8, 0.8, 0.8, 1}
    instance.checkedColor = options.checkedColor or {0.4, 0.8, 0.4, 1}
    instance.uncheckedColor = options.uncheckedColor or {0.8, 0.4, 0.4, 1}
    instance.borderColor = options.borderColor or {0, 0, 0, 1}
    instance.borderWidth = options.borderWidth or 2
    instance.borderEnabled = options.borderEnabled ~= nil and options.borderEnabled or true  -- Enable border by default
    instance.ballOnCheckedColor = options.ballOnCheckedColor or {1, 1, 1, 1} -- Default white color when checked
    instance.ballOnUncheckedColor = options.ballOnUncheckedColor or {1, 1, 1, 1} -- Default white color when unchecked
    instance.animationDuration = options.animationDuration or 0.2
    instance.roundness = options.roundness or instance.size / 2
    instance.onCheckedChanged = options.onCheckedChanged or function() end
    instance.onClicked = options.onClicked or function() end
    instance.animationProgress = instance.isChecked and 1 or 0
    instance.targetProgress = instance.animationProgress
    instance.isHovered = false
    instance.isPressed = false

    instance.x = x
    instance.y = y

    -- Text options
    instance.text = options.text or ""
    instance.textColor = options.textColor or {0, 0, 0, 1}
    instance.textPosition = options.textPosition or "right" -- "left" or "right"
    instance.textPadding = options.textPadding or 10

    -- New customizable options
    instance.easingFunction = options.easingFunction or function(t) return t end -- Linear by default
    instance.customDrawFunction = options.customDrawFunction or nil
    instance.handlePadding = options.handlePadding or 2
    instance.handleThickness = options.handleThickness or instance.height - instance.borderWidth * 2 - instance.handlePadding * 2
    instance.handleRoundness = options.handleRoundness or instance.handleThickness / 2

    return instance
end

function Switch:update(dt)
    if self.animationProgress ~= self.targetProgress then
        local direction = self.animationProgress < self.targetProgress and 1 or -1
        self.animationProgress = self.animationProgress + direction * dt / self.animationDuration
        if (direction == 1 and self.animationProgress >= self.targetProgress) or (direction == -1 and self.animationProgress <= self.targetProgress) then
            self.animationProgress = self.targetProgress
        end
    end
end

function Switch:draw()
    -- Use custom draw function if provided
    if self.customDrawFunction then
        self.customDrawFunction(self)
        return
    end

    local x, y = self.x, self.y
    local w, h = self.width, self.height

    -- Draw the background color based on the switch state
    local bgColor = {
        self.uncheckedColor[1] * (1 - self.animationProgress) + self.checkedColor[1] * self.animationProgress,
        self.uncheckedColor[2] * (1 - self.animationProgress) + self.checkedColor[2] * self.animationProgress,
        self.uncheckedColor[3] * (1 - self.animationProgress) + self.checkedColor[3] * self.animationProgress,
        self.uncheckedColor[4] * (1 - self.animationProgress) + self.checkedColor[4] * self.animationProgress
    }
    love.graphics.setColor(bgColor)
    love.graphics.rectangle("fill", x, y, w, h, self.roundness)

    -- Draw the border if enabled
    if self.borderEnabled then
        love.graphics.setColor(self.borderColor)
        love.graphics.setLineWidth(self.borderWidth)
        love.graphics.rectangle("line", x, y, w, h, self.roundness)
    end

    -- Calculate the easing progress
    local easedProgress = self.easingFunction(self.animationProgress)

    -- Draw the switch handle
    local switchSize = self.handleThickness
    local switchX = x + (w - switchSize - self.handlePadding * 2) * easedProgress + self.handlePadding
    local switchY = y + self.borderWidth + self.handlePadding
    local ballColor = {
        self.ballOnUncheckedColor[1] * (1 - easedProgress) + self.ballOnCheckedColor[1] * easedProgress,
        self.ballOnUncheckedColor[2] * (1 - easedProgress) + self.ballOnCheckedColor[2] * easedProgress,
        self.ballOnUncheckedColor[3] * (1 - easedProgress) + self.ballOnCheckedColor[3] * easedProgress,
        self.ballOnUncheckedColor[4] * (1 - easedProgress) + self.ballOnCheckedColor[4] * easedProgress
    }
    love.graphics.setColor(ballColor)
    love.graphics.rectangle("fill", switchX, switchY, switchSize, switchSize, self.handleRoundness)
    
    -- Draw the text
    if self.text and self.text ~= "" then
        love.graphics.setColor(self.textColor)
        local textX
        if self.textPosition == "left" then
            textX = x - self.textPadding - love.graphics.getFont():getWidth(self.text)
        else -- default to "right"
            textX = x + w + self.textPadding
        end
        local textY = y + h / 2 - love.graphics.getFont():getHeight() / 2
        love.graphics.print(self.text, textX, textY)
    end
end

function Switch:mousepressed(x, y, button)
    if button == 1 and self:isPointInside(x, y) then
        self.isPressed = true
        self.isChecked = not self.isChecked
        self.targetProgress = self.isChecked and 1 or 0
        self.onCheckedChanged(self.isChecked)
        self.onClicked()
    end
end

function Switch:mousereleased(x, y, button)
    if button == 1 and self.isPressed then
        self.isPressed = false
    end
end

function Switch:mousemoved(x, y)
    self.isHovered = self:isPointInside(x, y)
end

function Switch:isPointInside(x, y)
    return x >= self.x and x <= self.x + self.width and y >= self.y and y <= self.y + self.height
end

-- Setter methods for customizing the switch
function Switch:setSize(size)
    self.size = size
    self.width = size * 2
    self.height = size
    self.roundness = size / 2
    self.handleThickness = self.height - self.borderWidth * 2 - self.handlePadding * 2
    self.handleRoundness = self.handleThickness / 2
end

function Switch:setBackgroundColor(color) self.backgroundColor = color end
function Switch:setCheckedColor(color) self.checkedColor = color end
function Switch:setUncheckedColor(color) self.uncheckedColor = color end
function Switch:setBorderColor(color) self.borderColor = color end
function Switch:setBorderWidth(width) self.borderWidth = width end
function Switch:setBorderEnabled(enabled) self.borderEnabled = enabled end
function Switch:setBallOnCheckedColor(color) self.ballOnCheckedColor = color end
function Switch:setBallOnUncheckedColor(color) self.ballOnUncheckedColor = color end
function Switch:setAnimationDuration(duration) self.animationDuration = duration end
function Switch:setRoundness(roundness) self.roundness = roundness end

-- New setter methods for additional customization
function Switch:setEasingFunction(easingFunction) self.easingFunction = easingFunction end
function Switch:setCustomDrawFunction(drawFunction) self.customDrawFunction = drawFunction end
function Switch:setHandlePadding(padding) self.handlePadding = padding; self:setSize(self.size) end
function Switch:setHandleThickness(thickness) self.handleThickness = thickness; self.handleRoundness = thickness / 2 end
function Switch:setHandleRoundness(roundness) self.handleRoundness = roundness end

-- Setter methods for text customization
function Switch:setText(text) self.text = text end
function Switch:setTextColor(color) self.textColor = color end
function Switch:setTextPosition(position) self.textPosition = position end
function Switch:setTextPadding(padding) self.textPadding = padding end

-- Getter methods for switch state and properties
function Switch:getIsChecked() return self.isChecked end
function Switch:getIsHovered() return self.isHovered end
function Switch:getIsPressed() return self.isPressed end

return Switch
