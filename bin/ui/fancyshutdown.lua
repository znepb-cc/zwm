term.setBackgroundColor(colors.cyan)
term.clear()
local args = { ... }
local w, h = term.getSize()

term.setCursorPos(w / 2 - string.len("Goodbye") / 2, h / 2)
term.setTextColor(colors.white)
term.write("Goodbye")
term.setBackgroundColor(colors.black)
sleep(1)
for i = 1, h do
    term.setCursorPos(1, i)
    term.clearLine()
    sleep(0.05)
end

if args[1] == "shutdown" then
    os.shutdown()
elseif args[1] == "reboot" then
    os.reboot()
end