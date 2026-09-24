-- WSMM GANGS. Copyright (c) 2026 WSMM GANGS.
function WGLabel(field, lang)
    if type(field) == 'table' then
        lang = lang or Config.Locale or 'ar'
        return field[lang] or field.en or field.ar or ''
    end
    return field or ''
end

function WGZoneHalf(z)
    if not z then return 90.0 end
    return (z.size or z.radius or 90.0) + 0.0
end

function WGZoneList()
    if type(WG) == 'table' and type(WG.AllZones) == 'function' then
        local list = WG.AllZones()
        if type(list) == 'table' then return list end
    end
    return Config.Zones
end

-- Percent box on html/los-santos-map.png → world center + square half-extent.
function WGMapBoxToWorld(map)
    if type(map) ~= 'table' then return nil end
    local x = tonumber(map.x)
    local y = tonumber(map.y)
    local w = tonumber(map.w)
    local h = tonumber(map.h or map.w)
    if not x or not y or not w or not h then return nil end
    w = math.max(1.5, math.min(40.0, w))
    h = math.max(1.5, math.min(40.0, h))
    x = math.max(0.0, math.min(99.0, x))
    y = math.max(0.0, math.min(99.0, y))
    if x + w > 100.0 then x = 100.0 - w end
    if y + h > 100.0 then y = 100.0 - h end
    local cx = x + w / 2.0
    local cy = y + h / 2.0
    local worldX = ((cx - 12.0) / 60.0) * 2950.0 - 1850.0
    local worldY = 400.0 - ((cy - 12.0) / 70.0) * 3200.0
    local sizeX = (w / 60.0) * 2950.0 / 2.0
    local sizeY = (h / 70.0) * 3200.0 / 2.0
    local size = math.max(40.0, math.min(400.0, math.max(sizeX, sizeY)))
    return {
        x = worldX,
        y = worldY,
        z = 30.0,
        size = size,
        map = { x = x, y = y, w = w, h = h }
    }
end

-- Axis-aligned square (never a circle). Closest center wins if boxes overlap.
function WGGetZoneAt(coords)
    if not coords then return nil end
    local x, y = coords.x or coords[1], coords.y or coords[2]
    local best, bestD = nil, nil
    local list = WGZoneList()
    for i = 1, #list do
        local z = list[i]
        local c = z.coords
        if c then
            local half = WGZoneHalf(z)
            local dx, dy = x - c.x, y - c.y
            if math.abs(dx) <= half and math.abs(dy) <= half then
                local d = dx * dx + dy * dy
                if not bestD or d < bestD then
                    best, bestD = z, d
                end
            end
        end
    end
    return best
end

function WGColor(id)
    for i = 1, #Config.Colors do
        if Config.Colors[i].id == id then return Config.Colors[i] end
    end
    return Config.Colors[1]
end

function WGIcon(id)
    id = id or Config.DefaultIcon
    for i = 1, #Config.Icons do
        if Config.Icons[i].id == id then return Config.Icons[i] end
    end
    return Config.Icons[1]
end

function WGRankLabel(rank, lang)
    local row = Config.Ranks[tonumber(rank) or 1]
    return row and WGLabel(row, lang) or tostring(rank)
end

function WGHexToRgb(hex)
    hex = (hex or '#e74c3c'):gsub('#', '')
    return tonumber(hex:sub(1, 2), 16) or 231, tonumber(hex:sub(3, 4), 16) or 76, tonumber(hex:sub(5, 6), 16) or 60
end

function WGNormalize(text)
    text = string.lower(tostring(text or ''))
    text = text:gsub('أ', 'ا'):gsub('إ', 'ا'):gsub('آ', 'ا'):gsub('ة', 'ه'):gsub('ى', 'ي')
    text = text:gsub('[%s%p]+', ' ')
    return text
end

function WGSanitizeIconDataUrl(s)
    if type(s) ~= 'string' then return nil end
    local maxUrl = (Config.IconUpload and Config.IconUpload.maxDataUrl) or 700000
    local maxBytes = (Config.IconUpload and Config.IconUpload.maxBytes) or (512 * 1024)
    if #s < 32 or #s > maxUrl then return nil end
    local mime, b64 = s:match('^data:(image/[%w%+%.%-]+);base64,([A-Za-z0-9+/=]+)$')
    if not mime or not b64 then return nil end
    mime = mime:lower()
    if mime == 'image/jpg' then mime = 'image/jpeg' end
    local allowed = Config.IconUpload and Config.IconUpload.mime
    if not allowed or not allowed[mime] then return nil end
    local approx = math.floor(#b64 * 3 / 4)
    if approx > maxBytes then return nil end
    if mime == 'image/png' and not b64:find('^iVBOR') then return nil end
    if mime == 'image/jpeg' and not b64:find('^/9j/') then return nil end
    if mime == 'image/webp' and not b64:find('^UklGR') then return nil end
    return 'data:' .. mime .. ';base64,' .. b64
end

function WGBanned(text)
    if not text or text == '' then return false end
    local n = WGNormalize(text)
    if n:find('http', 1, true) or n:find('data:image', 1, true) or n:find('base64', 1, true) then
        return true
    end
    for i = 1, #Config.BannedWords do
        if n:find(Config.BannedWords[i], 1, true) then
            return true
        end
    end
    return false
end
