local Component = require("carbon.lib.component")
local Button = setmetatable({}, { __index = Component })
Button.__index = Button

-- Gradient shader code
local gradientShaderCode = [[
    extern vec4 color1;
    extern vec4 color2;
    vec4 effect(vec4 color, Image tex, vec2 tex_coords, vec2 screen_coords) {
        float t = tex_coords.y;
        return mix(color1, color2, t);
    }
]]

function Button:new(x, y, width, height, text, options)
    options = options or {}  -- Ensure options is a table, default to empty table if nil
    
    local instance = setmetatable(Component.new(self, x, y, width, height), self)
    instance.text = text or ""
    instance.onClick = options.onClick or function() end

    -- Default properties
    instance.font = options.font or love.graphics.newFont(14)  -- Customizable font
    instance.fontColor = options.fontColor or {0, 0, 1, 1}  -- Default text color is blue
    instance.upColor = options.upColor or {1, 1, 1, 1}  -- Default button color is solid white
    instance.downColor = options.downColor or {0.6, 0.6, 0.6, 1}
    instance.hoverColor = options.hoverColor or {0.9, 0.9, 0.9, 1}
    instance.disableColor = options.disableColor or {0.5, 0.5, 0.5, 1}
    instance.clickColor = options.clickColor or {1, 0, 0, 1}  -- Customizable click color
    instance.strokeColor = options.strokeColor or {0, 0, 0, 1}
    instance.stroke = options.stroke or 1
    instance.iconImg = nil
    instance.iconDir = options.iconDir or "left"  -- Customizable icon direction
    instance.iconAndTextSpace = options.iconAndTextSpace or 6  -- Space between icon and text
    instance.roundness = options.roundness or 0  -- Customizable roundness
    instance.enabled = options.enabled ~= nil and options.enabled or true
    instance.textAlignment = options.textAlignment or "center"  -- Customizable text alignment ("left", "center", "right")
    instance.padding = options.padding or {left = 10, right = 10, top = 5, bottom = 5}  -- Customizable padding
    instance.shadowColor = options.shadowColor or {0, 0, 0, 0.5}  -- Shadow effect color
    instance.shadowOffset = options.shadowOffset or {x = 2, y = 2}  -- Shadow offset
    instance.customDrawFunction = options.customDrawFunction or nil  -- Custom draw function

    -- Create gradient shader
    instance.gradientShader = love.graphics.newShader(gradientShaderCode)

    -- Precompute dimensions
    instance:updateDrawable()

    return instance
end

function Button:setPosition(x, y)
    self.x = x
    self.y = y
end

function Button:getPosition()
    return self.x, self.y
end

function Button:updateDrawable()
    -- Update text drawable
    self.textDrawable = love.graphics.newText(self.font, self.text)
    
    -- Calculate dimensions
    self.textWidth = self.textDrawable:getWidth()
    self.textHeight = self.textDrawable:getHeight()
    if self.iconImg then
        self.iconWidth = self.iconImg:getWidth()
        self.iconHeight = self.iconImg:getHeight()
    else
        self.iconWidth = 0
        self.iconHeight = 0
    end
end

