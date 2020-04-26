term.clear()
term.setCursorPos(1, 1)
if fs.exists("/disk/startup") or fs.exists("/disk/startup.lua") then
    write("Press any key to boot from disk")

    parallel.waitForAny(function()
        os.pullEvent("char")
        if fs.exists("/disk/startup") then
            shell.run('/disk/startup')
        elseif fs.exists("/disk/startup.lua") then
            shell.run('/disk/startup')
        else
            print("\nFailed to boot to disk. Is the disk still inserted?")
            sleep(1)
        end
    end, function()
        for i = 1, 3 do 
            write(".")
            sleep(1)
        end
    end)
end

local w, h = term.getSize()
local fail = false

local function errorScreen(error, code)
    fail = true
    term.setBackgroundColor(colors.red)
    term.clear()
    term.setTextColor(colors.white)
    term.setCursorPos(2, 2)
    term.write("Oh no! A big red error!")
    term.setCursorPos(2, h - 4)
    print("Error Code: " .. code)
    term.setCursorPos(2, h - 2)
    print("[1] Reboot")
    term.setCursorPos(2, h - 1)
    print("[2] Boot to shell")

    local w, h = term.getSize()
    local errorContentWindow = window.create(term.native(), 2, 4, w - 2, h - 8)
    errorContentWindow.setBackgroundColor(colors.red)
    errorContentWindow.setTextColor(colors.white)
    errorContentWindow.clear()
    term.redirect(errorContentWindow)
    print(error)
    term.redirect(term.native())
    while true do
        local e = {os.pullEventRaw()}
        if e[1] == "key" then
            if e[2] == keys.one then
                os.reboot()
            elseif e[2] == keys.two then
                term.setBackgroundColor(colors.black)
                term.setCursorPos(1, 1)
                term.clear()
                sleep()
                shell.run("/rom/programs/shell.lua")
            end
        end
    end
end

local function loadtable(path)
    local file = fs.open(path, "r")
    local content = textutils.unserialize(file.readAll())
    file.close()
    return content
end

function yield()
	os.queueEvent("randomEvent")
	os.pullEvent("randomEvent")
end

if not term.isColor() then
    printError("Please use a color terminal")
    return false
end

local function init()
    local missingFiles = {}

    if fs.exists("/boot/files.cfg") then
        local files = loadtable("/boot/files.cfg")
        for i, v in pairs(files) do
            if not fs.exists(v) then
                table.insert(missingFiles, v)
            end
        end
    else
        errorScreen("The system could find the file list.\n\nzwm may not be installed correctly.", "BOOT-FNE-FL")
    end

    if #missingFiles > 0 then
        errorScreen(string.format("Missing files: %s\n\nzwm may not be installed correctly", table.concat(missingFiles, ", ")), "BOOT-MIS-MUL")
    end
    sleep(math.random(50, 300) * 0.01)
end

local function animate()
    local frames = {
        {i = false, c = "\129"},
        {i = false, c = "\130"},
        {i = false, c = "\136"},
        {i = true, c = "\159"},
        {i = false, c = "\144"},
        {i = false, c = "\132"},
    }

    local function drawFrame(frame)
        term.setBackgroundColor(colors.gray)
        term.setTextColor(colors.white)
        if frame.i then
            term.setBackgroundColor(colors.white)
            term.setTextColor(colors.gray)
        end
        write(frame.c)
    end

    term.setCursorPos(w / 2 - string.len("Starting zwm") / 2 + 1, h / 2 + 2)
    term.write("Starting zwm")

    while true do
        for i, frame in pairs(frames) do
            if fail then while true do sleep(1) end end
            term.setCursorPos(w/2, h/2)
            drawFrame(frame)
            sleep(0.25)
        end
    end
end

parallel.waitForAny(init, animate)
local syspath = loadtable("/boot/sys.path")
term.setBackgroundColor(colors.black)
sleep(0.2)
term.clear()
sleep(0.5)
shell.run(
    syspath[1]
)