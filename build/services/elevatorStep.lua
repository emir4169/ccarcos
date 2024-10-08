local mdm = devices.find("modem")
local currentFloor = -1
if not mdm then
    error("Modem not found")
end
local whitelistedPlayers = {
    "ChanesawWhatever",
    "emireri1498",
    "kkk8GJ"
}
mdm.open(711)
mdm.open(713)
local function contains(table, element)
    for _, value in pairs(table) do
        if value == element then
            return true
        end
    end
    return false
end
while true do
    local _, side, channel, rc, msg, dist = arcos.ev("modem_message")
    if channel == 713 then
        print(msg)
        if msg == "TopDoorOpen" then
            rd.setO("back", true)
        elseif msg == "TopDoorClose" then
            rd.setO("back", false)
        end
    elseif channel == 711 then
        currentFloor = tonumber(msg)
    end
end
