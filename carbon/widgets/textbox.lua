local Component = require("carbon.lib.component")
local TextBox = setmetatable({}, { __index = Component })
TextBox.__index = TextBox

-- Helper functions to split and join text
local function splitText(text, delimiter)
    local result = {}
    for match in (text .. delimiter):gmatch("(.-)" .. delimiter) do
        table.insert(result, match)
    end
    return result
end

local function joinText(textTable, delimiter)
    return table.concat(textTable, delimiter)
end

-- Create shaders
local backgroundShader = love.graphics.newShader([[
vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
    vec4 fixedColor = vec4(1.0, 1.0, 1.0, 1.0); // Static color, replace as needed
    return fixedColor * texture2D(texture, texture_coords);
}
]])

local selectionShader = love.graphics.newShader([[
extern vec4 color;
vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
    vec4 texColor = texture2D(texture, texture_coords);
    return color * texColor;
}
]])

function TextBox:new(x, y, width, height, text, color, font, theme, enableScrolling)
    local instance = setmetatable(Component.new(self, x, y, width, height), TextBox)
    instance.backgroundShader = backgroundShader
    instance.selectionShader = selectionShader

    instance.text = text or ""
    instance.cursor = #instance.text + 1
    instance.selectionStart = 1
    instance.selectionEnd = 1
    instance.color = color or {1, 1, 1, 1}
    instance.textColor = {0, 0, 0, 1}
    instance.backgroundColor = {1, 1, 1, 1}
    instance.font = font or love.graphics.getFont()
    instance.focused = false
    instance.canvas = love.graphics.newCanvas(width, height)
    instance.showCursor = false
    instance.cursorBlinkRate = 0.5
    instance.cursorBlinkTimer = 0
    instance.scrollX = 0
    instance.scrollY = 0
    instance.lineNumbers = false
    instance.undoStack = {}
    instance.redoStack = {}
    instance.shaderColor = {0.8, 0.8, 1, 1} -- Default shader color
    instance.enableScrolling = enableScrolling

    instance.isBackspaceHeld = false
    instance.backspaceTimer = 0
    instance.backspaceDelay = 0.1 -- Delay for continuous backspace

    instance.theme = theme or {
        placeholderText = "Enter text...",
        textAlignment = "left",
        multiLine = true,
        wordWrap = true,
        maxLines = 10
    }
    instance:applyTheme()
    return instance
end

function TextBox:applyTheme()
    self.placeholderText = self.theme.placeholderText
    self.textAlignment = self.theme.textAlignment
    self.multiLine = self.theme.multiLine
    self.wordWrap = self.theme.wordWrap
    self.maxLines = self.theme.maxLines
end

