local textbox = require("/lib/textbox")
local util = require('/lib/util')
local sha256 = require("/lib/sha256")
local file = util.loadModule("file")
local w, h = term.getSize()
local theme = _G.wm.getTheme()
local username = textbox.new(2, 2, w - 2, nil, "Username", nil, theme.userInput.background, theme.userInput.text)
local password = textbox.new(2, 4, w - 2, "\7", "Password", nil, theme.userInput.background, theme.userInput.text)

local logins = file.readTable("/etc/accounts.cfg")

local usrRaw = ""
local pswrdRaw = ""
local errorText = ""

local function draw()
    local w, h = term.getSize()
    term.setBackgroundColor(theme.main.background)
    term.clear()
    username.redraw()
    password.redraw()
    term.setCursorPos(2,6)
    term.setBackgroundColor(theme.userInput.background)
    term.setTextColor(theme.userInput.text)
    term.write(" Login ")
    term.setCursorPos(10, 6)
    term.setBackgroundColor(theme.main.background)
    term.setTextColor(colors.red)
    term.write(errorText)

    local foregroundColor = theme.window.titlebar.background

    if wm.getSelectedProcessID() == id then
        foregroundColor = theme.window.titlebar.backgroundSelected
    end

    for i = 1, h - 1 do
        term.setCursorPos(1, i)
        term.setTextColor(foregroundColor)
        term.setBackgroundColor(theme.main.background)
        term.write("\149")
    end
    for i = 1, h - 1 do
        term.setCursorPos(w, i)
        term.setTextColor(theme.main.background)
        term.setBackgroundColor(foregroundColor)
        term.write("\149")
    end
    term.setCursorPos(2, h)
    term.setTextColor(theme.main.background)
    term.setBackgroundColor(foregroundColor)
    term.write(string.rep("\143", w - 2))

    term.setCursorPos(1, h)
    term.setTextColor(theme.main.background)
    term.setBackgroundColor(foregroundColor)
    term.write("\138")
    term.setCursorPos(w, h)
    term.setTextColor(theme.main.background)
    term.setBackgroundColor(foregroundColor)
    term.write("\133")
end

draw()
while true do
    draw()
    local e = {os.pullEvent()}
    if e[1] == "mouse_click" then
        local m, x, y = e[2], e[3], math.ceil(e[4])
        if x >= 2 and x <= w - 2 and y == 2 then
            usrRaw, goToNext = username.select()
            if goToNext then
                pswrdRaw = password.select()
            end
        elseif x >= 2 and x <= w - 2 and y == 4 then
            pswrdRaw = password.select()
        elseif x >= 2 and x <= 7 and y == 6 then
            local found = false
            for i, v in pairs(logins) do
                if sha256(pswrdRaw) == v.passwordHash and v.name == usrRaw then
                    os.queueEvent("wm_login", usrRaw)
                    found = true
                    wm.endProcess(id)
                end
            end
            if not found then
                errorText = "Incorrect"
            end
        end
    end
end
