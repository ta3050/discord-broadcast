-- WSMM GANGS. Copyright (c) 2026 WSMM GANGS.
function WGEnsureSchema()
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS wsmm_gangs (
            id INT AUTO_INCREMENT PRIMARY KEY,
            name VARCHAR(32) NOT NULL UNIQUE,
            label VARCHAR(64) NOT NULL,
            tag VARCHAR(8) NOT NULL DEFAULT '',
            color VARCHAR(16) NOT NULL DEFAULT 'red',
            icon VARCHAR(16) NOT NULL DEFAULT 'gang',
            pending_icon VARCHAR(16) NULL,
            icon_image MEDIUMTEXT NULL,
            pending_icon_image MEDIUMTEXT NULL,
            points INT NOT NULL DEFAULT 0,
            spray_count INT NOT NULL DEFAULT 0,
            leader VARCHAR(80) NULL,
            hq_x DOUBLE NULL,
            hq_y DOUBLE NULL,
            hq_z DOUBLE NULL,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
    ]])
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS wsmm_gang_members (
            id INT AUTO_INCREMENT PRIMARY KEY,
            gang_id INT NOT NULL,
            identifier VARCHAR(80) NOT NULL UNIQUE,
            name VARCHAR(80) NOT NULL DEFAULT '',
            rank INT NOT NULL DEFAULT 1,
            is_guest TINYINT NOT NULL DEFAULT 0,
            guest_until INT NOT NULL DEFAULT 0,
            joined_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            INDEX gang_idx (gang_id)
        )
    ]])
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS wsmm_gang_sprays (
            id INT AUTO_INCREMENT PRIMARY KEY,
            gang_id INT NOT NULL,
            identifier VARCHAR(80) NOT NULL,
            player_name VARCHAR(80) NOT NULL DEFAULT '',
            mode VARCHAR(12) NOT NULL DEFAULT 'freehand',
            text_content VARCHAR(40) NULL,
            strokes LONGTEXT NULL,
            x DOUBLE NOT NULL,
            y DOUBLE NOT NULL,
            z DOUBLE NOT NULL,
            heading DOUBLE NOT NULL DEFAULT 0,
            zone_id VARCHAR(32) NULL,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            INDEX gang_idx (gang_id)
        )
    ]])
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS wsmm_gang_notifications (
            id INT AUTO_INCREMENT PRIMARY KEY,
            gang_id INT NOT NULL,
            type VARCHAR(24) NOT NULL DEFAULT 'info',
            title VARCHAR(80) NOT NULL DEFAULT '',
            message VARCHAR(255) NOT NULL DEFAULT '',
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            INDEX gang_idx (gang_id)
        )
    ]])
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS wsmm_gang_activity (
            id INT AUTO_INCREMENT PRIMARY KEY,
            gang_id INT NULL,
            actor VARCHAR(80) NOT NULL DEFAULT '',
            actor_name VARCHAR(80) NOT NULL DEFAULT '',
            action VARCHAR(32) NOT NULL DEFAULT 'info',
            detail VARCHAR(180) NOT NULL DEFAULT '',
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            INDEX gang_idx (gang_id)
        )
    ]])
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS wsmm_gang_zone_state (
            zone_id VARCHAR(32) PRIMARY KEY,
            owner_gang_id INT NULL,
            scores TEXT NULL,
            open TINYINT NOT NULL DEFAULT 1
        )
    ]])
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS wsmm_gang_custom_zones (
            id VARCHAR(32) PRIMARY KEY,
            label VARCHAR(64) NOT NULL,
            x DOUBLE NOT NULL,
            y DOUBLE NOT NULL,
            z DOUBLE NOT NULL DEFAULT 30,
            size DOUBLE NOT NULL DEFAULT 90,
            map_x DOUBLE NOT NULL,
            map_y DOUBLE NOT NULL,
            map_w DOUBLE NOT NULL,
            map_h DOUBLE NOT NULL,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
    ]])
    pcall(function()
        MySQL.query.await('ALTER TABLE wsmm_gangs ADD COLUMN icon_image MEDIUMTEXT NULL')
    end)
    pcall(function()
        MySQL.query.await('ALTER TABLE wsmm_gangs ADD COLUMN pending_icon_image MEDIUMTEXT NULL')
    end)
    pcall(function()
        MySQL.query.await('ALTER TABLE wsmm_gang_zone_state ADD COLUMN open TINYINT NOT NULL DEFAULT 1')
    end)
end

local function dbHasTable(name)
    local row = MySQL.single.await(
        'SELECT 1 AS ok FROM information_schema.tables WHERE table_schema = DATABASE() AND table_name = ? LIMIT 1',
        { name }
    )
    return row ~= nil
