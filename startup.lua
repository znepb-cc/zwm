term.clear()
term.setCursorPos(1, 1)
print("Initalizing system...")

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

local missingFiles = {}

print("checking system files...")
if fs.exists("/boot/files.cfg") then
    local files = loadtable("/boot/files.cfg")
    for i, v in pairs(files) do
        if fs.exists(v) then
            term.blit("[ OK ]", "005500", "ffffff")
            term.write(" " .. v)
        else
            term.blit("[FAIL]", "0eeee0", "ffffff")
            term.write(" " .. v)
            table.insert(missingFiles, v)
        end
        print()
    end
else
    term.blit("[FAIL]", "0eeee0", "ffffff")
    term.write(" /boot/files.cfg")
    print()
    printError("Missing /boot/files.cfg\nzwm may not be installed correctly")
    return false
end

if #missingFiles > 0 then
    printError(string.format("Missing files: %s\nzwm may not be installed correctly", table.concat(missingFiles, ", ")))
    return false
end

local syspath = loadtable("/boot/sys.path")
shell.run(
    syspath[1]
)