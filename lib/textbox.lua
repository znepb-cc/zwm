local function newTextbox(x, y, w, rchar)
    local prevTerm = term.current()
    local win = window.create(prevTerm, x, y, w, 1)
    win.setBackgroundColor(colors.gray)
    win.clear()
    win.setTextColor(colors.lightGray)

    local obj = {

    }

    obj.select = function()
        term.redirect(win)
        local input = read(rchar)
        term.redirect(prevTerm)
        return input
    end

    return obj
end

return {
    new = newTextbox
}