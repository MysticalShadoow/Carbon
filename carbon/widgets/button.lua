local Component = require("carbon.lib.component")
local CheckBox = setmetatable({}, { __index = Component })
CheckBox.__index = CheckBox

function CheckBox:new(x, y, size, options)
    local instance = setmetatable(Component.new(self, x, y, size, size), self)
    instance.size = size
    instance.checkmarkSize = options.checkmarkSize or (size * 0.6)  -- Default checkmark size
    instance.checkmarkOffset = options.checkmarkOffset or (size * 0.2)  -- Default offset
    instance.isChecked = options.isChecked or false
    instance.backgroundColor = options.backgroundColor or {1, 1, 1, 1}
    instance.checkedBackgroundColor = options.checkedBackgroundColor or {0.8, 0.8, 0.8, 1}
    instance.borderColor = options.borderColor or {0, 0, 0, 1}
    instance.checkedBorderColor = options.checkedBorderColor or {0, 0, 0, 1}
    instance.borderWidth = options.borderWidth or 2
    instance.checkColor = options.checkColor or {0, 0, 0, 1}
    instance.text = options.text or ""
    instance.font = love.graphics.newFont(14)
    instance.fontColor = options.fontColor or {0, 0, 0, 1}
    instance.checkedFontColor = options.checkedFontColor or {0, 0, 0, 1}
    instance.onCheckChanged = options.onCheckChanged or function() end
    instance.isHovered = false
    instance.isPressed = false
    instance.textDrawable = love.graphics.newText(instance.font, instance.text)
    instance:updateDrawable()

    instance.x = x
    instance.y = y

    return instance
end

function CheckBox:updateDrawable()
    self.textDrawable = love.graphics.newText(self.font, self.text)
    self.textWidth = self.textDrawable:getWidth()
    self.textHeight = self.textDrawable:getHeight()
end

function CheckBox:draw()
    local box = self:getBoundingBox()
    local x, y = box.left, box.top
    local w, h = box:getWidth(), box:getHeight()

    -- Determine background color based on checked state
    local bgColor = self.isChecked and self.checkedBackgroundColor or self.backgroundColor
    love.graphics.setColor(bgColor)
    love.graphics.rectangle("fill", x, y, w, h)

    -- Determine border color based on checked state
    local borderColor = self.isChecked and self.checkedBorderColor or self.borderColor
    love.graphics.setColor(borderColor)
    love.graphics.setLineWidth(self.borderWidth)
    love.graphics.rectangle("line", x, y, w, h)

    -- Draw the checkmark if the checkbox is checked
    if self.isChecked then
        love.graphics.setColor(self.checkColor)
        local checkSize = self.checkmarkSize
        local offset = (self.size - checkSize) / 2
        love.graphics.setLineWidth(self.borderWidth * 2)
        -- Centered checkmark coordinates
        love.graphics.line(x + offset, y + offset + checkSize / 2, x + offset + checkSize / 2, y + offset + checkSize)
        love.graphics.line(x + offset + checkSize / 2, y + offset + checkSize, x + offset + checkSize, y + offset)
    end

    -- Draw the text next to the checkbox
    if self.text ~= "" then
        local textColor = self.isChecked and self.checkedFontColor or self.fontColor
        love.graphics.setColor(textColor)
        love.graphics.draw(self.textDrawable, x + self.size + 5, y + (self.size - self.textHeight) / 2)
    end
end

-- Handle mouse press events
function CheckBox:mousepressed(x, y, button)
    if button == 1 and self:isInBounds(x, y) then
        self.isPressed = true
    end
end

-- Handle mouse release events
function CheckBox:mousereleased(x, y, button)
    if button == 1 and self.isPressed then
        if self:isInBounds(x, y) then
            self.isChecked = not self.isChecked
            self.onCheckChanged(self.isChecked)
        end
        self.isPressed = false
    end
end

-- Handle mouse movement events for hover state
function CheckBox:mousemoved(x, y)
    self.isHovered = self:isInBounds(x, y)
end

-- Check if mouse is within the component's bounds
function CheckBox:isInBounds(x, y)
    local box = self:getBoundingBox()
    return x >= box.left and x <= box.right and y >= box.top and y <= box.bottom
end

-- Set the checkbox check color
function CheckBox:setCheckColor(color)
    self.checkColor = color
end

-- Set the checkbox background color
function CheckBox:setBackgroundColor(color)
    self.backgroundColor = color
end

-- Set the checkbox checked background color
function CheckBox:setCheckedBackgroundColor(color)
    self.checkedBackgroundColor = color
end

-- Set the checkbox border color
function CheckBox:setBorderColor(color)
    self.borderColor = color
end

-- Set the checkbox checked border color
function CheckBox:setCheckedBorderColor(color)
    self.checkedBorderColor = color
end

-- Set the checkbox border width
function CheckBox:setBorderWidth(width)
    self.borderWidth = width
end

-- Set the checkbox text
function CheckBox:setText(text)
    self.text = text
    self:updateDrawable()
end

-- Set the checkbox checkmark size
function CheckBox:setCheckmarkSize(size)
    self.checkmarkSize = size
end

-- Set the checkbox checkmark offset
function CheckBox:setCheckmarkOffset(offset)
    self.checkmarkOffset = offset
end

-- Set the checkbox padding
function CheckBox:setPadding(padding)
    self.padding = padding
end

-- Get the bounding box of the checkbox
function CheckBox:getBoundingBox()
    return {
        left = self.x,
        top = self.y,
        right = self.x + self.size,
        bottom = self.y + self.size,
        getWidth = function(self) return self.right - self.left end,
        getHeight = function(self) return self.bottom - self.top end
    }
end

return CheckBox
