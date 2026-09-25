-- WSMM GANGS. Copyright (c) 2026 WSMM GANGS.
local function hasItem(src, name)
    if GetResourceState('ox_inventory') == 'started' then
        return (exports.ox_inventory:GetItemCount(src, name) or 0) > 0
    end
    local xP = ESX.GetPlayerFromId(src)
    if not xP then return false end
    local item = xP.getInventoryItem(name)
    return item and (item.count or item.amount or 0) > 0
end

local function takeItem(src, name)
    if GetResourceState('ox_inventory') == 'started' then
        return exports.ox_inventory:RemoveItem(src, name, 1)
    end
    local xP = ESX.GetPlayerFromId(src)
    if xP then xP.removeInventoryItem(name, 1) end
    return true
end

local cooldown = {}

function WG.DeleteSpray(id, gangId)
    MySQL.update.await('DELETE FROM wsmm_gang_sprays WHERE id = ?', { id })
    if gangId then
        MySQL.update.await('UPDATE wsmm_gangs SET spray_count = GREATEST(spray_count - 1, 0) WHERE id = ?', { gangId })
        WG.Reload()
    end
    TriggerClientEvent('wsmm_gangs:removeSpray', -1, id)
    WG.RefreshBlipsAll()
end

function WG.WipeGangSprays(gangId)
    MySQL.update.await('DELETE FROM wsmm_gang_sprays WHERE gang_id = ?', { gangId })
    MySQL.update.await('UPDATE wsmm_gangs SET spray_count = 0 WHERE id = ?', { gangId })
    WG.Reload()
    TriggerClientEvent('wsmm_gangs:clearSprays', -1, gangId)
    WG.RefreshBlipsAll()
end

function WG.WipeAllSprays()
    MySQL.update.await('DELETE FROM wsmm_gang_sprays')
    MySQL.update.await('UPDATE wsmm_gangs SET spray_count = 0')
    WG.Reload()
    TriggerClientEvent('wsmm_gangs:clearSprays', -1, 0)
    WG.RefreshBlipsAll()
end

