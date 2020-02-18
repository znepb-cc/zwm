local applications = {
  {
    title = "Task Manager",
    path = "/bin/tskmgr.lua",
    settings = {
      x = 2,
      y = 3,
      width = 30,
      height = 15
    }
  },
  {
    title = "Shell",
    path = "/rom/programs/shell.lua",
    settings = {
      x = 2,
      y = 3,
      width = 20,
      height = 10
    }
  }
}

local function draw()
  term.setBackgroundColor(colors.gray)
  term.clear()
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