local Component = require("carbon.lib.component")
local Picture = setmetatable({}, { __index = Component })
Picture.__index = Picture

function Picture:new(x, y, imagePath, options)
    local instance = setmetatable(Component.new(self, x, y), self)
    instance.options = options or {}
    instance.image = love.graphics.newImage(imagePath)
    instance.width = instance.options.width or instance.image:getWidth()
    instance.height = instance.options.height or instance.image:getHeight()
    instance.roundness = instance.options.roundness or 0
    instance.scaleX = instance.options.scaleX or 1
    instance.scaleY = instance.options.scaleY or 1
    instance.color = instance.options.color or {1, 1, 1, 1} -- Default to white (no tint)

    instance.x = x
    instance.y = y
    
    return instance
end

function Picture:draw()
    love.graphics.setColor(self.color)
    love.graphics.push()
    love.graphics.translate(self.x, self.y)
    love.graphics.scale(self.scaleX, self.scaleY)

    if self.roundness > 0 then
        -- Draw a rounded rectangle with the image as a pattern fill
        local function drawRoundedImage()
            love.graphics.draw(self.image, 0, 0, 0, self.width / self.image:getWidth(), self.height / self.image:getHeight())
        end

        love.graphics.stencil(drawRoundedImage, "replace", 1)
        love.graphics.setStencilTest("greater", 0)
        love.graphics.setColor(1, 1, 1, 1) -- Reset color to draw the image without tint
        drawRoundedImage()
        love.graphics.setStencilTest()
    else
        love.graphics.draw(self.image, 0, 0, 0, self.width / self.image:getWidth(), self.height / self.image:getHeight())
    end

    love.graphics.pop()
    love.graphics.setColor(1, 1, 1, 1) -- Reset color to default
end

function Picture:update(dt)
   
end

function Picture:resize(width, height)
    self.width = width
    self.height = height
end

return Picture
