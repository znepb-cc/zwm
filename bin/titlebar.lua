local ok, err = pcall(function()
  local menuPID
  local hiddenNames = {"menu", "titlebar"}
  local running = {}
  local procList

  local function draw()
    procList = wm.listProcesses()

    term.setBackgroundColor(colors.gray)
    term.clear()
    term.setCursorPos(1,1)
    term.setTextColor(colors.lightGray)
    if menuPID and procList[menuPID] then
      term.setTextColor(colors.white)
    else
      menuPID = nil
    end
    term.write("@ ")
    term.setTextColor(colors.lightGray)

    for i, v in pairs(procList) do
      if not table.contains(hiddenNames, v.title) then
        if v == wm.getSelectedProcess() then
          term.setTextColor(colors.white)
        else
          term.setTextColor(colors.lightGray)
        end
        local ins = v
        local x, y = term.getCursorPos()
        v.startX = x
        term.write(v.title .. " ")
        local x, y = term.getCursorPos()
        v.endX = x
        v.pid = i
        table.insert(running, v)
      end
    end
  end

  while true do
    local e = {os.pullEvent()}
    draw()
    if e[1] == "mouse_click" then
      local m, x, y = e[2], e[3], e[4]
      if x == 1 and y == 1 then
        if menuPID and wm.listProcesses()[menuPID] == nil then
          menuPID = nil
        else
          if menuPID ~= nil then
            wm.endProcess(menuPID)
            menuPID = nil
          else
            menuPID = wm.createProcess("/menu.lua", {
              x = 1,
              y = 2,
              width = 13,
              height = 12,
              showTitlebar = false
            })

            wm.selectProcess(menuPID)
          end
        end
      else
        local pid
        for i, v in pairs(running) do
          if x >= v.startX and x <= v.endX then
            pid = v.pid
          end
        end

        if pid then
          if procList[pid].minimized then
            wm.unminimizeProcess(pid)
          end
          wm.selectProcess(pid)
        end
      end
    end
  end
end)

print(ok, err)