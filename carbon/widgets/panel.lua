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

    instance.x = x
    instance.y = y

    -- Save initial dimensions
    instance.originalWidth = width
    instance.originalHeight = height

    -- Add property to enable or disable culling overlapping widgets
    instance.cullOverlapping = instance.options.cullOverlapping ~= false -- Default to true

    -- Initialize a table to keep track of widgets with exact coordinates
    instance.widgetMap = {}
    instance.cache = {} -- Cache for culled widgets

    return instance
end

-- Check if a widget is within the visible area of the panel
function Panel:isWidgetVisible(widget)
    local widgetX = widget.x + self.scrollX + self.padding.left
    local widgetY = widget.y + self.scrollY + self.padding.top
    local widgetWidth = widget.width
    local widgetHeight = widget.height

    return widgetX < self.width and widgetY < self.height and
           widgetX + widgetWidth > 0 and widgetY + widgetHeight > 0
end

-- Check if a widget overlaps with another
function Panel:isWidgetOverlapping(widget, otherWidget)
    return widget.x < otherWidget.x + otherWidget.width and
           widget.x + widget.width > otherWidget.x and
           widget.y < otherWidget.y + otherWidget.height and
           widget.y + widget.height > otherWidget.y
end

-- Track widgets at exact coordinates
function Panel:updateWidgetMap()
    self.widgetMap = {}

    for _, child in ipairs(self.children) do
        if self:isWidgetVisible(child) then
            local key = string.format("%d,%d", child.x, child.y)
            if not self.widgetMap[key] then
                self.widgetMap[key] = {}
            end
            table.insert(self.widgetMap[key], child)
        end
    end
end

-- Draw method with exact coordinate culling
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

    -- Update widget map
    self:updateWidgetMap()

    -- Draw child elements with respect to padding and scroll
    love.graphics.push()
    love.graphics.translate(-self.scrollX - self.padding.left, -self.scrollY - self.padding.top)

    for _, childList in pairs(self.widgetMap) do
        if self.cullOverlapping then
            if #childList == 1 then
                -- Draw non-overlapping widget
                childList[1]:draw()
            elseif #childList > 1 then
                -- Draw only the first widget in case of overlap
                childList[1]:draw()
                -- Cache the remaining widgets
                for i = 2, #childList do
                    table.insert(self.cache, childList[i])
                end
            end
        else
            -- Draw all widgets if culling is disabled
            for _, child in ipairs(childList) do
                child:draw()
            end
        end
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

-- Call this method to clear the cache
function Panel:clearCache()
    self.cache = {}
end

function Panel:markDirty()
    self.dirty = true
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

    -- Mark widget map as dirty
    self:markDirty()
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
