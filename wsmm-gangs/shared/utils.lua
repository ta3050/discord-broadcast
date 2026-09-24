-- WSMM GANGS. Copyright (c) 2026 WSMM GANGS.
function WGLabel(field, lang)
    if type(field) == 'table' then
        lang = lang or Config.Locale or 'ar'
        return field[lang] or field.en or field.ar or ''
    end
    return field or ''
end

function WGGetZoneAt(coords)
    if not coords then return nil end
    local x, y = coords.x or coords[1], coords.y or coords[2]
    for i = 1, #Config.Zones do
        local z = Config.Zones[i]
        local c = z.coords
        local dx, dy = x - c.x, y - c.y
        if (dx * dx + dy * dy) <= (z.radius * z.radius) then
            return z
        end
    end
    return nil
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
