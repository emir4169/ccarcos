local function split(inputstr, sep)
    if sep == nil then
        sep = "%s"
    end
    local t = {}
    for str in string.gmatch(inputstr, "([^" .. sep .. "]+)") do
        table.insert(t, str)
    end
    if t == {} then
        t = { inputstr }
    end
    return t
end
function open(path, mode)
    local validModes = {"w", "r"}
    local cmodevalid = false
    for _, v in ipairs(validModes) do
        if mode == v then cmodevalid = true break end
    end
    if not cmodevalid then error("Mode not valid: " .. mode) end
    local err
    file = {}
    file._f, err = __LEGACY.fs.open(path, mode)
    if not file._f then
        return nil, err
    end
    file.close = file._f.close
    if mode == "w" then
        file.write = function(towrite)
            file._f.write(towrite)
        end
        file.writeLine = function(towrite)
            file._f.writeLine(towrite)
        end
        file.flush = function(towrite)
            file._f.write(towrite)
        end
        file.seekBytes = function(b)
            return file._f.seek(b)
        end
    elseif mode == "r" then
        local fd = file._f.readAll()
        local li = 0
        file.readBytes = function(b)
            return file._f.read(b)
        end
        file.seekBytes = function(b)
            return file._f.seek(b)
        end
        file.read = function()
            return fd
        end
        file.readLine = function(withTrailing)
            li = li + 1
            if withTrailing then
                return split(fd, "\n")[li] .. "\n"
            else
                return split(fd, "\n")[li]
            end
        end
    end
    return file, nil
end
function ls(dir)
    return __LEGACY.fs.list(dir)
end
function rm(f)
    return __LEGACY.fs.delete(f)
end
function exists(f)
    if d == "" or d == "/" then return true end
    return __LEGACY.fs.exists(f)
end
function mkDir(d)
    return __LEGACY.fs.makeDir(d)
end
function resolve(f, keepNonExistent)
    local p = f:sub(1, 1) == "/" and "/" or (environ.workDir or "/")
    local pa = tutils.split(p, "/")
    local fla = tutils.split(f, "/")
    local out = {}
    local frmItems = {}
    for _, i in ipairs(pa) do
        table.insert(out, i)
    end
    for _, i in ipairs(fla) do
        table.insert(out, i)
    end
    for ix, i in ipairs(out) do
        if i == "" then
            table.insert(frmItems, 1, ix)
        end
        if i == "." then
            table.insert(frmItems, 1, ix)
        end
        if i == ".." then
            if #pa + ix ~= 1 then
                table.insert(frmItems, 1, ix-1) 
            end
            table.insert(frmItems, 1, ix)
        end
    end
    if not keepNonExistent and not fs.exists("/" .. tutils.join(out, "/")) then return {} end
    for _, rmi in ipairs(frmItems) do
        table.remove(out, rmi)
    end
    return { "/" .. tutils.join(out, "/") }
end
function dir(d) 
    if d == "" or d == "/" then return true end
    return __LEGACY.fs.isDir(d)
end
function m(t, d) 
    return __LEGACY.fs.move(t, d)
end
function c(t, d)
    return __LEGACY.fs.copy(t, d)
end
