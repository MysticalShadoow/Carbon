-- ui/init.lua
local Carbon = {}

-- Require core components
Carbon.Base = require("carbon.lib.component")
Carbon.Button = require("carbon.widgets.button")
Carbon.TextBox = require("carbon.widgets.textbox")
Carbon.ScrollBar = require("carbon.widgets.scrollbar")
Carbon.Panel = require("carbon.widgets.panel")
Carbon.CheckBox = require("carbon.widgets.checkbox")
Carbon.RadioButton = require("carbon.widgets.radiobutton")
Carbon.Switch = require("carbon.widgets.switch")
Carbon.Divider = require("carbon.widgets.divider")
Carbon.Picture = require("carbon.widgets.picture")
Carbon.Slider = require("carbon.widgets.slider")
Carbon.TextLabel = require("carbon.widgets.textlabel")
Carbon.ProgressBar = require("carbon.widgets.progressbar")

return Carbon
