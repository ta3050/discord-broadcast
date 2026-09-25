-- WSMM GANGS. Copyright (c) 2026 WSMM GANGS.
-- Server guards: rate limits, action allow-list, identifier checks. NUI is never trusted.

local buckets = {}

local ACTIONS = {
    summon = true,
    inviteGuest = true,
    removeGuest = true,
    announce = true,
    setHQ = true,
    setColor = true,
    requestIcon = true,
    uploadIcon = true,
    setRank = true,
    kick = true,
    deleteSpray = true,
    wipeGangSprays = true,
    adminCreate = true,
    adminDelete = true,
    adminSetLeader = true,
    adminClearLeader = true,
    adminAddMember = true,
    adminRemoveMember = true,
    adminPoints = true,
    approveIcon = true,
    rejectIcon = true,
    wipeAllSprays = true,
    setZoneOpen = true,
    createZone = true,
    deleteZone = true
}

function WG.ValidSrc(src)
    src = tonumber(src)
    return src and src > 0 and GetPlayerName(src) ~= nil
end

function WG.RateOk(src, key, minMs)
    if not WG.ValidSrc(src) then return false end
    minMs = minMs or 200
    local now = GetGameTimer()
    local b = buckets[src]
    if not b then
        b = {}
        buckets[src] = b
    end
    local last = b[key] or 0
    if now - last < minMs then return false end
    b[key] = now
    return true
end

function WG.KnownAction(action)
    return type(action) == 'string' and ACTIONS[action] == true
end

function WG.ClearGuard(src)
    buckets[src] = nil
end

function WG.SecMs(name, fallback)
    local s = Config.Security
    if s and s[name] ~= nil then return s[name] end
    return fallback
end
