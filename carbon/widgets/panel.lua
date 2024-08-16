local Component = require("carbon.lib.component")
local Panel = setmetatable({}, { __index = Component })
Panel.__index = Panel

-- Constructor for Panel
function Panel:new(x, y, width, height, options)
    local instance = setmetatable(Component.new(self, x, y, width, height), self)
    instance.options = options or {}
    instance.padding = instance.options.padding or {top = 0, right = 0, bottom = 0, left = 0}
    instance.margin = instance.options.margin or {top = 0, right = 0, bottom = 0, left = 0}
    instance.backgroundColor = instance.options.backgroundColor or {0.9, 0.9, 0.9, 1}
    instance.borderColor = instance.options.borderColor or {0.7, 0.7, 0.7, 1}
    instance.borderWidth = instance.options.borderWidth or 0
    instance.scrollX = 0
    instance.scrollY = 0
    instance.clipping = instance.options.clipping ~= false -- Default to true
    instance.autoScale = instance.options.autoScale ~= false -- Default to false
    instance.roundness = instance.options.roundness or 0 -- Default to 0 for no rounding
    instance.canvas = love.graphics.newCanvas(width, height) -- Initialize canvas

    -- Save initial dimensions
    instance.originalWidth = width
    instance.originalHeight = height

    return instance
end

function Panel:draw()
    love.graphics.setCanvas(self.canvas)
    love.graphics.clear()

    -- Draw background
    love.graphics.setColor(self.backgroundColor)
    if self.roundness > 0 then
        love.graphics.rectangle("fill", 0, 0, self.width, self.height, self.roundness)
    else
        love.graphics.rectangle("fill", 0, 0, self.width, self.height)
    end

    -- Draw border
    if self.borderWidth > 0 then
        love.graphics.setColor(self.borderColor)
        love.graphics.setLineWidth(self.borderWidth)
        if self.roundness > 0 then
            love.graphics.rectangle("line", 0, 0, self.width, self.height, self.roundness)
        else
            love.graphics.rectangle("line", 0, 0, self.width, self.height)
        end
    end

    -- Apply clipping if enabled
    if self.clipping then
        love.graphics.setScissor(self.padding.left, self.padding.top,
                                 self.width - self.padding.left - self.padding.right,
                                 self.height - self.padding.top - self.padding.bottom)
    end

    -- Draw child elements with respect to padding and scroll
    love.graphics.push()
    love.graphics.translate(-self.scrollX - self.padding.left, -self.scrollY - self.padding.top)
    for _, child in ipairs(self.children) do
        child:draw()
    end
    love.graphics.pop()

    -- Disable clipping
    if self.clipping then
        love.graphics.setScissor()
    end

    love.graphics.setCanvas()

    -- Draw the canvas to the screen
    love.graphics.setColor(1, 1, 1)
    love.graphics.draw(self.canvas, self.x, self.y)
end

function Panel:addChild(child)
    -- Ensure the child is not nil
    if child == nil then
        print("Error: Attempted to add a nil child to the panel.")
        return
    end

    -- Adjust child position for padding
    child.x = self.padding.left + child.x
    child.y = self.padding.top + child.y

    -- Calculate initial scale based on panel's original size if autoScale is enabled
    if self.autoScale then
        child.scaleX = (self.width - self.padding.left - self.padding.right) / self.originalWidth
        child.scaleY = (self.height - self.padding.top - self.padding.bottom) / self.originalHeight
    else
        child.scaleX = 1
        child.scaleY = 1
    end

    Component.addChild(self, child) -- Assuming Component has addChild method
end


function Panel:update(dt)
    -- Update child elements
    for _, child in ipairs(self.children) do
        child:update(dt)
    end
end

function Panel:resize(w, h)
    -- Handle panel resize
    self.width = w
    self.height = h
    self.canvas = love.graphics.newCanvas(w, h) -- Recreate the canvas with the new dimensions

    -- Resize and scale children if autoScale is enabled
    if self.autoScale then
        local scaleX = (self.width - self.padding.left - self.padding.right) / self.originalWidth
        local scaleY = (self.height - self.padding.top - self.padding.bottom) / self.originalHeight

        -- Resize and scale children
        for _, child in ipairs(self.children) do
            child.width = self.originalWidth * scaleX
            child.height = self.originalHeight * scaleY
            child.scaleX = scaleX
            child.scaleY = scaleY

            -- Maintain child positions relative to the panel's new dimensions
            child.x = (child.x - self.padding.left) * scaleX + self.padding.left
            child.y = (child.y - self.padding.top) * scaleY + self.padding.top

            if child.resize then
                child:resize(child.width, child.height)
            end
        end
    end
end

function Panel:getMaxScrollY()
    local maxY = 0
    for _, child in ipairs(self.children) do
        local childMaxY = child.y + child.height
        if childMaxY > maxY then
            maxY = childMaxY
        end
    end
    return math.max(0, maxY + self.padding.top + self.padding.bottom - self.height)
end

function Panel:mousepressed(x, y, button)
    -- Adjust x and y for scrolling and padding
    local adjustedX = x - self.x + self.scrollX - self.padding.left
    local adjustedY = y - self.y + self.scrollY - self.padding.top
    if adjustedX >= 0 and adjustedX <= self.width and adjustedY >= 0 and adjustedY <= self.height then
        for _, child in ipairs(self.children) do
            child:mousepressed(adjustedX, adjustedY, button)
        end
    end
end

function Panel:mousereleased(x, y, button)
    -- Adjust x and y for scrolling and padding
    local adjustedX = x - self.x + self.scrollX - self.padding.left
    local adjustedY = y - self.y + self.scrollY - self.padding.top
    if adjustedX >= 0 and adjustedX <= self.width and adjustedY >= 0 and adjustedY <= self.height then
        for _, child in ipairs(self.children) do
            child:mousereleased(adjustedX, adjustedY, button)
        end
    end
end

function Panel:mousemoved(x, y, dx, dy)
    -- Adjust x and y for scrolling and padding
    local adjustedX = x - self.x + self.scrollX - self.padding.left
    local adjustedY = y - self.y + self.scrollY - self.padding.top
    if adjustedX >= 0 and adjustedX <= self.width and adjustedY >= 0 and adjustedY <= self.height then
        for _, child in ipairs(self.children) do
            if child.mousemoved then
                child:mousemoved(adjustedX, adjustedY, dx, dy)
            end
        end
    end
end

function Panel:wheelmoved(dx, dy)
    -- Implement logic to handle scrolling with the mouse wheel
    self.scrollY = math.max(0, math.min(self.scrollY - dy * 10, self:getMaxScrollY()))
    -- Forward to children
    for _, child in ipairs(self.children) do
        if child.wheelmoved then
            child:wheelmoved(dx, dy)
        end
    end
end

function Panel:keypressed(key)
    for _, child in ipairs(self.children) do
        if child.keypressed then
            child:keypressed(key)
        end
    end
end

function Panel:keyreleased(key)
    for _, child in ipairs(self.children) do
        if child.keyreleased then
            child:keyreleased(key)
        end
    end
end

function Panel:textinput(text)
    for _, child in ipairs(self.children) do
        if child.textinput then
            child:textinput(text)
        end
    end
end

return Panel
