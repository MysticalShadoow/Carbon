local Component = {}
Component.__index = Component

function Component:new(x, y, width, height)
    local instance = setmetatable({}, self)
    instance.x = x or 0
    instance.y = y or 0
    instance.width = width or 100
    instance.height = height or 100
    instance.children = {}
    instance.needsRedraw = true
    return instance
end

function Component:addChild(child)
    table.insert(self.children, child)
    self.needsRedraw = true
end

function Component:draw()
    if self.needsRedraw then
        self:drawToCanvas()
        self.needsRedraw = false
    end
    love.graphics.draw(self.canvas, self.x, self.y)
end

function Component:drawToCanvas()
    -- To be implemented by specific components
end

function Component:update(dt)
    for _, child in ipairs(self.children) do
        child:update(dt)
    end
end

function Component:mousepressed(x, y, button)
    for _, child in ipairs(self.children) do
        child:mousepressed(x, y, button)
    end
end

function Component:mousereleased(x, y, button)
    for _, child in ipairs(self.children) do
        child:mousereleased(x, y, button)
    end
end

function Component:wheelmoved(dx, dy)
    for _, child in ipairs(self.children) do
        child:wheelmoved(dx, dy)
    end
end

return Component
