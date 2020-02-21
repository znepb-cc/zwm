local history = {}
term.setCursorPos(1, 1)
term.clear()
local shell = _G.shell

while true do
    local dir = shell.dir()
    if dir == "" then
        dir = "/"
    end
    term.setTextColor(colors.red)
    term.write("uph")
    term.setTextColor(colors.white)
    term.write("@")
    term.write(os.getComputerLabel() or os.getComputerID())
    term.write(" " .. dir .. " ")
    term.setTextColor(colors.white)
    term.write("# ")
    
    local input = read(nil, history)
    if input ~= history[#history] then
        table.insert(history, input)
    end
    shell.run(input)
end