ESX = nil
WG = WG or {}
WG.Gangs = {}
WG.Members = {}
WG.ZoneState = {}
WG.Online = {}

local summonCd = {}

local function waitESX()
    while ESX == nil do
        if GetResourceState('es_extended') == 'started' then
            local ok, obj = pcall(function()
                return exports['es_extended']:getSharedObject()
            end)
            if ok and obj then
                ESX = obj
                break
            end
        end
        TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
        Wait(150)
    end
end

local function players()
    if ESX.GetExtendedPlayers then
        return ESX.GetExtendedPlayers()
    end
    local out = {}
    for _, id in ipairs(ESX.GetPlayers()) do
        out[#out + 1] = ESX.GetPlayerFromId(id)
    end
    return out
end

function WG.IsAdmin(src)
    if IsPlayerAceAllowed(src, 'wickgangs.admin') then return true end
    local xP = ESX.GetPlayerFromId(src)
    if not xP then return false end
    local g = xP.getGroup and xP.getGroup() or 'user'
    return Config.AdminGroups[g] == true
end

function WG.GetXP(src)
    return ESX.GetPlayerFromId(src)
end

function WG.MemberOf(src)
    local xP = ESX.GetPlayerFromId(src)
    if not xP then return nil, nil end
    return WG.Members[xP.identifier], xP
end

function WG.IsLeader(member)
    if not member or member.is_guest == 1 then return false end
    if (member.rank or 0) >= 5 then return true end
    local g = WG.Gangs[member.gang_id]
    return g and g.leader == member.identifier
end

function WG.Notify(src, key)
    TriggerClientEvent('wick_gangs:toast', src, _L(key))
end

function WG.Reload()
    WG.Gangs = {}
    for _, r in ipairs(MySQL.query.await('SELECT * FROM wick_gangs') or {}) do
        WG.Gangs[r.id] = r
    end
    WG.Members = {}
    local now = os.time()
    for _, r in ipairs(MySQL.query.await('SELECT * FROM wick_gang_members') or {}) do
        if r.is_guest == 1 and r.guest_until > 0 and now > r.guest_until then
            MySQL.update.await('DELETE FROM wick_gang_members WHERE id = ?', { r.id })
        else
            WG.Members[r.identifier] = r
        end
    end
end

function WG.LoadZones()
    WG.ZoneState = {}
    for _, z in ipairs(Config.Zones) do
        WG.ZoneState[z.id] = { owner_gang_id = nil, scores = {} }
    end
    for _, r in ipairs(MySQL.query.await('SELECT * FROM wick_gang_zone_state') or {}) do
        local scores = {}
        if r.scores and r.scores ~= '' then
            local ok, decoded = pcall(json.decode, r.scores)
            if ok and type(decoded) == 'table' then scores = decoded end
        end
        WG.ZoneState[r.zone_id] = { owner_gang_id = r.owner_gang_id, scores = scores }
    end
end

function WG.SaveZone(zoneId)
    local st = WG.ZoneState[zoneId]
    if not st then return end
    MySQL.query.await(
        'INSERT INTO wick_gang_zone_state (zone_id, owner_gang_id, scores) VALUES (?, ?, ?) ON DUPLICATE KEY UPDATE owner_gang_id = VALUES(owner_gang_id), scores = VALUES(scores)',
        { zoneId, st.owner_gang_id, json.encode(st.scores or {}) }
    )
end

function WG.AddInfluence(zoneId, gangId, amount)
    local st = WG.ZoneState[zoneId]
    if not st then return end
    local key = tostring(gangId)
    st.scores[key] = (st.scores[key] or 0) + amount
    local bestId, best = nil, 0
    for gid, sc in pairs(st.scores) do
        if sc > best then
            best = sc
            bestId = tonumber(gid)
        end
    end
    local prev = st.owner_gang_id
    if best >= 8 then
        st.owner_gang_id = bestId
    end
    WG.SaveZone(zoneId)
    if prev ~= st.owner_gang_id then
        WG.RefreshBlipsAll()
    end
end

function WG.LogActivity(src, gangId, action, detail)
    local xP = src and ESX.GetPlayerFromId(src) or nil
    local name = 'console'
    local ident = ''
    if xP then
        ident = xP.identifier or ''
        name = xP.getName and xP.getName() or GetPlayerName(src)
    elseif src then
        name = GetPlayerName(src) or 'player'
    end
    MySQL.insert.await(
        'INSERT INTO wick_gang_activity (gang_id, actor, actor_name, action, detail) VALUES (?, ?, ?, ?, ?)',
        { gangId, ident, name, action or 'info', tostring(detail or ''):sub(1, 180) }
    )
    MySQL.update.await(
        'DELETE FROM wick_gang_activity WHERE created_at < DATE_SUB(NOW(), INTERVAL 14 DAY)'
    )
end

function WG.NotifyLeaders(gangId, key)
    for ident, m in pairs(WG.Members) do
        if m.gang_id == gangId and WG.IsLeader(m) then
            local t = WG.Online[ident]
            if t then WG.Notify(t, key) end
        end
    end
end

function WG.OnlineSrc(identifier)
    return WG.Online[identifier]
end

local function identFromSrc(src)
    local xP = ESX.GetPlayerFromId(src)
    return xP and xP.identifier or nil, xP
end

local function xPFromServerId(sid)
    sid = tonumber(sid)
    if not sid then return nil end
    return ESX.GetPlayerFromId(sid)
end

function WG.Rankings()
    local list = {}
    for id, g in pairs(WG.Gangs) do
        local zones = 0
        for _, st in pairs(WG.ZoneState) do
            if st.owner_gang_id == id then zones = zones + 1 end
        end
        list[#list + 1] = {
            id = id,
            label = g.label,
            tag = g.tag,
            color = g.color,
            icon = g.icon,
            points = g.points or 0,
            sprays = g.spray_count or 0,
            zones = zones,
            score = (g.points or 0) + (g.spray_count or 0) * 2 + zones * 8
        }
    end
    table.sort(list, function(a, b) return a.score > b.score end)
    return list
end

function WG.Places(lang)
    local out = {}
    for i = 1, #Config.Zones do
        local z = Config.Zones[i]
        local st = WG.ZoneState[z.id] or {}
        local owner = st.owner_gang_id and WG.Gangs[st.owner_gang_id]
        out[#out + 1] = {
            id = z.id,
            label = WGLabel(z.label, lang),
            owner = owner and owner.label or nil,
            color = owner and owner.color or nil,
            icon = owner and owner.icon or nil,
            influence = st.scores or {}
        }
    end
    return out
end

local function gangMembers(gangId, lang)
    local list = {}
    for ident, m in pairs(WG.Members) do
        if m.gang_id == gangId then
            list[#list + 1] = {
                identifier = ident,
                name = m.name,
                rank = m.rank,
                rankLabel = WGRankLabel(m.rank, lang),
                guest = m.is_guest == 1,
                online = WG.Online[ident] ~= nil
            }
        end
    end
    table.sort(list, function(a, b)
        if a.online ~= b.online then return a.online end
        return (a.rank or 0) > (b.rank or 0)
    end)
    return list
end

local function publicBlips()
    local turfs = {}
    for i = 1, #Config.Zones do
        local z = Config.Zones[i]
        local st = WG.ZoneState[z.id] or {}
        local owner = st.owner_gang_id and WG.Gangs[st.owner_gang_id]
        if owner then
            local col = WGColor(owner.color)
            local ic = WGIcon(owner.icon)
            turfs[#turfs + 1] = {
                x = z.coords.x, y = z.coords.y, z = z.coords.z,
                radius = z.radius,
                label = owner.label .. ' · ' .. WGLabel(z.label, Config.Locale),
                blipColor = col.blip,
                sprite = ic.sprite,
                hex = col.hex
            }
        end
    end
    return turfs
end

function WG.PrivateBlips(src)
    local member = WG.MemberOf(src)
    local admin = WG.IsAdmin(src)
    local hq, sprays, summon = nil, {}, nil
    local gang = member and WG.Gangs[member.gang_id]
    if gang and gang.hq_x then
        local col = WGColor(gang.color)
        local ic = WGIcon(gang.icon)
        hq = {
            x = gang.hq_x, y = gang.hq_y, z = gang.hq_z,
            label = gang.label,
            sprite = ic.sprite,
            blipColor = col.blip
        }
    end
    if admin then
        for _, g in pairs(WG.Gangs) do
            if g.hq_x then
                local col = WGColor(g.color)
                local ic = WGIcon(g.icon)
                -- admin sees all HQs via extra list
            end
        end
    end
    return { hq = hq, sprays = sprays, gangColor = gang and WGColor(gang.color).blip, gangSprite = gang and WGIcon(gang.icon).sprite }
end

function WG.RefreshBlips(src)
    TriggerClientEvent('wick_gangs:blips', src, {
        publicTurfs = publicBlips(),
        private = WG.PrivateBlips(src),
        admin = WG.IsAdmin(src)
    })
    if WG.IsAdmin(src) or (select(1, WG.MemberOf(src)) and WG.IsLeader(select(1, WG.MemberOf(src)))) then
        WG.SendSprayBlips(src)
    end
end

function WG.RefreshBlipsAll()
    for _, src in pairs(WG.Online) do
        WG.RefreshBlips(src)
    end
end

function WG.BuildTablet(src, lang)
    lang = lang or Config.Locale
    local admin = WG.IsAdmin(src)
    local member, xP = WG.MemberOf(src)
    if not member and not admin then
        return { ok = false, reason = 'not_member' }
    end
    local gang = member and WG.Gangs[member.gang_id] or nil
    local isLeader = WG.IsLeader(member)
    local payload = {
        ok = true,
        lang = lang,
        strings = Locales[lang] or Locales['ar'],
        isAdmin = admin,
        isLeader = isLeader,
        isGuest = member and member.is_guest == 1 or false,
        isMember = member and member.is_guest == 0 or false,
        me = xP and { name = xP.getName and xP.getName() or GetPlayerName(src), rank = member and member.rank } or nil,
        gang = nil,
        places = WG.Places(lang),
        rankings = WG.Rankings(),
        members = {},
        guests = {},
        sprayLog = nil,
        activityLog = nil,
        adminSprays = nil,
        pendingIcons = nil,
        gangs = nil,
        colors = Config.Colors,
        icons = Config.Icons,
        ranks = Config.Ranks
    }
    if gang then
        local col = WGColor(gang.color)
        payload.gang = {
            id = gang.id,
            name = gang.name,
            label = gang.label,
            tag = gang.tag,
            color = gang.color,
            hex = col.hex,
            icon = gang.icon,
            pendingIcon = (isLeader or admin) and gang.pending_icon or nil,
            points = gang.points,
            sprays = gang.spray_count
        }
        payload.members = gangMembers(gang.id, lang)
        for _, m in ipairs(payload.members) do
            if m.guest then payload.guests[#payload.guests + 1] = m end
        end
    end
    if isLeader and gang then
        payload.sprayLog = MySQL.query.await(
            'SELECT id, player_name, mode, text_content, x, y, z, zone_id, created_at FROM wick_gang_sprays WHERE gang_id = ? ORDER BY id DESC LIMIT 40',
            { gang.id }
        ) or {}
        payload.activityLog = MySQL.query.await(
            'SELECT id, gang_id, actor_name, action, detail, created_at FROM wick_gang_activity WHERE gang_id = ? ORDER BY id DESC LIMIT 40',
            { gang.id }
        ) or {}
    end
    if admin then
        payload.adminSprays = MySQL.query.await(
            'SELECT s.id, s.player_name, s.mode, s.text_content, s.x, s.y, s.z, s.zone_id, s.created_at, s.gang_id, g.label AS gang_label FROM wick_gang_sprays s LEFT JOIN wick_gangs g ON g.id = s.gang_id ORDER BY s.id DESC LIMIT 80'
        ) or {}
        payload.pendingIcons = {}
        payload.gangs = {}
        for _, g in pairs(WG.Gangs) do
            payload.gangs[#payload.gangs + 1] = {
                id = g.id, name = g.name, label = g.label, tag = g.tag,
                color = g.color, icon = g.icon, pendingIcon = g.pending_icon,
                points = g.points, leader = g.leader
            }
            if g.pending_icon and g.pending_icon ~= '' then
                payload.pendingIcons[#payload.pendingIcons + 1] = {
                    id = g.id, label = g.label, current = g.icon, pending = g.pending_icon
                }
            end
        end
        payload.activityLog = MySQL.query.await(
            'SELECT a.id, a.gang_id, a.actor_name, a.action, a.detail, a.created_at, g.label AS gang_label FROM wick_gang_activity a LEFT JOIN wick_gangs g ON g.id = a.gang_id ORDER BY a.id DESC LIMIT 80'
        ) or {}
    end
    return payload
end

local function setOnline(src)
    local xP = ESX.GetPlayerFromId(src)
    if xP then WG.Online[xP.identifier] = src end
end

local function setOffline(src)
    for ident, s in pairs(WG.Online) do
        if s == src then WG.Online[ident] = nil end
    end
end

RegisterNetEvent('esx:playerLoaded', function(playerId, xPlayer)
    local src = playerId or source
    Wait(400)
    setOnline(src)
    WG.RefreshBlips(src)
end)

AddEventHandler('playerDropped', function()
    setOffline(source)
end)

RegisterNetEvent('wick_gangs:requestTablet', function(lang)
    local src = source
    lang = (lang == 'en' or lang == 'ar') and lang or Config.Locale
    local data = WG.BuildTablet(src, lang)
    TriggerClientEvent('wick_gangs:tabletData', src, data)
end)

RegisterNetEvent('wick_gangs:requestBlips', function()
    WG.RefreshBlips(source)
end)

RegisterNetEvent('wick_gangs:action', function(action, data)
    local src = source
    data = data or {}
    local member, xP = WG.MemberOf(src)
    local admin = WG.IsAdmin(src)
    local gang = member and WG.Gangs[member.gang_id] or nil

    if action == 'summon' then
        if not member or member.is_guest == 1 then return WG.Notify(src, 'not_member') end
        if (member.rank or 0) < Config.MinSummonRank and not WG.IsLeader(member) then
            return WG.Notify(src, 'summon_need_rank')
        end
        local now = os.time()
        if summonCd[member.identifier] and now - summonCd[member.identifier] < Config.SummonCooldown then
            return WG.Notify(src, 'cooldown')
        end
        summonCd[member.identifier] = now
        local ped = GetPlayerPed(src)
        local c = GetEntityCoords(ped)
        local col = WGColor(gang.color)
        local ic = WGIcon(gang.icon)
        local payload = {
            x = c.x, y = c.y, z = c.z,
            caller = xP.getName and xP.getName() or GetPlayerName(src),
            label = gang.label,
            blipColor = col.blip,
            sprite = ic.sprite,
            minutes = Config.SummonBlipMinutes
        }
        local n = 0
        for ident, m in pairs(WG.Members) do
            if m.gang_id == gang.id then
                local t = WG.Online[ident]
                if t then
                    TriggerClientEvent('wick_gangs:summon', t, payload)
                    n = n + 1
                end
            end
        end
        WG.LogActivity(src, gang.id, 'summon', payload.caller)
        WG.Notify(src, 'summon_sent')

    elseif action == 'inviteGuest' then
        if not WG.IsLeader(member) then return WG.Notify(src, 'not_leader') end
        local count = 0
        for _, m in pairs(WG.Members) do
            if m.gang_id == gang.id and m.is_guest == 1 then count = count + 1 end
        end
        if count >= Config.MaxGuests then return WG.Notify(src, 'cooldown') end
        local target = xPFromServerId(data.id)
        if not target then return WG.Notify(src, 'not_member') end
        if WG.Members[target.identifier] then return end
        MySQL.insert.await(
            'INSERT INTO wick_gang_members (gang_id, identifier, name, rank, is_guest, guest_until) VALUES (?, ?, ?, 1, 1, ?)',
            { gang.id, target.identifier, target.getName and target.getName() or GetPlayerName(target.source), os.time() + Config.GuestMinutes * 60 }
        )
        local gname = target.getName and target.getName() or GetPlayerName(target.source)
        WG.Reload()
        WG.LogActivity(src, gang.id, 'guest_invite', gname)
        WG.Notify(src, 'guest_invited')
        WG.RefreshBlips(target.source)

    elseif action == 'removeGuest' then
        if not WG.IsLeader(member) then return WG.Notify(src, 'not_leader') end
        local gmember = WG.Members[data.identifier]
        MySQL.update.await('DELETE FROM wick_gang_members WHERE identifier = ? AND gang_id = ? AND is_guest = 1', { data.identifier, gang.id })
        WG.Reload()
        WG.LogActivity(src, gang.id, 'guest_remove', gmember and gmember.name or tostring(data.identifier or ''))
        WG.Notify(src, 'guest_removed')

    elseif action == 'announce' then
        if not WG.IsLeader(member) then return WG.Notify(src, 'not_leader') end
        local msg = tostring(data.text or ''):sub(1, 120)
        if msg == '' or WGBanned(msg) then return WG.Notify(src, 'banned_text') end
        WG.LogActivity(src, gang.id, 'announce', msg)

    elseif action == 'setHQ' then
        if not WG.IsLeader(member) then return WG.Notify(src, 'not_leader') end
        local c = GetEntityCoords(GetPlayerPed(src))
        MySQL.update.await('UPDATE wick_gangs SET hq_x = ?, hq_y = ?, hq_z = ? WHERE id = ?', { c.x, c.y, c.z, gang.id })
        WG.Reload()
        WG.Notify(src, 'hq_set')
        WG.RefreshBlipsAll()

    elseif action == 'setColor' then
        if not WG.IsLeader(member) then return WG.Notify(src, 'not_leader') end
        local col = WGColor(data.color)
        MySQL.update.await('UPDATE wick_gangs SET color = ? WHERE id = ?', { col.id, gang.id })
        WG.Reload()
        WG.RefreshBlipsAll()

    elseif action == 'requestIcon' then
        if not WG.IsLeader(member) then return WG.Notify(src, 'not_leader') end
        local ic = WGIcon(data.icon)
        MySQL.update.await('UPDATE wick_gangs SET pending_icon = ? WHERE id = ?', { ic.id, gang.id })
        WG.Reload()
        WG.Notify(src, 'icon_pending')
        WG.LogActivity(src, gang.id, 'icon_request', ic.id)

    elseif action == 'setRank' then
        if not WG.IsLeader(member) then return WG.Notify(src, 'not_leader') end
        local rank = tonumber(data.rank) or 1
        if rank < 1 then rank = 1 end
        if rank > 4 then rank = 4 end
        MySQL.update.await('UPDATE wick_gang_members SET rank = ? WHERE identifier = ? AND gang_id = ? AND is_guest = 0', { rank, data.identifier, gang.id })
        local named = WG.Members[data.identifier]
        WG.Reload()
        WG.LogActivity(src, gang.id, 'set_rank', (named and named.name or '') .. ' ' .. tostring(rank))

    elseif action == 'kick' then
        if not WG.IsLeader(member) then return WG.Notify(src, 'not_leader') end
        if data.identifier == member.identifier then return end
        local named = WG.Members[data.identifier]
        MySQL.update.await('DELETE FROM wick_gang_members WHERE identifier = ? AND gang_id = ?', { data.identifier, gang.id })
        WG.Reload()
        WG.LogActivity(src, gang.id, 'kick', named and named.name or tostring(data.identifier or ''))
        WG.Notify(src, 'member_removed')

    elseif action == 'deleteSpray' then
        local id = tonumber(data.id)
        if not id then return end
        local row = MySQL.single.await('SELECT * FROM wick_gang_sprays WHERE id = ?', { id })
        if not row then return end
        local ok = admin
        if not ok and WG.IsLeader(member) and gang and row.gang_id == gang.id then ok = true end
        if not ok then return WG.Notify(src, 'not_leader') end
        WG.DeleteSpray(id, row.gang_id)
        WG.Notify(src, 'spray_deleted')

    elseif action == 'wipeGangSprays' then
        local gid = tonumber(data.gangId)
        if admin then
            if not gid then return end
        else
            if not WG.IsLeader(member) then return WG.Notify(src, 'not_leader') end
            gid = gang.id
        end
        WG.WipeGangSprays(gid)
        WG.Notify(src, 'spray_deleted')

    elseif action == 'adminCreate' then
        if not admin then return WG.Notify(src, 'not_admin') end
        local name = tostring(data.name or ''):gsub('%s+', ''):sub(1, 24)
        local label = tostring(data.label or name):sub(1, 40)
        local tag = tostring(data.tag or ''):sub(1, 6)
        if name == '' then return end
        local newId = MySQL.insert.await(
            'INSERT INTO wick_gangs (name, label, tag, color, icon) VALUES (?, ?, ?, ?, ?)',
            { name, label, tag, (WGColor(data.color).id), Config.DefaultIcon }
        )
        WG.Reload()
        WG.LogActivity(src, newId, 'create_gang', label)
        WG.Notify(src, 'gang_created')

    elseif action == 'adminDelete' then
        if not admin then return WG.Notify(src, 'not_admin') end
        local gid = tonumber(data.gangId)
        if not gid then return end
        local gone = WG.Gangs[gid]
        WG.LogActivity(src, gid, 'delete_gang', gone and gone.label or tostring(gid))
        WG.WipeGangSprays(gid)
        MySQL.update.await('DELETE FROM wick_gang_members WHERE gang_id = ?', { gid })
        MySQL.update.await('DELETE FROM wick_gangs WHERE id = ?', { gid })
        WG.Reload()
        WG.Notify(src, 'gang_deleted')
        WG.RefreshBlipsAll()

    elseif action == 'adminSetLeader' then
        if not admin then return WG.Notify(src, 'not_admin') end
        local gid = tonumber(data.gangId)
        local target = xPFromServerId(data.id)
        if not gid or not target or not WG.Gangs[gid] then return end
        MySQL.update.await('UPDATE wick_gang_members SET rank = 4 WHERE gang_id = ? AND rank = 5', { gid })
        local existing = WG.Members[target.identifier]
        if existing then
            MySQL.update.await('UPDATE wick_gang_members SET gang_id = ?, rank = 5, is_guest = 0, name = ? WHERE identifier = ?', { gid, target.getName and target.getName() or '', target.identifier })
        else
            MySQL.insert.await(
                'INSERT INTO wick_gang_members (gang_id, identifier, name, rank, is_guest) VALUES (?, ?, ?, 5, 0)',
                { gid, target.identifier, target.getName and target.getName() or GetPlayerName(target.source) }
            )
        end
        MySQL.update.await('UPDATE wick_gangs SET leader = ? WHERE id = ?', { target.identifier, gid })
        WG.Reload()
        WG.LogActivity(src, gid, 'set_leader', target.getName and target.getName() or GetPlayerName(target.source))
        WG.Notify(src, 'leader_set')
        WG.RefreshBlips(target.source)

    elseif action == 'adminClearLeader' then
        if not admin then return WG.Notify(src, 'not_admin') end
        local gid = tonumber(data.gangId)
        if not gid then return end
        MySQL.update.await('UPDATE wick_gangs SET leader = NULL WHERE id = ?', { gid })
        MySQL.update.await('UPDATE wick_gang_members SET rank = 4 WHERE gang_id = ? AND rank = 5', { gid })
        WG.Reload()
        WG.LogActivity(src, gid, 'clear_leader', '')
        WG.Notify(src, 'leader_set')

    elseif action == 'adminAddMember' then
        if not admin then return WG.Notify(src, 'not_admin') end
        local gid = tonumber(data.gangId)
        local target = xPFromServerId(data.id)
        if not gid or not target or not WG.Gangs[gid] then return end
        if WG.Members[target.identifier] then
            MySQL.update.await('UPDATE wick_gang_members SET gang_id = ?, is_guest = 0, rank = 1, name = ? WHERE identifier = ?', { gid, target.getName and target.getName() or '', target.identifier })
        else
            MySQL.insert.await(
                'INSERT INTO wick_gang_members (gang_id, identifier, name, rank, is_guest) VALUES (?, ?, ?, 1, 0)',
                { gid, target.identifier, target.getName and target.getName() or GetPlayerName(target.source) }
            )
        end
        WG.Reload()
        WG.LogActivity(src, gid, 'add_member', target.getName and target.getName() or GetPlayerName(target.source))
        WG.Notify(src, 'member_added')
        WG.RefreshBlips(target.source)

    elseif action == 'adminRemoveMember' then
        if not admin then return WG.Notify(src, 'not_admin') end
        local named = WG.Members[data.identifier]
        local gid = named and named.gang_id or nil
        MySQL.update.await('DELETE FROM wick_gang_members WHERE identifier = ?', { data.identifier })
        WG.Reload()
        WG.LogActivity(src, gid, 'remove_member', named and named.name or tostring(data.identifier or ''))
        WG.Notify(src, 'member_removed')
        WG.RefreshBlipsAll()

    elseif action == 'adminPoints' then
        if not admin then return WG.Notify(src, 'not_admin') end
        local gid = tonumber(data.gangId)
        local pts = tonumber(data.points) or 0
        MySQL.update.await('UPDATE wick_gangs SET points = ? WHERE id = ?', { pts, gid })
        WG.Reload()

    elseif action == 'approveIcon' then
        if not admin then return WG.Notify(src, 'not_admin') end
        local gid = tonumber(data.gangId)
        local g = gid and WG.Gangs[gid]
        if not g or not g.pending_icon then return end
        local iconId = g.pending_icon
        MySQL.update.await('UPDATE wick_gangs SET icon = pending_icon, pending_icon = NULL WHERE id = ?', { gid })
        WG.Reload()
        WG.LogActivity(src, gid, 'icon_approve', iconId)
        WG.NotifyLeaders(gid, 'icon_approved')
        WG.RefreshBlipsAll()

    elseif action == 'rejectIcon' then
        if not admin then return WG.Notify(src, 'not_admin') end
        local gid = tonumber(data.gangId)
        local g = gid and WG.Gangs[gid]
        if not g then return end
        MySQL.update.await('UPDATE wick_gangs SET pending_icon = NULL WHERE id = ?', { gid })
        WG.Reload()
        WG.LogActivity(src, gid, 'icon_reject', g.icon or Config.DefaultIcon)
        WG.NotifyLeaders(gid, 'icon_rejected')

    elseif action == 'wipeAllSprays' then
        if not admin then return WG.Notify(src, 'not_admin') end
        WG.WipeAllSprays()
        WG.Notify(src, 'spray_deleted')
    end
end)

CreateThread(function()
    waitESX()
    WGEnsureSchema()
    WG.Reload()
    WG.LoadZones()

    pcall(function()
        ESX.RegisterUsableItem(Config.TabletItem, function(source)
            TriggerClientEvent('wick_gangs:openTablet', source)
        end)
        ESX.RegisterUsableItem(Config.SprayItem, function(source)
            TriggerClientEvent('wick_gangs:trySpray', source)
        end)
    end)

    for _, xP in ipairs(players()) do
        if xP and xP.source then
            WG.Online[xP.identifier] = xP.source
            WG.RefreshBlips(xP.source)
        end
    end
end)

CreateThread(function()
    while true do
        Wait(Config.PresenceSeconds * 1000)
        if ESX then
            for _, xP in ipairs(players()) do
                local m = xP and WG.Members[xP.identifier]
                if m and m.is_guest == 0 then
                    local ped = GetPlayerPed(xP.source)
                    if ped and ped ~= 0 then
                        local c = GetEntityCoords(ped)
                        local z = WGGetZoneAt(c)
                        if z then
                            WG.AddInfluence(z.id, m.gang_id, Config.PresencePoints)
                        end
                    end
                end
            end
        end
    end
end)
