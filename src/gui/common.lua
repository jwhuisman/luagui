local common = {}
common.add_position = require 'gui.common.position'
common.add_client_size = require 'gui.common.client_size'
common.add_size = require 'gui.common.size'
common.add_label = require 'gui.common.label'
common.add_value = require 'gui.common.value'
common.add_anchor = require 'gui.common.anchor'
common.add_color = require 'gui.common.color'
common.add_text_color = require 'gui.common.text_color'

function common.create_metatable(class)
  return {
    -- Handles the setting of properties.
    -- object: the object on which to set the property
    -- key:    the name of the property
    -- value:  the value the property should be set to
    __newindex = function(object, key, value)
      local self = getmetatable(object)
      local getter = self['get_' .. key]
      local setter = self['set_' .. key]
      
      -- If there is no getter and no setter for the specified key, then it's
      -- business as usual and we shouldn't interfere.
      if getter == nil and setter == nil then
        rawset(object, key, value)
      end
      
      -- If there is a setter for the specified key, we should store the value
      -- returned by the setter somewhere, so the getter can access it later.
      -- We create a special value table for the object to do this and store
      -- the value table in the metatable.
      if setter ~= nil then
        self[object] = self[object] or {}
        self[object][key] = setter(object, value) or value
      end
      
      -- If there is a getter for the specified key, but no setter, we should
      -- store the raw value in the value table, so the getter can access it
      -- later. We can't store the value in the object itself, because then
      -- the __index metamethod won't be called anymore.
      if getter ~= nil and setter == nil then
        self[object] = self[object] or {}
        self[object][key] = value
      end
    end,

    -- Handles the getting of properties.
    -- object:  the object of which to get the property
    -- key:     the name of the property
    -- returns: the value of the property
    __index = function(object, key)
      local self = getmetatable(object)
      local getter = self['get_' .. key]
      local setter = self['set_' .. key]
      
      -- If there is a getter for the specified key, call it and return its
      -- value.
      if getter ~= nil then
        return getter(object)
      end
      
      -- If there is no getter for the specified key, but there is a setter,
      -- then the setter might have stored a value in the value table. If not,
      -- the setter hasn't been called yet and we should return nil.
      if setter ~= nil then
        if self[object] == nil then
          return nil
        end
        
        return self[object][key]
      end
      
      -- If there is no getter and no setter for the specified key, we should
      -- treat the object as a normal table. If the object doesn't contain the
      -- specified key, look up the key in the object's class.
      return rawget(object, key) or class[key]
    end
  }
end

function common.add_event(object, event_name, wx_event, ...)
  local params = { ... }
  local trigger_event = function(event)
    if type(object[event_name]) == 'function' then
      if type(params[1]) == 'function' then
        object[event_name](object, params[1](event))
      else
        object[event_name](object, unpack(params))
      end
    end
  end
  
  if object.wx_panel then
    object.wx_panel:Connect(wx_event, trigger_event)
  else
    object.wx:Connect(wx_event, trigger_event)
  end
end

function common.propagate_events(object, wx_events)
  local propagate = function(event)
    event:ResumePropagation(1)
    event:Skip()
  end
  
  wx_events = wx_events or {
    wx.wxEVT_MOTION,
    wx.wxEVT_LEFT_DOWN,
    wx.wxEVT_LEFT_UP,
    wx.wxEVT_MIDDLE_DOWN,
    wx.wxEVT_MIDDLE_UP,
    wx.wxEVT_RIGHT_UP,
    wx.wxEVT_RIGHT_DOWN }
  
  for _, wx_event in ipairs(wx_events) do
    object.wx:Connect(wx_event, propagate)
  end
end

function common.add_mouse_events(object)
  common.mouse_listeners = common.mouse_listeners or {}
  table.insert(common.mouse_listeners, object)
end

return common