-- WSMM GANGS. Copyright (c) 2026 WSMM GANGS.
local blips = {}
local sprayBlips = {}

local function wipe(list)
    for i = 1, #list do
        if DoesBlipExist(list[i]) then RemoveBlip(list[i]) end
    end
end

local function add(list, blip)
    list[#list + 1] = blip
    return blip
end

RegisterNetEvent('wsmm_gangs:blips', function(payload)
    payload = payload or {}
    wipe(blips)
    blips = {}

    for _, t in ipairs(payload.publicTurfs or {}) do
        local half = (t.size or t.radius or 90) + 0.0
        local area = add(blips, AddBlipForArea(t.x + 0.0, t.y + 0.0, t.z + 0.0, half * 2.0, half * 2.0))
        SetBlipColour(area, t.blipColor or 1)
        SetBlipAlpha(area, 90)
        SetBlipRotation(area, 0)
        SetBlipAsShortRange(area, true)
        local icon = add(blips, AddBlipForCoord(t.x, t.y, t.z))
        SetBlipSprite(icon, t.sprite or 437)
        SetBlipColour(icon, t.blipColor or 1)
        SetBlipScale(icon, 0.75)
        SetBlipAsShortRange(icon, true)
        BeginTextCommandSetBlipName('STRING')
        AddTextComponentString(t.label or 'Turf')
        EndTextCommandSetBlipName(icon)
    end

    local priv = payload.private or {}
    if priv.hq then
        local b = add(blips, AddBlipForCoord(priv.hq.x, priv.hq.y, priv.hq.z))
        SetBlipSprite(b, priv.hq.sprite or 40)
        SetBlipColour(b, priv.hq.blipColor or 1)
        SetBlipScale(b, 0.95)
        SetBlipAsShortRange(b, true)
        BeginTextCommandSetBlipName('STRING')
        AddTextComponentString(priv.hq.label or 'HQ')
        EndTextCommandSetBlipName(b)
    end
end)

RegisterNetEvent('wsmm_gangs:sprayBlips', function(list)
    wipe(sprayBlips)
    sprayBlips = {}
    for _, s in ipairs(list or {}) do
        local b = add(sprayBlips, AddBlipForCoord(s.x, s.y, s.z))
        SetBlipSprite(b, 72)
        SetBlipColour(b, s.blipColor or 1)
        SetBlipScale(b, 0.55)
        SetBlipAsShortRange(b, true)
        BeginTextCommandSetBlipName('STRING')
        AddTextComponentString(s.mode == 'text' and 'Spray text' or 'Spray')
        EndTextCommandSetBlipName(b)
    end
end)
