UItheme = {
    bg = col.white,
    fg = col.black,
    buttonBg = col.blue,
    buttonFg = col.white
}
W, H = term.getSize()
function InitBuffer(mon)
    local buf = {}
    W, H = mon.getSize()
    for i = 1, H, 1 do
        local tb = {}
        for i = 1, W, 1 do
            table.insert(tb, {col.white, col.black, " "})
        end
        table.insert(buf, tb)
    end
    return buf
end
local function blitAtPos(x, y, bgCol, forCol, text, buf)
    if x <= #buf[1] and y <= #buf and y>0 and x>0 then
        buf[y][x] = {bgCol, forCol, text}
    end
end
function ScrollPane(b)
    local config = {}
    for key, value in pairs(b) do
        config[key] = value
    end
    config.scroll = 0
    config.width = config.width - 1
    config.getTotalHeight = function ()
        local h = 0
        for index, value in ipairs(config.children) do
            h = h + value.getWH()[2]
        end
        return h
    end
    local mbpressedatm = false
    local lastx, lasty = 0, 0
    config.getDrawCommands = function ()
        local dcBuf = {}
        local tw, th = config.width, config.height
        for i = 1, tw, 1 do
            for ix = 1, th, 1 do
                local rc = {
                    bgCol = config.col,
                    forCol = col.white,
                    text = " ",
                    x = i,
                    y = ix,
                }
                table.insert(dcBuf, rc)
            end
        end
        local yo = 0
        for index, value in ipairs(config.children) do
            if value.y - config.scroll + value.getWH()[1] > 0 and value.y - config.scroll <= config.height then
                local rc = value.getDrawCommands()
                for index, value in ipairs(rc) do
                    table.insert(dcBuf, {
                        x = config.x + value.x,
                        y = config.y + value.y - config.scroll + yo,
                        text = value.text,
                        bgCol = value.bgCol,
                        forCol = value.forCol
                    })
                end
                yo = yo + value.getWH()[2]
            end
        end
        local rmIndexes = {}
        for index, value in ipairs(dcBuf) do
            if value.x - config.x < 0 or value.x - config.x > config.width-1 or value.y - config.y < 0 or value.y - config.y > config.height-1 then
                table.insert(rmIndexes, 1, index)
            end
        end
        for index, value in ipairs(rmIndexes) do
            table.remove(dcBuf, value)
        end
        if config.showScrollBtns then
            table.insert(dcBuf, {
                text = "^",
                forCol = UItheme.bg,
                bgCol = UItheme.fg,
                x = config.x + config.width+1,
                y = config.y
            })
            table.insert(dcBuf, {
                text = "v",
                forCol = UItheme.bg,
                bgCol = UItheme.fg,
                x = config.x + config.width+1,
                y = config.y + 1
            })
        end
        for i = (config.showScrollBtns and 2 or 0), config.height-1, 1 do
            table.insert(dcBuf, {
                text = "|",
                forCol = UItheme.bg,
                bgCol = UItheme.fg,
                x = config.x + config.width + 1,
                y = config.y + i
            }) 
        end
        return dcBuf
    end
    config.onEvent = function (e)
        local ce = e
        if ce[1] == "click" then
            if ce[3] >= config.x and ce[4] >= config.y and ce[3] <= config.x + config.width and ce[3] <= config.y + config.height then
                for index, value in ipairs(config.children) do
                    value.onEvent({"click", ce[2], ce[3] - config.x, ce[4] - config.y})
                end
            end
            if config.showScrollBtns then
                if ce[3] == config.x+config.width+1 and ce[4] == config.y then
                    config.scroll = math.max(config.scroll - 1, 0) 
                    return true
                end
                if ce[3] == config.x+config.width+1 and ce[4] == config.y+1 then
                    config.scroll = math.min(config.scroll + 1, config.getTotalHeight() - config.height) 
                    return true
                end
            end
            mbpressedatm = true
            lastx, lasty = ce[3], ce[4]
        end
        if ce[1] == "drag" then
            if ce[3] >= config.x and ce[4] >= config.y and ce[3] <= config.x + config.width and ce[3] <= config.y + config.height then
                for index, value in ipairs(config.children) do
                    value.onEvent({"drag", ce[2], ce[3] - config.x, ce[4] - config.y})
                end
            end
            local ret = false
            if mbpressedatm and lastx == config.x + config.width + 1 and lasty >= config.y + (config.showScrollBtns and 2 or 0) and lasty <= config.y + config.width then
                config.scroll = math.min(math.max(config.scroll + (ce[4] - lasty)*-1, 0), config.getTotalHeight() - config.height)
                ret = true
            end
            lastx, lasty = ce[3], ce[4]
            return ret
        end
        if ce[1] == "up" then
            if ce[3] >= config.x and ce[4] >= config.y and ce[3] <= config.x + config.width and ce[3] <= config.y + config.height then
                for index, value in ipairs(config.children) do
                    value.onEvent({"up", ce[2], ce[3] - config.x, ce[4] - config.y})
                end
            end
            mbpressedatm = false
        end
    end
    return config
