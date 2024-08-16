local Component = require("carbon.lib.component")
local ScrollBar = setmetatable({}, { __index = Component })
ScrollBar.__index = ScrollBar

function ScrollBar:new(x, y, length, orientation, contentLength, viewLength)
    local width = orientation == "horizontal" and length or 20
    local height = orientation == "vertical" and length or 20
    local instance = Component.new(self, x, y, width, height)
    instance.orientation = orientation
    instance.position = 0 -- Scroll position (0 to 1)
    instance.contentLength = contentLength or length -- Total length of the scrollable content
    instance.viewLength = viewLength or length -- Viewport length
    instance.dragging = false
    instance.dragOffset = 0
    instance.canvas = love.graphics.newCanvas(width, height)
    return instance
end

function ScrollBar:drawToCanvas()
    love.graphics.setCanvas(self.canvas)
    love.graphics.clear()

    -- Draw the scrollbar background
    love.graphics.setColor(0.6, 0.6, 0.6)
    love.graphics.rectangle("fill", 0, 0, self.width, self.height)

    -- Calculate scrollbar thumb size and position
    local thumbSize = math.max(self.viewLength / self.contentLength * (self.orientation == "horizontal" and self.width or self.height), 20)
    local maxOffset = (self.orientation == "horizontal" and self.width or self.height) - thumbSize
    local thumbPos = self.position * maxOffset

    -- Draw the scrollbar thumb
    love.graphics.setColor(0.4, 0.4, 0.4)
    if self.orientation == "horizontal" then
        love.graphics.rectangle("fill", thumbPos, 0, thumbSize, self.height)
    else
        love.graphics.rectangle("fill", 0, thumbPos, self.width, thumbSize)
    end

    love.graphics.setCanvas()
end

function ScrollBar:update(dt)
    if self.dragging then
        local mx, my = love.mouse.getPosition()
        local mousePos = self.orientation == "horizontal" and mx or my
        local thumbSize = math.max(self.viewLength / self.contentLength * (self.orientation == "horizontal" and self.width or self.height), 20)
        local maxOffset = (self.orientation == "horizontal" and self.width or self.height) - thumbSize

        local newPosition = math.min(math.max((mousePos - self.dragOffset - (self.orientation == "horizontal" and self.x or self.y)) / maxOffset, 0), 1)
        self.position = newPosition
        self:setRedrawFlag()
    end
end

function ScrollBar:mousepressed(x, y, button)
    if button == 1 then
        local thumbSize = math.max(self.viewLength / self.contentLength * (self.orientation == "horizontal" and self.width or self.height), 20)
        local maxOffset = (self.orientation == "horizontal" and self.width or self.height) - thumbSize
        local thumbPos = self.position * maxOffset

        if self.orientation == "horizontal" then
            if x >= self.x + thumbPos and x <= self.x + thumbPos + thumbSize and y >= self.y and y <= self.y + self.height then
                self.dragging = true
                self.dragOffset = x - (self.x + thumbPos)
            end
        else
            if x >= self.x and x <= self.x + self.width and y >= self.y + thumbPos and y <= self.y + thumbPos + thumbSize then
                self.dragging = true
                self.dragOffset = y - (self.y + thumbPos)
            end
        end
    end
end

function ScrollBar:mousereleased(x, y, button)
    if button == 1 then
        self.dragging = false
    end
end

function ScrollBar:getScrollOffset()
    return self.position * (self.contentLength - self.viewLength)
end

return ScrollBar
