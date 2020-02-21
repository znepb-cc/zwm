local tw, th = wm.getSize()

local applications = {
  {
    title = "Task Manager",
    path = "/bin/ui/tskmgr.lua",
    settings = {
      width = 30,
      height = 15,
      title = "Task Manager"
    }
  },
  {
    title = "Shell",
    path = "bin/shell.lua",
    settings = {
      title = "Shell"
    }
  },
  {
    title = "Power",
    path = "/bin/ui/shutdown.lua",
    settings = {
      height = 6,
      showTitlebar = false,
      dontShowInTitlebar = true,
      title = "Power"
    }
  }
}

local util = require("/lib/util")
local file = util.loadModule("file")
local theme = file.readTable("/etc/colors.cfg")
local wm = _G.wm

local function draw()
  term.setBackgroundColor(theme.menu.background)
  term.clear()
  term.setTextColor(theme.menu.text)
  for i, v in pairs(applications) do
    print(v.title)
  end
end

draw()

while true do
  local e = {os.pullEvent()}
  if e[1] == "mouse_click" then
    local m, x, y = e[2], e[3], e[4]
    for i, v in pairs(applications) do
      if y == i then
        wm.endProcess(id)
        wm.selectProcess(wm.createProcess(v.path, v.settings))
      end
    end
  end
end