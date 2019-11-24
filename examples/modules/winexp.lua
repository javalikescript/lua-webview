local winapiLib = require('winapi')

local viewportLeft, viewportTop = -10240, -10240
local viewportRight, viewportBottom = 10240, 10240
local minimizedLeft, minimizedTop = -32000, -32000
local minWidth, minHeight = 5, 5

local currentWindow

local WINDOW_TEXT = 'Window Explorer'
local HIDDEN_WINDOW_TEXT = 'Hidden '..WINDOW_TEXT

local winexp = {}

local function isViewableWindow(w)
  local width, height = w:get_bounds()
  if width > minWidth and height > minHeight then
    local left, top = w:get_position()
    if left == minimizedLeft and top == minimizedTop then -- special posision when minimized
      return true
    end
    local right, bottom = left + width, top + height
    return left < viewportRight and top < viewportBottom and right > viewportLeft and bottom > viewportTop
  end
  return false
end

local function isTopLevelWindow(w)
  local pw = w:get_parent()
  return pw and pw:get_handle()
end

local function isUserWindow(w)
  return isTopLevelWindow(w) and isViewableWindow(w) and w:get_text() ~= nil
end

local function isVisibleWindow(w)
  return w:is_visible() and isViewableWindow(w)
end

local function getWindowInfos(w)
  if not w then
    return nil
  end
  local width, height = w:get_bounds()
  local left, top = w:get_position()
  local text = w:get_text()
  if text and #text > 128 then
    text = string.sub(text, 1, 125)..'...'
  end
  local p = w:get_process()
  return {
    handle = w:get_handle(),
    text = text,
    visible = w:is_visible(),
    width = width,
    height = height,
    left = left,
    top = top,
    pid = p and p:get_pid(),
  }
end

function winexp.printWindow(w)
  if w then
    local i = getWindowInfos(w)
    print(i.handle, string.format('0x%08x', i.pid), i.visible, string.format('%dx%d', i.left, i.top), string.format('%dx%d', i.width, i.height), i.text)
  end
end

function winexp.findWindow(m)
  return winapiLib.find_window_ex(m or isViewableWindow)
end

function winexp.listWindows(m, t)
  if not m then
    m = isViewableWindow
  end
  if not t then
    return winapiLib.find_all_windows(m)
  end
  local list = {}
  winapiLib.enum_windows(function(w)
    if m(w) then
      table.insert(list, t(w))
    end
  end)
  return list
end

function winexp.listWindowsInfos()
  return winexp.listWindows(isUserWindow, getWindowInfos)
end

local SW_HIDE = 0 -- Hides the window and activates another window
local SW_SHOW = 5 -- Activates the window and displays it in its current size and position
local SW_SHOWNA = 8 -- Displays the window in its current size and position

function winexp.getWindowByHandle(h)
  return winapiLib.find_window_ex(function(w)
    return w:get_handle() == h
  end)
end

function winexp.toggleWindowByHandle(h)
  local w = winexp.getWindowByHandle(h)
  if w then
    w:show(w:is_visible() and SW_HIDE or SW_SHOWNA)
  end
end

function winexp.foregroundWindowByHandle(h)
  local w = winexp.getWindowByHandle(h)
  if w then
    w:set_foreground()
  end
end

function winexp.lookForCurrentWindow()
  if not currentWindow then
    -- we could not see our own window so we check the foreground one with our pid
    local w = winapiLib.get_foreground_window()
    if w then
      local pid = winapiLib.get_current_pid()
      local p = w:get_process()
      if p and p:get_pid() == pid then
        currentWindow = w
      end
    end
  end
  return currentWindow
end

function winexp.hideCurrentSession()
  local cw = winexp.lookForCurrentWindow()
  if cw then
    cw:show(SW_HIDE)
    cw:set_text(HIDDEN_WINDOW_TEXT)
  end
end

function winexp.restoreHiddenSession()
  local pw = winapiLib.find_window_ex(function(w)
    return not w:is_visible() and w:get_text() == HIDDEN_WINDOW_TEXT
  end)
  if not pw then
    return false
  end
  local cw = winexp.lookForCurrentWindow()
  if cw then
    --local width, height = cw:get_bounds()
    --local left, top = cw:get_position()
    --pw:resize(left, top, width, height)
    pw:set_text(WINDOW_TEXT)
    pw:show(SW_SHOW)
    cw:show(SW_HIDE)
    print('Restoring hidden session')
    return true
  end
  return false
end

winapiLib.set_encoding(winapiLib.CP_UTF8)

local pmw = winapiLib.find_window('Progman', 'Program Manager')
if pmw then
  local width, height = pmw:get_bounds()
  viewportLeft, viewportTop = pmw:get_position()
  viewportRight = viewportLeft + width
  viewportBottom = viewportTop + height
end

return winexp