end

local function dbHasColumn(tableName, column)
    local row = MySQL.single.await(
        'SELECT 1 AS ok FROM information_schema.columns WHERE table_schema = DATABASE() AND table_name = ? AND column_name = ? LIMIT 1',
        { tableName, column }
    )
    return row ~= nil
end

local function ensureEsxItem(name, label, weight)
    if not dbHasTable('items') then return false end
    local exists = MySQL.single.await('SELECT name FROM items WHERE name = ? LIMIT 1', { name })
    if exists then return true end
    local ok = pcall(function()
        if dbHasColumn('items', 'weight') and dbHasColumn('items', 'rare') and dbHasColumn('items', 'can_remove') then
            MySQL.insert.await(
                'INSERT INTO items (name, label, weight, rare, can_remove) VALUES (?, ?, ?, 0, 1)',
                { name, label, weight }
            )
        elseif dbHasColumn('items', 'weight') then
            MySQL.insert.await('INSERT INTO items (name, label, weight) VALUES (?, ?, ?)', { name, label, weight })
        elseif dbHasColumn('items', 'limit') then
            MySQL.insert.await('INSERT INTO items (name, label, `limit`) VALUES (?, ?, 1)', { name, label })
        else
            MySQL.insert.await('INSERT INTO items (name, label) VALUES (?, ?)', { name, label })
        end
    end)
    return ok
end

local function injectEsxItem(name, label, weight)
    if not ESX then return end
    pcall(function()
        ESX.Items = ESX.Items or {}
        if not ESX.Items[name] then
            ESX.Items[name] = {
                name = name,
                label = label,
                weight = weight,
                rare = 0,
                can_remove = 1,
                usable = true
            }
        elseif type(ESX.Items[name]) == 'table' then
            ESX.Items[name].usable = true
        end
    end)
end

local function oxFileHasItem(body, name)
    if body:find("['" .. name .. "']", 1, true) then return true end
    if body:find('["' .. name .. '"]', 1, true) then return true end
    return false
end

local function insertBeforeLastBrace(body, snippet)
    local last
    for i = #body, 1, -1 do
        if body:sub(i, i) == '}' then
            last = i
            break
        end
    end
    if not last then return nil end
    return body:sub(1, last - 1) .. snippet .. body:sub(last)
end

local function ensureOxItems(tablet, spray)
    if GetResourceState('ox_inventory') ~= 'started' then return false end
    local body = LoadResourceFile('ox_inventory', 'data/items.lua')
    if type(body) ~= 'string' or body == '' then return false end
    if oxFileHasItem(body, tablet) and oxFileHasItem(body, spray) then return true end
    local add = ''
    if not oxFileHasItem(body, tablet) then
        add = add .. ('\n\t[%q] = {\n\t\tlabel = %q,\n\t\tweight = 400,\n\t\tstack = false,\n\t\tclose = true,\n\t\tclient = { event = %q }\n\t},\n'):format(
            tablet, 'WSMM GANGS', 'wsmm_gangs:openTablet'
        )
    end
    if not oxFileHasItem(body, spray) then
        add = add .. ('\n\t[%q] = {\n\t\tlabel = %q,\n\t\tweight = 200,\n\t\tstack = true,\n\t\tclose = true,\n\t\tclient = { event = %q }\n\t},\n'):format(
            spray, 'بخاخ WSMM GANGS', 'wsmm_gangs:trySpray'
        )
    end
    if add == '' then return true end
    local patched = insertBeforeLastBrace(body, add)
    if not patched then return false end
    if not SaveResourceFile('ox_inventory', 'data/items.lua', patched, -1) then return false end
    print('^2[WSMM GANGS]^7 انضافت الأغراض في ox_inventory. أعد تشغيل السيرفر مرة واحدة.')
    if GetNumPlayerIndices() == 0 then
        pcall(function()
            ExecuteCommand('ensure ox_inventory')
        end)
    end
    return true
end

function WGEnsureItems()
    if Config.AutoInstallItems == false then return end
    local tablet = Config.TabletItem or 'gang_tablet'
    local spray = Config.SprayItem or 'gang_spray'
    ensureEsxItem(tablet, 'WSMM GANGS', 1)
    ensureEsxItem(spray, 'بخاخ WSMM GANGS', 1)
    injectEsxItem(tablet, 'WSMM GANGS', 1)
    injectEsxItem(spray, 'بخاخ WSMM GANGS', 1)
    CreateThread(function()
        for _ = 1, 50 do
            if GetResourceState('ox_inventory') == 'started' then
                pcall(function()
                    ensureOxItems(tablet, spray)
                end)
                return
            end
            Wait(200)
        end
    end)
end
