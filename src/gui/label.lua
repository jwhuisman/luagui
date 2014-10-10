local common = require 'gui.common'

local Label = {}
local metatable = common.create_metatable(Label)
common.add_position(metatable, 'label')
common.add_size(metatable, 'label')
common.add_label(metatable, 'label', 'text')

function Label.create(parent)
  local label = {
    parent = parent
  }
  
  label.wx = wx.wxStaticText(
    parent.wx_panel or parent.wx,
    wx.wxID_ANY,
    '',
    wx.wxDefaultPosition,
    wx.wxDefaultSize
  )
  
  common.propagate_events(label)
  common.add_mouse_events(label)
  
  setmetatable(label, metatable)
  label.anchor = 'top left'
  
  return label
end

return Label