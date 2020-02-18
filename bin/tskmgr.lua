local selectedID = 0
local procList

local function draw()
  local w, h = term.getSize()
  term.setBackgroundColor(colors.white)
  term.clear()
  term.setTextColor(colors.white)
  term.setCursorPos(2,1)
  term.setBackgroundColor(colors.gray)
  term.clearLine()
  term.write("New task")
  term.setCursorPos(2,2)
  term.clearLine()
  term.write("PID")
  term.setCursorPos(7, 2)
  term.write("Name")
  procList = wm.listProcesses()
  term.setTextColor(colors.gray)
  local c = 3
  for i, v in pairs(procList) do
    term.setBackgroundColor(colors.white)
    term.setCursorPos(2, c)
    if selectedID == i then
      term.setBackgroundColor(colors.lightGray)
      term.clearLine()
    end
    term.write(i)
    term.setCursorPos(7, c)
    term.write(v.title)
    c = c + 1
  end

  if contextShown then
    drawContextMenu()
  end
end

while true do
  draw()
  local e = {os.pullEvent()}
  if e[1] == "mouse_click" then
    local m, x, y = e[2], e[3], e[4]
    if m == 1 then
      local c = 3
      for i, v in pairs(procList) do
        if y == c then
          selectedID = i
          break
        end
        c = c + 1
      end
      if x > 1 and x < 7 and y == 1 then
        wm.selectProcess(wm.createProcess(function()
          local function newTextbox(x, y, w, rchar)
            local prevTerm = term.current()
            local win = window.create(prevTerm, x, y, w, 1)
            win.setBackgroundColor(colors.gray)
            win.clear()
            win.setTextColor(colors.lightGray)
          
            local obj = {}
            
            obj.select = function()
              term.redirect(win)
              local input = read(rchar)
              term.redirect(prevTerm)
              return input
            end
          
            return obj
          end
          local w, h = term.getSize()
          term.setBackgroundColor(colors.white)
          term.clear()
          term.setCursorPos(2,2)
          term.setTextColor(colors.gray)
          term.write("Enter program path")
          local box = newTextbox(2, 4, w - 2)
          term.setCursorPos(2,6)
          term.setBackgroundColor(colors.gray)
          term.setTextColor(colors.lightGray)
          term.write(" Run ")
          local content = ""
          while true do
            local e = {os.pullEvent()}
            if e[1] == "mouse_click" then
              local m, x, y = e[2], e[3], e[4]
              if x >= 2 and x <= w - 2 and y == 4 then
                content = box.select()
              elseif x >= 2 and x <= 7 and y == 6 then
                wm.selectProcess(wm.createProcess(content, {
                  x = 2,
                  y = 3,
                  width = 20,
                  height = 10
                }))
                break
              end
            end
          end
        end, 
        {
          x = 2,
          y = 3,
          width = 24,
          height = 7
        }))
      end
    end
  elseif e[1] == "key" then
    local key = e[2]
    if key == keys.delete then
      wm.endProcess(selectedID)
    end
  end
end