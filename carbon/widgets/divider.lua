local Component = require("carbon.lib.component")
local Divider = setmetatable({}, { __index = Component })
Divider.__index = Divider

function Divider:new(x, y, length, options)
    local instance = setmetatable(Component.new(self, x, y, length, 1), self)
    instance.length = length or 100
    instance.thickness = options.thickness or 2
    instance.color = options.color or {0, 0, 0, 1}
    instance.secondaryColor = options.secondaryColor or {1, 1, 1, 1}  -- For double lines or custom designs
    instance.style = options.style or "solid"  -- "solid", "dotted", "dashed", "double"
    instance.orientation = options.orientation or "horizontal"  -- "horizontal" or "vertical"
    instance.margin = options.margin or 0
    instance.padding = options.padding or 0
    instance.roundness = options.roundness or 0
    instance.gradient = options.gradient or nil  -- Optional gradient color
    instance.shadow = options.shadow or false  -- Add shadow effect
    instance.shadowColor = options.shadowColor or {0, 0, 0, 0.5}  -- Shadow color
    instance.x = x
    instance.y = y
    
    return instance
end

function Divider:draw()
    local x, y = self.x, self.y
    local length = self.length
    local thickness = self.thickness

    if self.orientation == "vertical" then
        length, thickness = thickness, length
    end

    -- Apply shadow if enabled
    if self.shadow then
        love.graphics.setColor(self.shadowColor)
        love.graphics.rectangle("fill", x + 2, y + 2, length, thickness, self.roundness)
    end

    -- Set the color and draw the divider
    love.graphics.setColor(self.color)

    if self.gradient then
        local r, g, b, a = unpack(self.gradient)
        local gradientMesh = love.graphics.newMesh({
            {0, 0, 0, 0, unpack(self.color)},
            {length, 0, 1, 0, r, g, b, a}
        }, "strip", "static")
        love.graphics.draw(gradientMesh, x, y)
    else
        if self.style == "solid" then
            love.graphics.rectangle("fill", x, y, length, thickness, self.roundness)
        elseif self.style == "dotted" then
            local dotSize = thickness
            local spacing = dotSize * 2
            for i = 0, length, spacing do
                love.graphics.rectangle("fill", x + i, y, dotSize, thickness, self.roundness)
            end
        elseif self.style == "dashed" then
            local dashSize = thickness * 4
            local spacing = dashSize * 2
            for i = 0, length, spacing do
                love.graphics.rectangle("fill", x + i, y, dashSize, thickness, self.roundness)
            end
        elseif self.style == "double" then
            -- Draw the first line
            love.graphics.rectangle("fill", x, y, length, thickness, self.roundness)
            -- Set secondary color and draw the second line
            love.graphics.setColor(self.secondaryColor)
            love.graphics.rectangle("fill", x, y + thickness + self.padding, length, thickness, self.roundness)
        end
    end
end

-- Setter methods for customization
function Divider:setThickness(thickness) self.thickness = thickness end
function Divider:setColor(color) self.color = color end
function Divider:setSecondaryColor(color) self.secondaryColor = color end
function Divider:setStyle(style) self.style = style end
function Divider:setOrientation(orientation) self.orientation = orientation end
function Divider:setMargin(margin) self.margin = margin end
function Divider:setPadding(padding) self.padding = padding end
function Divider:setRoundness(roundness) self.roundness = roundness end
function Divider:setGradient(gradient) self.gradient = gradient end
function Divider:setShadow(shadow) self.shadow = shadow end
function Divider:setShadowColor(color) self.shadowColor = color end

return Divider
