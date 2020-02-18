local util = {}
local json

if fs.exists("/json.lua") or fs.exists("/lib/json.lua") then
    json = require("json")
end

function util.resetColorScheme()
    term.setBackgroundColor(colors.black)
    term.setTextColor(colors.white)
end

function util.resetPalleteColors()
end

function util.resetCursorPos()
    term.setCursorPos(1,1)
end

function util.reset()
    util.resetColorScheme()
    term.clear()
    util.resetCursorPos()
    return true
end

function util.read(path)
    if fs.exists(path) then
        local file = fs.open(path, "r")
        local content = file.readAll()
        file.close()
        return content
    end
end

function util.write(path, contents)
    local file = fs.open(path, "w")
    file.write(contents)
    file.close()
    return true
end

function util.writeTable(path, table)
    return util.write(path, textutils.serialize(table))
end

function util.readTable(path)
    if fs.exists(path) then
        return textutils.unserialize(util.read(path))
    end
end

function util.readTableAsJSON(path)
    if json then
        local content = util.read(path)
        return json.decode(content)
    end
end

function util.writeTableAsJSON(path, tbl)
    if json then
        local content = util.write(path, json.encode(tbl))
    end
end

function util.fetch(url)
    local file = http.get(url)
    local content = file.readAll()
    return content
end

function util.tableContains(tbl, elem)
    for i, v in pairs(tbl) do
        if elem == v then
            return true 
        end
    end
    return false
end

return util