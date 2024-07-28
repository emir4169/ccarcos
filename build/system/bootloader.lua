local theme = {
    background = colours.black,
    foreground = colors.white
}
function main()
    term.setTextColor(theme.foreground)
    term.setBackgroundColor(theme.background)
    term.clear()
    term.setCursorPos(1, 1)
    local branch = textutils.unserialiseJSON(http.get("https://api.github.com/repos/mirkokral/ccarcos/commits/main").readAll())["sha"]
    local cur = fs.open("/system/rel", "r")
    if cur and cur.readAll() ~= branch then
        shell.run("/system/installer.lua")
    end
    print("arcos2 bootloader")
    local args = ""
    _G.__LEGACY.shell.run("/system/krnl.lua " .. args)
end
main()