end
function Label(b)
    local config = {}
    for i, v in pairs(b) do
        config[i] = v
    end
    function config.getWH()
        local height = 1
        local width = 1
        local i = 1
        while string.sub(config.label, i, i) ~= "" do
            if string.sub(config.label, i, i) == "\n" then
                height = height + 1
            else
                width = width + 1
            end
            i = i + 1
        end
        width = width - 1
        return {width, height}
    end
    if not config.col then config.col = UItheme.bg end
    if not config.textCol then config.textCol = UItheme.fg end
    config.getDrawCommands = function ()
        local rcbuffer = {}
        local rx = 0
        local ry = 0
        local i = 1
        while string.sub(config.label, i, i) ~= "" do
            if string.sub(config.label, i, i) == "\n" then
                rx = 0
                ry = ry + 1
            else
                table.insert(rcbuffer, {
                    x = config.x + rx,
                    y = config.y + ry,
                    forCol = config.textCol,
                    bgCol = config.col,
                    text = string.sub(config.label, i, i)
                })
                rx = rx + 1
            end
            i = i + 1
        end
        return rcbuffer
    end
    config.onEvent = function(ev)
    end
    return config
end
function Button(b)
    local config = {col = UItheme.buttonBg, textCol = UItheme.buttonFg}
    for i, v in pairs(b) do
        config[i] = v
    end
    local o = Label(config)
    o.onEvent = function (e)
        local rt = false
        if e[1] == "click" then
            local wh = o.getWH()
            if e[2] == 1 and e[3] >= o.x and e[4] >= o.y and e[3] < o.x + wh[1] and e[4] < o.y + wh[2] then
                if b.callBack() then rt = true end
            end
        end
        return rt
    end
    return o
end
function RenderLoop(toRender, outTerm, f)
    local function rerender()
        local buf = ui.InitBuffer()
        ui.RenderWidgets(toRender, 0, 0, buf)
        ui.Push(buf, outTerm)
    end
    if f then rerender() end
    local ev = { arcos.ev() }
    local red = false
    local isMonitor, monSide = pcall(__LEGACY.peripheral.getName, outTerm)
    if not isMonitor then
        if ev[1] == "mouse_click" then
            for i, v in ipairs(toRender) do
                if v.onEvent({"click", ev[2], ev[3]-0, ev[4]-0}) then red = true end
            end
        elseif ev[1] == "mouse_drag" then
            for i, v in ipairs(toRender) do
                if v.onEvent({"drag", ev[2], ev[3]-0, ev[4]-0}) then red = true end
            end
        elseif ev[1] == "mouse_up" then
            for i, v in ipairs(toRender) do
                if v.onEvent({"up", ev[2], ev[3]-0, ev[4]-0}) then red = true end
            end
        else
            for i, v in ipairs(toRender) do
                if v.onEvent(ev) then red = true end
            end
        end
    else
        if ev[1] == "monitor_touch" and ev[2] == monSide then
            for i, v in ipairs(toRender) do
                if v.onEvent({"click", 1, ev[3]-0, ev[4]-0}) then red = true end
                if v.onEvent({"up", 1, ev[3]-0, ev[4]-0}) then red = true end
            end
        else
            for i, v in ipairs(toRender) do
                if v.onEvent(ev) then red = true end
            end
        end
    end
    if red then rerender() end
end
function DirectRender(wr, ox, oy, buf)
    local rc
    if wr["getDrawCommands"] then
        rc = wr["getDrawCommands"]()
    else
        rc = wr
    end
    for i, v in ipairs(rc) do
        blitAtPos(v.x+ox, v.y+oy, v.bgCol, v.forCol, v.text, buf)
    end
end
function Push(buf, terma)
    for ix, vy in ipairs(buf) do
        local blitText = ""
        local blitColor = ""
        local blitBgColor = ""
        for iy, vx in ipairs(vy) do
            blitBgColor = blitBgColor .. col.toBlit(vx[1])
            blitColor = blitColor .. col.toBlit(vx[2])
            blitText = blitText .. vx[3]
        end
        terma.setCursorPos(1, ix)
        terma.blit(blitText, blitColor, blitBgColor)
    end
end
function Cpy(buf1, buf2, ox, oy)
    for iy, vy in ipairs(buf1) do
        for ix, vx in ipairs(vy) do
            blitAtPos(ix+ox, iy+oy, vx[1], vx[2], vx[3], buf2)
        end
    end
end
function RenderWidgets(wdg, ox, oy, buf)
    arcos.log("UI blitatpos")
    local tw, th = #buf[1], #buf
    for i = 1, th, 1 do
        for ix = 1, tw, 1 do
            blitAtPos(ix+ox, i+oy, ui.UItheme.bg, ui.UItheme.fg, " ", buf)
        end
    end
    arcos.log("UI directrender")
    for index, value in ipairs(wdg) do
        ui.DirectRender(value, ox, oy, buf)
    end
end
function PageTransition(widgets1, widgets2, dir, speed, ontop, terma)
    local tw, th = terma.getSize()
    local ox = 0
    local accel = 1
    local buf = InitBuffer()
    local buf2 = InitBuffer()
    RenderWidgets(widgets1, 0, 0, buf)
    RenderWidgets(widgets2, 0, 0, buf2)
    if ontop then
        while ox < tw do
            ox = ox + accel
            accel = accel + speed
        end
        while ox > 0 do
            ox = math.max(ox - accel, 0)
            accel = accel - speed
            local sbuf = InitBuffer()
            Cpy(buf, sbuf, 0, 0)
            Cpy(buf2, sbuf, ox * (dir and -1 or 1), 0)
            Push(sbuf, terma)
            sleep(1/60)
        end        
    else
        while ox < tw do
            ox = math.min(ox + accel, tw)
            accel = accel + speed
            local sbuf = InitBuffer()
            Cpy(buf2, sbuf, 0, 0)
            Cpy(buf, sbuf, ox * (dir and -1 or 1), 0)
            Push(sbuf, terma)
            sleep(1/60)
        end
    end
end