-- Draw the button
function Button:draw()
    if self.customDrawFunction then
        self.customDrawFunction(self)
        return
    end

    local box = self:getBoundingBox()
    local x, y = box.left, box.top
    local w, h = box:getWidth(), box:getHeight()

    -- Determine button color based on state
    local color
    if not self.enabled then
        color = self.disableColor
    elseif self.isPressed then
        color = self.clickColor
    elseif self.isHovered then
        color = self.hoverColor
    else
        color = self.upColor
    end

    -- Draw shadow if enabled
    if self.shadowColor and self.shadowOffset then
        love.graphics.setColor(self.shadowColor)
        love.graphics.rectangle("fill", x + self.shadowOffset.x, y + self.shadowOffset.y, w, h, self.roundness)
    end

    -- Check if the color is a gradient
    if type(color) == "table" and #color == 2 then
        -- Draw gradient
        local gradient = love.graphics.newCanvas(w, h)
        love.graphics.setCanvas(gradient)
        love.graphics.setShader(self.gradientShader)
        self.gradientShader:send("color1", color[1])
        self.gradientShader:send("color2", color[2])
        love.graphics.rectangle("fill", 0, 0, w, h, self.roundness)
        love.graphics.setShader()
        love.graphics.setCanvas()

        -- Draw the gradient respecting the rounded corners
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(gradient, x, y)
    else
        -- Draw solid color rectangle with rounded corners
        love.graphics.setColor(color)
        love.graphics.rectangle("fill", x, y, w, h, self.roundness)
    end

    -- Draw button border
    if self.enabled and self.stroke then
        love.graphics.setColor(self.strokeColor)
        love.graphics.setLineWidth(self.stroke)
        love.graphics.rectangle("line", x, y, w, h, self.roundness)
    end

    -- Calculate text and icon positions
    local space = (self.iconImg and self.textWidth > 0) and self.iconAndTextSpace or 0
    local allWidth = space + self.textWidth + self.iconWidth

    local textX = x + self.padding.left
    local textY = (h - self.textHeight) / 2 + y + self.padding.top - self.padding.bottom
    local iconX = 0
    local iconY = (h - self.iconHeight) / 2 + y

    if self.textAlignment == "center" then
        textX = x + (w - allWidth) / 2
    elseif self.textAlignment == "right" then
        textX = x + w - allWidth - self.padding.right
    end

    if self.iconDir == "left" then
        iconX = textX
        textX = iconX + self.iconWidth + space
    else
        iconX = textX + self.textWidth + space
    end

    -- Draw text
    if self.textDrawable then
        love.graphics.setColor(self.fontColor)
        love.graphics.draw(self.textDrawable, textX, textY)
    end

    -- Draw icon
    if self.iconImg then
        love.graphics.draw(self.iconImg, iconX, iconY)
    end
end

-- Handle mouse press events
function Button:mousepressed(x, y, button)
    if button == 1 and self.enabled then
        local box = self:getBoundingBox()
        if x >= box.left and x <= box.right and y >= box.top and y <= box.bottom then
            self.isPressed = true
        end
    end
end

-- Handle mouse release events
function Button:mousereleased(x, y, button)
    if button == 1 and self.isPressed then
        local box = self:getBoundingBox()
        if x >= box.left and x <= box.right and y >= box.top and y <= box.bottom then
            self.onClick()
        end
        self.isPressed = false
    end
end

-- Handle mouse movement events for hover state
function Button:mousemoved(x, y)
    local box = self:getBoundingBox()
    self.isHovered = x >= box.left and x <= box.right and y >= box.top and y <= box.bottom
end

-- Set the button icon image
function Button:setIcon(icon)
    self.iconImg = love.graphics.newImage(icon)
    self:updateDrawable()
end

-- Set the button icon direction
function Button:setIconDir(dir)
    self.iconDir = dir
end

-- Set the button label text
function Button:setText(text)
    self.text = text
    self:updateDrawable()
end

-- Set the button up color
function Button:setUpColor(color)
    self.upColor = color
end

-- Set the button down color
function Button:setDownColor(color)
    self.downColor = color
end

-- Set the button hover color
function Button:setHoverColor(color)
    self.hoverColor = color
end

-- Set the button disable color
function Button:setDisableColor(color)
    self.disableColor = color
end

-- Set the button click color
function Button:setClickColor(color)
    self.clickColor = color
end

-- Set the button roundness
function Button:setRoundness(roundness)
    self.roundness = roundness
end

function Button:setCustomDrawFunction(drawFunction)
    self.customDrawFunction = drawFunction
end

-- Define the getBoundingBox method
function Button:getBoundingBox()
    return {
        left = self.x,
        top = self.y,
        right = self.x + self.width,
        bottom = self.y + self.height,
        getWidth = function(self) return self.right - self.left end,
        getHeight = function(self) return self.bottom - self.top end
    }
end

return Button