function TextBox:drawToCanvas()
    love.graphics.setCanvas(self.canvas)
    love.graphics.clear()

    -- Draw background
    love.graphics.setShader(self.backgroundShader)
    love.graphics.rectangle("fill", 0, 0, self.width, self.height)
    love.graphics.setShader()

    -- Draw text with optional line numbers
    local lines = splitText(self.text, '\n')
    local xOffset = 5 + (self.lineNumbers and 40 or 0)
    local yOffset = 5
    local lineHeight = self.font:getHeight()

    love.graphics.setColor(self.textColor)

    -- Calculate the visible line range for culling
    local firstVisibleLine = math.floor(self.scrollY / lineHeight) + 1
    local lastVisibleLine = firstVisibleLine + math.floor(self.height / lineHeight) - 1

    -- Ensure indices are within bounds
    firstVisibleLine = math.max(1, firstVisibleLine)
    lastVisibleLine = math.min(#lines, lastVisibleLine)

    for i = firstVisibleLine, lastVisibleLine do
        local line = lines[i]
        local lineText = line:sub(self.scrollX + 1, self.scrollX + self.width)
        love.graphics.print(lineText, xOffset, yOffset + (i - firstVisibleLine) * lineHeight)
    end

    -- Draw selection using shader
    if self.selectionStart ~= self.selectionEnd then
        love.graphics.setShader(self.selectionShader)
        self.selectionShader:send("color", self.shaderColor) -- Use default shader color
        local startPos, endPos = math.min(self.selectionStart, self.selectionEnd), math.max(self.selectionStart, self.selectionEnd)
        local selectionStartX = xOffset + self.font:getWidth(self.text:sub(1, startPos - 1)) - self.scrollX
        local selectionEndX = xOffset + self.font:getWidth(self.text:sub(1, endPos - 1)) - self.scrollX
        local selectionY = yOffset + (self:getLineForCursor() - firstVisibleLine) * lineHeight
        local selectionHeight = lineHeight

        love.graphics.rectangle("fill", selectionStartX, selectionY, selectionEndX - selectionStartX, selectionHeight)
        love.graphics.setShader()
    end

    -- Draw placeholder text if needed
    if #self.text == 0 then
        love.graphics.setColor(0.6, 0.6, 0.6, 1)
        love.graphics.print(self.placeholderText, xOffset, yOffset)
    end

    -- Draw cursor if focused and cursor should be shown
    if self.focused and self.showCursor then
        local lineIndex = self:getLineForCursor()
        local cursorLine = lines[lineIndex]
        local cursorX = xOffset + self.font:getWidth(cursorLine:sub(1, self.cursor - 1)) - self.scrollX
        local cursorY = yOffset + (lineIndex - firstVisibleLine) * lineHeight
        love.graphics.setColor(0, 0, 0)
        love.graphics.line(cursorX, cursorY, cursorX, cursorY + lineHeight)
    end

    love.graphics.setCanvas()
end


function TextBox:draw()
    love.graphics.draw(self.canvas, self.x, self.y)
end

function TextBox:keypressed(key)
    if self.focused then
        if key == "backspace" then
            self.isBackspaceHeld = true
            self.backspaceTimer = 0
            self:removeChar()
        elseif key == "left" then
            self:moveCursor(-1, 0)
        elseif key == "right" then
            self:moveCursor(1, 0)
        elseif key == "up" then
            self:moveCursor(0, -1)
        elseif key == "down" then
            self:moveCursor(0, 1)
        elseif key == "return" then
            self:insertNewline()
        elseif key == "tab" then
            self:insertChar('  ')
        elseif key == "c" and love.keyboard.isDown("lctrl") then
            self:copy()
        elseif key == "v" and love.keyboard.isDown("lctrl") then
            self:paste()
        elseif key == "z" and love.keyboard.isDown("lctrl") then
            self:undo()
        elseif key == "y" and love.keyboard.isDown("lctrl") then
            self:redo()
        end

        self.showCursor = true
        self.cursorBlinkTimer = 0
        self:drawToCanvas()
    end
end

function TextBox:keyreleased(key)
    if key == "backspace" then
        self.isBackspaceHeld = false
        self.backspaceTimer = 0
    end
end

function TextBox:textinput(text)
    if self.focused then
        self:insertChar(text)
        self.showCursor = true
        self.cursorBlinkTimer = 0
        self:drawToCanvas()
    end
end

function TextBox:mousepressed(x, y, button)
    if button == 1 and self:isMouseOver(x, y) then
        self.focused = true
        self:calculateCursorPosition(x, y)
        self.selectionStart = self.cursor
        self.selectionEnd = self.cursor
    else
        self.focused = false
    end
    self:drawToCanvas()
end

function TextBox:mousemoved(x, y, dx, dy)
    if love.mouse.isDown(1) and self.focused then
        self:calculateCursorPosition(x, y)
        self.selectionEnd = self.cursor
        self:drawToCanvas()
    end
end

function TextBox:isMouseOver(x, y)
    return x >= self.x and x <= self.x + self.width and y >= self.y and y <= self.y + self.height
end

function TextBox:getLineForCursor()
    local lines = splitText(self.text, '\n')
    local lineStart = 1
    for i, line in ipairs(lines) do
        local lineEnd = lineStart + #line
        if self.cursor >= lineStart and self.cursor <= lineEnd then
            return i
        end
        lineStart = lineEnd + 1
    end
    return 1
end


function TextBox:insertChar(char)
    if self.selectionStart ~= self.selectionEnd then
        self:deleteSelection()
    end

    local beforeCursor = self.text:sub(1, self.cursor - 1)
    local afterCursor = self.text:sub(self.cursor)
    self.text = beforeCursor .. char .. afterCursor
    self.cursor = self.cursor + #char
    self.selectionStart = self.cursor
    self.selectionEnd = self.cursor
    self:drawToCanvas()
end

function TextBox:removeChar()
    if self.selectionStart ~= self.selectionEnd then
        self:deleteSelection()
    elseif self.cursor > 1 then
        local beforeCursor = self.text:sub(1, self.cursor - 2)
        local afterCursor = self.text:sub(self.cursor)
        self.text = beforeCursor .. afterCursor
        self.cursor = self.cursor - 1
    end
    self.selectionStart = self.cursor
    self.selectionEnd = self.cursor
    self:drawToCanvas()
end


function TextBox:insertNewline()
    if self.selectionStart ~= self.selectionEnd then
        self:deleteSelection()
    end

    -- Insert the newline at the current cursor position
    local beforeCursor = self.text:sub(1, self.cursor - 1)
    local afterCursor = self.text:sub(self.cursor)
    self.text = beforeCursor .. '\n' .. afterCursor

    -- Move cursor to the position after the new line
    self.cursor = #beforeCursor + 2  -- Position just after the new line

    -- Recalculate the scroll position if needed
    local lineIndex = self:getLineForCursor()
    local lineHeight = self.font:getHeight()
    local totalLines = #splitText(self.text, '\n')
    local visibleLines = math.floor(self.height / lineHeight)

    if lineIndex > self.scrollY + visibleLines - 1 then
        self.scrollY = math.max(0, totalLines - visibleLines)
    end

    -- Update the canvas with the new text
    self:recordUndo("newline", self.text)
    self:drawToCanvas()
end

function TextBox:moveCursor(x, y)
    local lines = splitText(self.text, '\n')
    local lineIndex = self:getLineForCursor()
    local line = lines[lineIndex]

    -- Move cursor horizontally
    if x ~= 0 then
        local newPos = self.cursor + x
        if newPos < 1 then newPos = 1 end
        if newPos > #self.text + 1 then newPos = #self.text + 1 end
        self.cursor = newPos
    end

    -- Move cursor vertically
    if y ~= 0 then
        local lineHeight = self.font:getHeight()
        local newIndex = lineIndex + y
        if newIndex < 1 then newIndex = 1 end
        if newIndex > #lines then newIndex = #lines end
        line = lines[newIndex]
        local newPos = math.min(#line + 1, self.cursor)
        self.cursor = newPos
    end

    self:drawToCanvas()
end

function TextBox:adjustCursorForLineChange(lineIndex, y)
    local lines = splitText(self.text, '\n')
    local newLineIndex = lineIndex + y
    newLineIndex = math.max(1, math.min(#lines, newLineIndex))

    local newLine = lines[newLineIndex]
    local lineWidth = self.font:getWidth(newLine)
    local cursorPos = self.cursor - self.font:getWidth(lines[lineIndex]) + self.font:getWidth(newLine)

    if cursorPos > lineWidth then
        cursorPos = lineWidth
    elseif cursorPos < 1 then
        cursorPos = 1
    end

    return cursorPos + (newLineIndex - 1) * lineWidth
end

function TextBox:getLineForCursor()
    local lines = splitText(self.text, '\n')
    local lineStart = 1
    for i, line in ipairs(lines) do
        local lineEnd = lineStart + #line
        if self.cursor >= lineStart and self.cursor <= lineEnd then
            return i
        end
        lineStart = lineEnd + 1
    end
    return #lines
end

function TextBox:calculateCursorPosition(x, y)
    local lines = splitText(self.text, '\n')
    local lineHeight = self.font:getHeight()
    local localY = y - self.y
    local lineIndex = math.floor(localY / lineHeight) + 1
    lineIndex = math.min(#lines, math.max(1, lineIndex))
    local line = lines[lineIndex]
    local localX = x - self.x
    local cursorX = self.scrollX
    local cursorIndex = 1

    for i = 1, #line do
        local width = self.font:getWidth(line:sub(1, i))
        if localX <= width then
            cursorIndex = i
            break
        end
    end

    self.cursor = cursorIndex
end

function TextBox:scroll(amount)
    local lineHeight = self.font:getHeight()
    self.scrollY = math.max(0, self.scrollY + amount)
    self:drawToCanvas()
end

function TextBox:getGlobalCursorPos(lineIndex, cursorPosition)
    local lines = splitText(self.text, '\n')
    local globalPos = 0

    for i = 1, lineIndex - 1 do
        globalPos = globalPos + #lines[i] + 1 -- +1 for the newline character
    end

    return globalPos + cursorPosition
end

function TextBox:deleteSelection()
    local startPos = math.min(self.selectionStart, self.selectionEnd)
    local endPos = math.max(self.selectionStart, self.selectionEnd)
    self.text = self.text:sub(1, startPos - 1) .. self.text:sub(endPos)
    self.cursor = startPos
    self.selectionStart = self.cursor
    self.selectionEnd = self.cursor
    self:recordUndo("delete", self.text)
end

function TextBox:undo()
    if #self.undoStack > 0 then
        local action = table.remove(self.undoStack)
        table.insert(self.redoStack, {action = action, text = self.text})
        if action.action == "remove" then
            self.text = action.text
        elseif action.action == "insert" then
            self.text = action.text
        elseif action.action == "newline" then
            self.text = action.text
        end
        self.cursor = action.cursor
    end
    self:drawToCanvas()
end

function TextBox:redo()
    if #self.redoStack > 0 then
        local action = table.remove(self.redoStack)
        table.insert(self.undoStack, {action = action, text = self.text})
        if action.action == "remove" then
            self.text = action.text
        elseif action.action == "insert" then
            self.text = action.text
        elseif action.action == "newline" then
            self.text = action.text
        end
        self.cursor = action.cursor
    end
    self:drawToCanvas()
end

function TextBox:copy()
    if self.selectionStart ~= self.selectionEnd then
        local startPos = math.min(self.selectionStart, self.selectionEnd)
        local endPos = math.max(self.selectionStart, self.selectionEnd)
        local selectedText = self.text:sub(startPos, endPos - 1)
        love.system.setClipboardText(selectedText)
    end
end

function TextBox:paste()
    local clipboardText = love.system.getClipboardText()
    if clipboardText then
        self:insertChar(clipboardText)
    end
end

function TextBox:recordUndo(action, text)
    table.insert(self.undoStack, {action = action, text = text, cursor = self.cursor})
end

function TextBox:getSelectedText()
    if self.selectionStart == self.selectionEnd then return "" end
    local startPos, endPos = math.min(self.selectionStart, self.selectionEnd), math.max(self.selectionStart, self.selectionEnd)
    return self.text:sub(startPos, endPos - 1)
end

function TextBox:getLineForCursor()
    local lines = splitText(self.text, '\n')
    local cursorLine = 1
    local position = 0

    for i, line in ipairs(lines) do
        position = position + #line + 1
        if position > self.cursor then
            cursorLine = i
            break
        end
    end

    return cursorLine
end

function TextBox:scroll(dx, dy)
    if self.enableScrolling then
        self.scrollX = math.max(0, self.scrollX + dx)
        self.scrollY = math.max(0, self.scrollY + dy)
        self:drawToCanvas()
    end
end

function TextBox:update(dt)
    if self.focused then
        self.cursorBlinkTimer = self.cursorBlinkTimer + dt
        if self.cursorBlinkTimer >= self.cursorBlinkRate then
            self.showCursor = not self.showCursor
            self.cursorBlinkTimer = 0
        end

        -- Handle continuous backspace deletion with delay
        -- if self.isBackspaceHeld then
        --     self.backspaceTimer = self.backspaceTimer + dt
        --     if self.backspaceTimer >= self.backspaceDelay then
        --         if not self.isBackspaceHeld then return end
        --         self:removeChar()
        --         self:drawToCanvas()
        --         self.backspaceTimer = 0 
        --     end
        -- end
    else
        self.showCursor = false
    end
end


return TextBox
