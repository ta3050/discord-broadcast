-- WSMM GANGS. Copyright (c) 2026 WSMM GANGS.
local nearby = {}
local sprayOpen = false
local lastHit = nil

local function rotationAxes(heading)
    local r = math.rad(heading)
    local right = vector3(math.cos(r), math.sin(r), 0.0)
    local up = vector3(0.0, 0.0, 1.0)
    return right, up
end

local function rayWall()
    local cam = GetGameplayCamCoord()
    local rot = GetGameplayCamRot(2)
    local pitch = math.rad(rot.x)
    local yaw = math.rad(rot.z)
    local dir = vector3(-math.sin(yaw) * math.cos(pitch), math.cos(yaw) * math.cos(pitch), math.sin(pitch))
    local dest = cam + dir * Config.Spray.range
    local handle = StartShapeTestRay(cam.x, cam.y, cam.z, dest.x, dest.y, dest.z, 1, PlayerPedId(), 7)
    local _, hit, coords, normal = GetShapeTestResult(handle)
    return hit == 1, coords, normal
end

local function hexRgb(hex)
    return WGHexToRgb(hex)
end

local function drawText3d(x, y, z, text, hex)
    local on, sx, sy = World3dToScreen2d(x, y, z)
    if not on then return end
    local r, g, b = hexRgb(hex)
    SetTextScale(0.32, 0.32)
    SetTextFont(4)
    SetTextProportional(true)
    SetTextColour(r, g, b, 230)
    SetTextCentre(true)
    SetTextOutline()
    BeginTextCommandDisplayText('STRING')
    AddTextComponentSubstringPlayerName(text)
    EndTextCommandDisplayText(sx, sy)
end

local function drawFreehand(s)
    if type(s.strokes) ~= 'table' then return end
    local right, up = rotationAxes(s.heading or 0)
    local origin = vector3(s.x, s.y, s.z)
    local w, h = Config.Spray.width, Config.Spray.height
    local r, g, b = hexRgb(s.hex)
    for i = 1, #s.strokes do
        local line = s.strokes[i]
        if type(line) == 'table' then
            for p = 2, #line do
                local a, c = line[p - 1], line[p]
                if a and c then
                    local p1 = origin + right * ((a.x - 0.5) * w) + up * ((0.5 - a.y) * h)
                    local p2 = origin + right * ((c.x - 0.5) * w) + up * ((0.5 - c.y) * h)
                    DrawLine(p1.x, p1.y, p1.z, p2.x, p2.y, p2.z, r, g, b, 220)
                end
            end
        end
    end
end

RegisterNetEvent('wsmm_gangs:setSprays', function(list)
    if type(list) ~= 'table' then return end
    nearby = list
end)

RegisterNetEvent('wsmm_gangs:addSpray', function(s)
    if type(s) ~= 'table' then return end
    if not WGFinite(s.x) or not WGFinite(s.y) or not WGFinite(s.z) then return end
    if s.strokes and (type(s.strokes) ~= 'table' or #s.strokes > 8) then
        s.strokes = WGCompactStrokes(s.strokes)
    end
    if s.text then s.text = WGSafeText(s.text, 28) end
    local coords = GetEntityCoords(PlayerPedId())
    if #(coords - vector3(s.x, s.y, s.z)) > Config.Spray.syncRange then return end
    nearby[#nearby + 1] = s
end)

RegisterNetEvent('wsmm_gangs:removeSpray', function(id)
    local out = {}
    for i = 1, #nearby do
        if nearby[i].id ~= id then out[#out + 1] = nearby[i] end
    end
    nearby = out
end)

RegisterNetEvent('wsmm_gangs:clearSprays', function(gangId)
    if not gangId or gangId == 0 then
        nearby = {}
        return
    end
    local out = {}
    for i = 1, #nearby do
        if nearby[i].gangId ~= gangId then out[#out + 1] = nearby[i] end
    end
    nearby = out
end)

CreateThread(function()
    while true do
        Wait(Config.Spray.syncMs)
        local c = GetEntityCoords(PlayerPedId())
        TriggerServerEvent('wsmm_gangs:requestSprays', c.x, c.y, c.z)
    end
end)

CreateThread(function()
    while true do
        local wait = 800
        local coords = GetEntityCoords(PlayerPedId())
        for i = 1, #nearby do
            local s = nearby[i]
            if s and WGFinite(s.x) and WGFinite(s.y) and WGFinite(s.z) and #(coords - vector3(s.x, s.y, s.z)) < Config.Spray.drawRange then
                wait = 0
                if s.mode == 'text' and s.text then
                    drawText3d(s.x, s.y, s.z, s.text, s.hex)
                else
                    drawFreehand(s)
                end
            end
        end
        Wait(wait)
    end
end)

RegisterNetEvent('wsmm_gangs:trySpray', function()
    TriggerServerEvent('wsmm_gangs:canSpray')
end)

RegisterNetEvent('wsmm_gangs:sprayDenied', function(key)
    WGToast(_L(key))
end)

RegisterNetEvent('wsmm_gangs:sprayAllowed', function(info)
    local hit, coords, normal = rayWall()
    if not hit then
        WGToast(_L('need_wall'))
        return
    end
    lastHit = {
        x = coords.x + normal.x * 0.035,
        y = coords.y + normal.y * 0.035,
        z = coords.z + normal.z * 0.035,
        heading = GetHeadingFromVector_2d(normal.x, normal.y)
    }
    sprayOpen = true
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'openSpray',
        data = {
            hex = info.hex,
            maxText = info.maxText,
            strings = Locales[Config.Locale] or Locales['ar']
        }
    })
end)

RegisterNUICallback('spraySubmit', function(data, cb)
    sprayOpen = false
    SetNuiFocus(false, false)
    if not lastHit then
        cb({ ok = false })
        return
    end
    TriggerServerEvent('wsmm_gangs:saveSpray', {
        mode = data.mode,
        text = data.text,
        strokes = data.strokes,
        x = lastHit.x, y = lastHit.y, z = lastHit.z,
        heading = lastHit.heading
    })
    lastHit = nil
    cb({ ok = true })
end)

RegisterNUICallback('sprayCancel', function(_, cb)
    sprayOpen = false
    lastHit = nil
    SetNuiFocus(false, false)
    cb({ ok = true })
end)
