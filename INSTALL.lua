print("Starting installer...")
local rootPath

local args = { ... }

local function getFile(name)
    local file, second = http.get(rootPath .. name)
    local content
    if file then
        content = file.readAll()
    end
    return content, second
end

local function downloadFile(name)
    local content = getFile(name)
    local file = fs.open(name, "w")
    file.write(content)
    file.close()
    return true
end

local function getInstallationInformation(tag)
    rootPath = "https://raw.githubusercontent.com/znepb-cc/zwm/" .. tag or "zwm"
    print("Fetching installation information...")
    local inst, err = getFile("/inst/installation.lua")
    if not inst then
        printError(("Could not fetch installation information for branch %s."):format(tag))
        return
    else
        instData = textutils.unserialize(inst)
    end
    if not instData then
        error("Error parsing installing information")
    end
    return instData
end

local function getLatestTag()
    rootPath = "https://raw.githubusercontent.com/znepb-cc/zwm/zwm"
    print("Fetching latest tag...")
    local release, err = getFile("/inst/tag.txt")
    if err then
        printError("Could not fetch release tag. Please try again later.")
        return
    end
    return release
end

local function install(inst, release)
    print(("Got version %s"):format(release))
    print(("Release type: %s"):format(inst.releaseType))
    write(("Required space: %d"):format(inst.spaceRequirement))
    if fs.getFreeSpace("/") < inst.spaceRequirement then
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
end

if not args[1] then
    local tag = getLatestTag()
    local inst = getInstallationInformation(tag)
    install(inst, tag)
elseif args[1] == "dev" then
    print("Development version selected - expect bugs")
    local inst = getInstallationInformation("zwm")
    if not inst then
        return
    end
    install(inst, "development")
else
    local inst = getInstallationInformation(args[1])
    if not inst then
        return
    end
    install(inst, args[1])
end
