local logs = {}

local function log(text)
  table.insert(logs, os.epoch('utc') .. " " .. text)
end

local function dumpLogs()
  local f = fs.open("dump.log", "w")
  f.write(table.concat(logs, "\n"))
  f.close()
end

local function main()
  local processes = {}
  local selectedProcessID = 0
  local selectedProcess
  local lastProcID = 0
  local native = term.current()
  local wm = {}
  local w, h = term.getSize()
  local titlebarID = 0

  local resizeStartX
  local resizeStartY
  local resizeStartW
  local resizeStartH
  local mvmtX = nil

  local util = require("/lib/util")
  local file = util.loadModule("file")
  local theme = file.readTable("/etc/colors.cfg")

  local top = 0

  local function updateProcesses()
    for i, v in pairs(processes) do
      term.redirect(v.window)
      coroutine.resume(v.coroutine)
    end
  end

  local function drawProcess(proc)
    if proc.showTitlebar == false then
      term.redirect(proc.window)
      if proc.maximazed then
        proc.window.reposition(1, 2, w, h - 1)
      else
        proc.window.reposition(proc.x, proc.y, proc.w, proc.h)
      end
      proc.window.redraw()
    else
      term.redirect(native)
      
      if proc.maximazed then
        proc.window.reposition(1, 3, w, h - 2)
        if proc == selectedProcess then
          paintutils.drawLine(1, 2, w, 2, theme.window.titlebar.backgroundSelected)
        else
          paintutils.drawLine(1, 2, w, 2, theme.window.titlebar.background)
        end
        term.setCursorPos(1, 2)
        term.setTextColor(theme.window.titlebar.text)
        term.write(proc.title)

        term.setCursorPos(w - 2, 2)
        if proc == selectedProcess then
          term.setTextColor(theme.window.minimize)
        else
          term.setTextColor(theme.window.titlebar.text)
        end
        term.write("\31")
        if proc == selectedProcess then
          term.setTextColor(theme.window.maximize) 
        else
          term.setTextColor(theme.window.titlebar.text)
        end
        term.write("-")
        if proc == selectedProcess then
          term.setTextColor(theme.window.close)
        else
          term.setTextColor(theme.window.titlebar.text)
        end
        term.write("\215")
      else
        proc.window.reposition(proc.x, proc.y + 1, proc.w, proc.h)
        if proc == selectedProcess then
          paintutils.drawLine(proc.x, proc.y, proc.x + proc.w - 1, proc.y, theme.window.titlebar.backgroundSelected)
        else
          paintutils.drawLine(proc.x, proc.y, proc.x + proc.w - 1, proc.y, theme.window.titlebar.background)
        end
        term.setCursorPos(proc.x, proc.y)
        term.setTextColor(theme.window.titlebar.text)
        term.write(proc.title)

        term.setCursorPos(proc.x + proc.w - 3, proc.y)
        if proc == selectedProcess then
          term.setTextColor(theme.window.minimize)
        else
          term.setTextColor(theme.window.titlebar.text)
        end
        term.write("\31")
        if proc == selectedProcess then
          term.setTextColor(theme.window.maximize)
        else
          term.setTextColor(theme.window.titlebar.text)
        end
        term.write("+")
        if proc == selectedProcess then
          term.setTextColor(theme.window.close)
        else
          term.setTextColor(theme.window.titlebar.text)
        end
        term.write("\215")
      end

      term.redirect(proc.window)
      proc.window.redraw()
    end
  end

  local function drawProcesses()
    term.redirect(native)
    term.setBackgroundColor(theme.desktop.background)
    term.clear()
    term.setCursorPos(1,5)
    if selectedProcess.minimized == true then
      selectedProcessID = 1
      selectedProcess = processes[1]
    end

    for i, v in pairs(processes) do
      if i ~= selectedProcessID then
        if v.minimized then
          v.window.setVisible(false)
        else
          drawProcess(v)
        end
      end
    end
    drawProcess(selectedProcess)
    updateProcesses()
  end

  function wm.selectProcess(pid)
    if processes[pid] then
      selectedProcessID = pid
      selectedProcess = processes[pid]
      selectedProcess.window.setVisible(true)
      selectedProcess.window.redraw()
      drawProcesses()
    end
  end

  function wm.selectProcessAfter(pid, time)
    sleep(time)
    wm.selectProcess(pid)
  end

  function wm.unminimizeProcess(pid)
    processes[pid].minimized = false
  end

  function wm.listProcesses()
    return processes
  end

  function wm.getSelectedProcess()
    return selectedProcess
  end

  function wm.endProcess(pid)
    local proc = processes[pid]
    if proc then
      if pid == selectedProcessID then
        wm.selectProcess(titlebarID)
      end
      proc.window.setVisible(false)
      processes[pid] = nil
      drawProcesses()
    end
  end

  local function removeDeadProcesses()
    for i, v in pairs(processes) do
      if coroutine.status(v.coroutine) == "dead" then
        wm.endProcess(i)
      end
    end
  end

  local function contains(tbl, elem)
    for i, v in pairs(tbl) do
      if elem == v then
        return true 
      end
    end
    return false
  end

  function wm.createProcess(path, settings)
    lastProcID  = lastProcID + 1
    if not settings.title and type(path) == "string" then
      settings.title = fs.getName(path)
      if settings.title:sub(-4) == ".lua" then
        settings.title = settings.title:sub(1, -5)
      end
    else
      settings.title = "Untitled"
    end

    if settings.showTitlebar == nil or settings.showTitlebar == true then
      settings.showTitlebar = true
    end

    local ins = {
      path = path,
      x = settings.x,
      y = settings.y,
      w = settings.width,
      h = settings.height,
      title = settings.title,
      showTitlebar = settings.showTitlebar,
      maximazed = settings.maximazed,
      minimized = settings.minimized
    }

    local newTable = table
    newTable["contains"] = contains

    local function run()
    end

    log(type(path))

    local req = _G.require

    if type(path) == "string" then
      run = function()
        _G.require = require
        _G.wm = wm
        _G.id = lastProcID
        _G.table = newTable

        os.run({
          _G = _G
        }, path)
      end
    elseif type(path) == "function" then
      log("running as func")
      run = function()
        local wm = wm
        local id = lastProcID
        local table = newTable
        local textbox = textbox

        path(textbox)
      end
    end

    ins.window = window.create(native, ins.x, ins.y, ins.w, ins.h)
    term.redirect(ins.window)
    ins.coroutine = coroutine.create(run)
    coroutine.resume(ins.coroutine)
    ins.window.redraw()

    table.insert(processes, lastProcID, ins)
    return lastProcID
  end

  titlebarID = wm.createProcess("/bin/titlebar.lua", {
    x = 1,
    y = 1,
    width = w,
    height = 1,
    showTitlebar = false,
    maximazed = false;
  })
  wm.selectProcess(titlebarID)

  drawProcesses()

  while true do
    local e = {os.pullEvent()}
    term.redirect(selectedProcess.window)
    if string.sub(e[1], 1, 6) == "mouse_" and not selectedProcess.minimized then
      local m, x, y = e[2], e[3], e[4]
      -- Resize checking
      if resizeStartX ~= nil and m == 2 then
        log(e[1])
        if e[1] == "mouse_up" then 
          resizeStartX = nil
          resizeStartY = nil
          resizeStartW = nil
          resizeStartH = nil
          drawProcesses()
        elseif e[1] == "mouse_drag" then
          selectedProcess.w = (resizeStartW + (x - resizeStartX))
          selectedProcess.h = (resizeStartH + (y - resizeStartY))
          term.redirect(selectedProcess.window)
          coroutine.resume(selectedProcess.coroutine, "term_resize")
          drawProcesses()
        end
      -- Moving windows & x and max / min buttons
      elseif not selectedProcess.minimized and not selectedProcess.maximazed and selectedProcess.showTitlebar and x >= selectedProcess.x and x <= selectedProcess.x + selectedProcess.w - 1 and y == selectedProcess.y and e[1] == "mouse_click" and mvmtX == nil then
        if x == selectedProcess.x + selectedProcess.w - 1 and e[1] == "mouse_click" then
          wm.endProcess(selectedProcessID)
          drawProcesses()
        elseif x == selectedProcess.x + selectedProcess.w - 2 and e[1] == "mouse_click" then
          selectedProcess.maximazed = true
          term.redirect(selectedProcess.window)
          coroutine.resume(selectedProcess.coroutine, "term_resize")
          drawProcesses()
        elseif x == selectedProcess.x + selectedProcess.w - 3 and e[1] == "mouse_click" then
          selectedProcess.minimized = true
          drawProcesses()
        else
          mvmtX = x - selectedProcess.x
          drawProcesses()
        end
      -- Max window controls
      elseif selectedProcess.maximazed == true and y == 2 then 
        if x == w and e[1] == "mouse_click" then
          wm.endProcess(selectedProcessID)
          drawProcesses()
        elseif x == w - 1 and e[1] == "mouse_click" then
          selectedProcess.maximazed = false
          term.redirect(selectedProcess.window)
          coroutine.resume(selectedProcess.coroutine, "term_resize")
          drawProcesses()
        elseif x == w - 2 then
          selectedProcess.minimized = true
          drawProcesses()
        end
      -- Window movement 
      elseif not selectedProcess.maximazed and selectedProcess.showTitlebar and x >= selectedProcess.x - 1 and x <= selectedProcess.x + selectedProcess.w and y >= selectedProcess.y - 1  and y <= selectedProcess.y + 1 and e[1] == "mouse_drag" or e[1] == "mouse_up" and mvmtX ~= nil then
        if e[1] == "mouse_drag" and mvmtX then
          selectedProcess.x = x - mvmtX + 1
          selectedProcess.y = y
          drawProcesses()
        else
          mvmtX = nil
        end
      elseif x == selectedProcess.x + selectedProcess.w - 1 and y == selectedProcess.y + selectedProcess.h and m == 2 then
        if e[1] == "mouse_click" then
          resizeStartX = x
          resizeStartY = y
          resizeStartW = selectedProcess.w
          resizeStartH = selectedProcess.h
          log("resize start")
        end
      -- Passing events (not maximazed)
      elseif not selectedProcess.maximazed and x >= selectedProcess.x and x <= selectedProcess.x + selectedProcess.w - 1 and y >= selectedProcess.y and y <= selectedProcess.y + selectedProcess.h - 1 then
        term.redirect(selectedProcess.window)
        local pass = {}
        if selectedProcess.showTitlebar == true then
          pass = {
            e[1],
            m,
            x - selectedProcess.x + 1,
            y - selectedProcess.y
          }
        else
          pass = {
            e[1],
            m,
            x - selectedProcess.x + 1,
            y - selectedProcess.y + 1
          }
        end
        coroutine.resume(selectedProcess.coroutine, table.unpack(pass))
      -- Passing events (maximazed)
      elseif selectedProcess.maximazed and y > 2 then
        term.redirect(selectedProcess.window)
        local pass = {}
        if selectedProcess.showTitlebar == true then
          pass = {
            e[1],
            m,
            x,
            y - 2
          }
        else
          pass = {
            e[1],
            m,
            x,
            y - 1
          }
        end
        coroutine.resume(selectedProcess.coroutine, table.unpack(pass))
      else
        for i, v in pairs(processes) do
          if x >= v.x and x <= v.x + v.w - 1 and y >= v.y and y <= v.y + v.h - 1 then
            wm.selectProcess(i)
            local pass = {}
            if selectedProcess.showTitlebar == true then
              pass = {
                e[1],
                m,
                x - selectedProcess.x + 1,
                y - selectedProcess.y
              }
            else
              pass = {
                e[1],
                m,
                x - selectedProcess.x + 1,
                y - selectedProcess.y + 1
              }
            end
            term.redirect(selectedProcess.window)
            coroutine.resume(selectedProcess.coroutine, table.unpack(pass))
            break
          end
        end
      end
    elseif e[1] == "char" or string.sub(e[1], 1, 3) == "key" or e[1] == "paste" then
      term.redirect(selectedProcess.window)
      coroutine.resume(selectedProcess.coroutine, table.unpack(e))
    else
      for i, v in pairs(processes) do
        term.redirect(v.window)
        coroutine.resume(v.coroutine, table.unpack(e))
        v.window.redraw()
      end
      drawProcesses()
    end
    term.redirect(selectedProcess.window)
    removeDeadProcesses()
    for i, v in pairs(processes) do
      if i ~= selectedProcessID then
        term.redirect(v.window)
        coroutine.resume(v.coroutine, "keepalive")
      end
    end
    if selectedProcess.minimized then
      wm.selectProcess(1)
    else
      drawProcess(selectedProcess)
    end
    log(tostring(selectedProcess.minimized))
  end
end

local ok, err = xpcall(main, function(err)
  term.redirect(term.native())
  term.setCursorPos(1, 1)
  term.setTextColor(colors.white)
  print("Fatal System Error:", err)
  local traceback = {debug.traceback()}
  local w, h = term.getSize()
  for i, v in pairs(traceback) do
    local x, y = term.getCursorPos()
    if y == h - 1 then
      write("...")
    elseif y < h - 1 then
      print(v)
    end
  end
  term.setCursorPos(1, 19)
  read()

  dumpLogs()
end)