function WG.SendSprayBlips(src)
    local member, _ = WG.MemberOf(src)
    local admin = WG.IsAdmin(src)
    if not admin and not WG.IsLeader(member) then
        TriggerClientEvent('wsmm_gangs:sprayBlips', src, {})
        return
    end
    local rows
    if admin then
        rows = MySQL.query.await('SELECT id, x, y, z, gang_id, mode FROM wsmm_gang_sprays ORDER BY id DESC LIMIT 40') or {}
    else
        rows = MySQL.query.await('SELECT id, x, y, z, gang_id, mode FROM wsmm_gang_sprays WHERE gang_id = ? ORDER BY id DESC LIMIT 20', { member.gang_id }) or {}
    end
    local list = {}
    for _, r in ipairs(rows) do
        local g = WG.Gangs[r.gang_id]
        local col = g and WGColor(g.color) or WGColor('red')
        list[#list + 1] = { id = r.id, x = r.x, y = r.y, z = r.z, blipColor = col.blip, mode = r.mode }
    end
    TriggerClientEvent('wsmm_gangs:sprayBlips', src, list)
end

RegisterNetEvent('wsmm_gangs:requestSprays', function(x, y, z)
    local src = source
    if not WG.RateOk(src, 'sprays', WG.SecMs('spraysMs', 2500)) then return end
    x, y, z = WGFinite(x) or 0, WGFinite(y) or 0, WGFinite(z) or 0
    if not WGInWorld(x, y, z) then
        TriggerClientEvent('wsmm_gangs:setSprays', src, {})
        return
    end
    local range = Config.Spray.syncRange
    local rows = MySQL.query.await(
        'SELECT id, gang_id, mode, text_content, strokes, x, y, z, heading FROM wsmm_gang_sprays WHERE (x - ?) * (x - ?) + (y - ?) * (y - ?) < ? ORDER BY id DESC LIMIT 24',
        { x, x, y, y, range * range }
    ) or {}
    local out = {}
    for _, r in ipairs(rows) do
        local g = WG.Gangs[r.gang_id]
        local col = g and WGColor(g.color) or WGColor('red')
        local strokes = nil
        if r.strokes and r.strokes ~= '' then
            local ok, decoded = pcall(json.decode, r.strokes)
            if ok then strokes = WGCompactStrokes(decoded) or decoded end
        end
        out[#out + 1] = {
            id = r.id,
            mode = r.mode,
            text = r.text_content,
            strokes = strokes,
            x = r.x, y = r.y, z = r.z,
            heading = r.heading,
            hex = col.hex,
            gangId = r.gang_id
        }
    end
    TriggerClientEvent('wsmm_gangs:setSprays', src, out)
end)

RegisterNetEvent('wsmm_gangs:saveSpray', function(payload)
    local src = source
    payload = type(payload) == 'table' and payload or {}
    local member, xP = WG.MemberOf(src)
    if not member then return WG.Notify(src, 'no_spray') end
    if member.is_guest == 1 then return WG.Notify(src, 'guest_no_spray') end
    if not hasItem(src, Config.SprayItem) then return WG.Notify(src, 'no_item') end
    local now = os.time()
    if cooldown[member.identifier] and now - cooldown[member.identifier] < Config.Spray.cooldown then
        return WG.Notify(src, 'cooldown')
    end
    local gang = WG.Gangs[member.gang_id]
    if not gang then return WG.Notify(src, 'not_member') end
    if (gang.spray_count or 0) >= Config.MaxGangSprays then return WG.Notify(src, 'max_sprays') end

    local mode = payload.mode == 'text' and 'text' or 'freehand'
    local text = nil
    local strokesJson = nil
    local compact = nil
    if mode == 'text' then
        text = WGSafeText(payload.text, Config.Spray.maxText)
        if text == '' then return WG.Notify(src, 'empty_draw') end
        if WGBanned(text) then return WG.Notify(src, 'banned_text') end
    else
        compact = WGCompactStrokes(payload.strokes)
        if not compact then return WG.Notify(src, 'empty_draw') end
        strokesJson = json.encode(compact)
    end

    local x = WGFinite(payload.x)
    local y = WGFinite(payload.y)
    local z = WGFinite(payload.z)
    local heading = WGFinite(payload.heading) or 0
    if not x or not y or not z or not WGInWorld(x, y, z) then return WG.Notify(src, 'need_wall') end
    heading = heading % 360.0

    local ped = GetPlayerPed(src)
    if not ped or ped == 0 then return WG.Notify(src, 'need_wall') end
    local c = GetEntityCoords(ped)
    local slack = WG.SecMs('spraySlack', 3.0)
    local maxDist = (Config.Spray.range or 4.2) + slack
    local dx, dy, dz = c.x - x, c.y - y, c.z - z
    if (dx * dx + dy * dy + dz * dz) > (maxDist * maxDist) then
        return WG.Notify(src, 'need_wall')
    end

    local zone = WGGetZoneAt({ x = x, y = y, z = z })
    local zoneId = zone and zone.id or nil

    takeItem(src, Config.SprayItem)
    cooldown[member.identifier] = now

    local id = MySQL.insert.await(
        'INSERT INTO wsmm_gang_sprays (gang_id, identifier, player_name, mode, text_content, strokes, x, y, z, heading, zone_id) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
        {
            gang.id,
            member.identifier,
            xP.getName and xP.getName() or GetPlayerName(src),
            mode,
            text,
            strokesJson,
            x, y, z, heading, zoneId
        }
    )

    local pts = Config.Spray.pointsPerSpray
    if zoneId and WG.ZoneIsOpen(zoneId) then
        pts = pts + Config.Spray.zoneBonus
        WG.AddInfluence(zoneId, gang.id, 6)
        local st = WG.ZoneState[zoneId]
        if st and st.owner_gang_id and st.owner_gang_id ~= gang.id then
            MySQL.update.await('UPDATE wsmm_gangs SET points = GREATEST(points - 2, 0) WHERE id = ?', { st.owner_gang_id })
            WG.NotifyLeaders(st.owner_gang_id, 'rival_spray')
            WG.PushNotif(st.owner_gang_id, 'rival', 'rival_spray', zoneId or '')
        end
    end
    MySQL.update.await('UPDATE wsmm_gangs SET points = points + ?, spray_count = spray_count + 1 WHERE id = ?', { pts, gang.id })
    WG.Reload()

    local col = WGColor(gang.color)
    local spray = {
        id = id,
        mode = mode,
        text = text,
        strokes = compact,
        x = x, y = y, z = z,
        heading = heading,
        hex = col.hex,
        gangId = gang.id
    }
    TriggerClientEvent('wsmm_gangs:addSpray', -1, spray)
    WG.Notify(src, 'spray_saved')
end)

RegisterNetEvent('wsmm_gangs:canSpray', function()
    local src = source
    if not WG.RateOk(src, 'canSpray', WG.SecMs('canSprayMs', 800)) then return end
    local member = WG.MemberOf(src)
    if not member then return TriggerClientEvent('wsmm_gangs:sprayDenied', src, 'no_spray') end
    if member.is_guest == 1 then return TriggerClientEvent('wsmm_gangs:sprayDenied', src, 'guest_no_spray') end
    if not hasItem(src, Config.SprayItem) then return TriggerClientEvent('wsmm_gangs:sprayDenied', src, 'no_item') end
    local gang = WG.Gangs[member.gang_id]
    TriggerClientEvent('wsmm_gangs:sprayAllowed', src, {
        hex = WGColor(gang and gang.color or 'red').hex,
        maxText = Config.Spray.maxText
    })
end)
