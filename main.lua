local UI = require("carbon")
local TextBox = require("carbon.widgets.textbox") -- Ensure this path is correct

local panel
local switch
local checkbox
local divider
local slider

function love.load()
    love.window.setMode(love.graphics.getWidth(), love.graphics.getHeight(), { vsync = 0 })
    print("starting electron")

    panel = UI.Panel:new(50, 50, 500, 500, { 
        backgroundColor = {0.9, 0.9, 0.9, 1},
        autoScale = false,  -- Enable auto-scaling
        roundness = 15
    })

    checkbox = UI.CheckBox:new(50, 200, 20, {
        isChecked = false,
        backgroundColor = {1, 1, 1, 1},
        borderColor = {0, 0, 0, 1},
        borderWidth = 2,
        checkColor = {0, 0, 0, 1},
        text = "Check me",
        fontColor = {0, 0, 0, 1},
        onCheckChanged = function(checked)
            print("Checkbox checked state: " .. tostring(checked))
        end
    })

    panel:addChild(checkbox)

    
    local button = UI.Button:new(
        10, 300, 150, 50, "Click Me",
        {
            roundness = 10,
            textAlignment = "center",
        }
    )


    button:setRoundness(5)

    panel:addChild(button)

    switch = UI.Switch:new(100, 300, 25, {  -- Size is 40
        isChecked = true,
        text = "Enable Feature",
        textColor = {0, 0, 0, 1},
        textPosition = "right",
        textPadding = 15,
        ballOnCheckedColor = {0.2, 0.7, 0.2, 1},
        ballOnUncheckedColor = {0.7, 0.2, 0.2, 1},
        onClicked = function()
            print("Switch was clicked")
        end
    })

    switch.onCheckedChanged = function(isChecked)
            print("Switch checked state changed to: " .. tostring(isChecked))
        end

    slider = UI.Slider:new(50, 500, 400, 0, 100, 50, {
        trackColor = {0.9, 0.9, 0.9, 1},
        thumbColor = {0.2, 0.5, 0.8, 1},
        thumbRadius = 15,
        cornerRadius = 10,
        shadowColor = {0, 0, 0, 0.3},
        shadowOffsetX = 3,
        shadowOffsetY = 3,
        shadowBlur = 6,
    })

    local label = UI.TextLabel:new(100, 100, 200, 50, "Hello, World!", {
        font = love.graphics.newFont(20),
        textColor = {1, 1, 1, 1},  -- White text
        bgColor = {0, 0, 0, 1},    -- Black background
        roundness = 10,             -- Rounded corners
        hasStroke = false,           -- Enable stroke
        strokeColor = {1, 1, 1, 1},-- White stroke
        strokeWidth = 2             -- Stroke width
        -- No gradient provided, so default is used
    })

    progressBar = UI.ProgressBar:new(50, 50, 300, 30, {
        minValue = 0,
        maxValue = 100,
        currentValue = 50,
        barColor = {0, 1, 0, 1}, -- Green bar color
        bgColor = {0.8, 0.8, 0.8, 1}, -- Light gray background
        borderColor = {0, 0, 0, 1}, -- Black border
        borderWidth = 2,
        roundness = 5 -- Rounded corners
    })
    
    panel:addChild(label)
    panel:addChild(switch)
    panel:addChild(divider)
    panel:addChild(slider)
    panel:addChild(progressBar)
end

function love.mousepressed(x, y, button, istouch, presses)
    panel:mousepressed(x, y, button)
end

function love.mousereleased(x, y, button, istouch, presses)
    panel:mousereleased(x, y, button)
end

function love.mousemoved(x, y, dx, dy, istouch)
    panel:mousemoved(x, y, dx, dy)
end

function love.wheelmoved(x, y)
    panel:wheelmoved(x, y)
end

function love.update(dt)
    panel:update(dt)
    love.window.setTitle("Carbon TEST - " .. love.timer.getFPS() .. " FPS")

    local newValue = progressBar.currentValue + 10 * dt
    if newValue > progressBar.maxValue then
        newValue = progressBar.minValue
    end
    progressBar:setCurrentValue(newValue)
end

function love.draw()
    panel:draw()
end
