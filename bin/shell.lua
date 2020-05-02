local history = {}
term.setCursorPos(1, 1)
term.clear()
local shell = _G.shell
local wm = _G.wm

while true do
    local dir = shell.dir()
    if dir == "" then
        dir = "/"
    end
    term.setTextColor(colors.orange)
    term.write(wm.currentUser)
    term.setTextColor(colors.white)
    term.write("@")
    term.setTextColor(colors.blue)
    term.write(os.getComputerLabel() or os.getComputerID())
    term.setTextColor(colors.white)
    term.write(":")
    term.setTextColor(colors.red)
    if dir ~= "/" then
        write("/" .. dir .. "\n")
    else
        write("/\n")
    end

    term.setTextColor(colors.white)
    local x, y = term.getCursorPos()
    local prevInput
    local input = ""
    local completion = ""
    local completionList = {}
    local completionIndex = 0
    local historyIndex = #history + 1
    term.setCursorBlink(true)

    local function drawInput()
        if input ~= "" then
            completionList = {}
            if shell.complete(input) and shell.complete(input)[1] then
                completion = shell.complete(input)[1]
            elseif shell.completeProgram(input) and shell.completeProgram(input)[1] then
                completion = shell.completeProgram(input)[1]
            else
                completion = ""
            end

            if shell.complete(input) and shell.complete(input)[completionIndex] then
                for i, v in pairs({shell.complete(input)}) do
                    table.insert(completionList, v)
                end
            end
            if shell.completeProgram(input) and shell.completeProgram(input)[completionIndex] then
                for i, v in pairs({shell.completeProgram(input)}) do
                    table.insert(completionList, v)
                end
            end
            if prevInput ~= input then
                completionIndex = 0
            end
        else
            completionList = {}
            completion = ""
        end
        term.setCursorPos(x, y)
        term.clearLine()
        term.setTextColor(colors.green)
        term.write("\26 ")
        term.setTextColor(colors.white)
        term.write(input)
        local iX, iY = term.getCursorPos()
        term.setTextColor(colors.gray)
        term.write(completion)
        term.setCursorPos(iX, iY)
        term.setTextColor(colors.white)
        prevInput = input
    end

    drawInput()

    while true do
        local e = {os.pullEvent()}
        if e[1] == "char" then
            input = input .. e[2]
            drawInput()
        elseif e[1] == "key" then
            if e[2] == keys.backspace then
                input = string.sub(input, 1, string.len(input) - 1)
                drawInput()
            elseif e[2] == keys.enter then
                print()
                break
            elseif e[2] == keys.up then
                if #completionList > 1 then
                    if history[completionIndex - 1] then
                        completion = completion[completionIndex - 1]
                        completionIndex = completionIndex - 1
                        drawInput()
                    end
                else
                    if history[historyIndex - 1] then
                        input = history[historyIndex - 1]
                        historyIndex = historyIndex - 1
                        drawInput()
                    end
                end
            elseif e[2] == keys.down then
                if #completionList > 1 then
                    if history[completionIndex + 1] then
                        completion = completion[completionIndex + 1]
                        completionIndex = completionIndex + 1
                        drawInput()
                    end
                else
                    if history[historyIndex + 1] then
                        input = history[historyIndex + 1]
                        historyIndex = historyIndex + 1
                        drawInput()
                    end
                end
            elseif e[2] == keys.tab then
                input = input .. completion
                drawInput()
            end
        end
    end
    if input ~= history[#history] then
        table.insert(history, input)
    end
    term.setTextColor(colors.white)
    term.setCursorBlink(false)
    shell.run(input)
    input = ""
end