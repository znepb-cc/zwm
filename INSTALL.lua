print("Starting installer...")
local rootPath = "https://raw.githubusercontent.com/znepb-cc/zwm/zwm"

local function getFile(name)
    local file = http.get(rootPath .. name)
    local content = file.readAll()
    return content
end

local function downloadFile(name)
    local content = getFile(name)
    local file = fs.open(name, "w")
    file.write(content)
    file.close()
    return true
end

print("Downloading installation information...")
local inst = textutils.unserialize(getFile("/inst/installation.lua"))
print(("Got version %d.%d"):format(inst.release[1], inst.release[2]))
print(("Release type: %s"):format(inst.releaseType))
write(("Required space: %d"):format(inst.spaceRequirement))
if fs.getFreeSpace("/") < inst.spaceRequirement then
    print()
    printError("Unable to install zwm. Reason: Not enough space")
else
    print(" (OK)")
end

print(("Setup will create %d directories and will install %d files."):format(#inst.directories, #inst.files))
write("Confirm? Y/n ")
local ready = read()
if string.lower(ready) == "n" then
    print("Installation canceled.")
else
    print("Creating directories...")
    for i, v in pairs(inst.directories) do 
        print(("Creating: %s"):format(v))
        fs.makeDir(v)
    end

    print("Downloading files...")
    for i, v in pairs(inst.files) do 
        print(("Downloading: %s"):format(v))
        downloadFile(v)
    end

    print("Installation complete")
    local sha256 = require("/lib/sha256")

    print("Please set a username and password")
    write("Username: ")
    local username = read()
    write("Password: ")
    local password = sha256(read(" "))
    local data = {
        {
            name = username,
            passwordHash = password,
            homeDir = "/home/" .. username
        }
    }

    local file = fs.open("/etc/accounts.cfg", "w")
    file.write(textutils.serialize(data))
    file.close()

    print("Set information")
    write("Restart now? Y/n ")
    local rsn = read()
    if string.lower(rsn) ~= "n" then
        os.reboot()
    end
end