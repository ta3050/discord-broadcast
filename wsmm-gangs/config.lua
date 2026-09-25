-- WSMM GANGS. Copyright (c) 2026 WSMM GANGS.
Config = {}

Config.Locale = 'ar'
Config.TabletKey = 'F6'
Config.LeaderKey = 'F7'
Config.AdminKey = 'F10'

Config.TabletItem = 'gang_tablet'
Config.SprayItem = 'gang_spray'
-- On first start: create tables, insert ESX items, and append ox_inventory items if missing.
Config.AutoInstallItems = true

Config.Ranks = {
    [1] = { ar = 'عضو', en = 'Member' },
    [2] = { ar = 'جندي', en = 'Soldier' },
    [3] = { ar = 'ملازم', en = 'Lieutenant' },
    [4] = { ar = 'نائب', en = 'Underboss' },
    [5] = { ar = 'قائد', en = 'Leader' }
}

Config.MinSummonRank = 3
Config.SummonCooldown = 90
Config.SummonBlipMinutes = 8
Config.GuestMinutes = 60
Config.MaxGuests = 3
Config.MaxGangSprays = 40

Config.AdminGroups = { admin = true, superadmin = true, god = true }

-- Server-side caps. NUI is not trusted; every event is rate-limited and re-checked.
Config.Security = {
    actionMs = 180,
    tabletMs = 300,
    spraysMs = 2500,
    blipsMs = 1500,
    iconMs = 4000,
    canSprayMs = 800,
    maxPoints = 9999999,
    identMax = 80,
    spraySlack = 3.0
}

Config.Spray = {
    cooldown = 8,
    range = 4.2,
    width = 1.4,
    height = 1.0,
    drawRange = 26.0,
    syncRange = 70.0,
    syncMs = 4500,
    pointsPerSpray = 2,
    zoneBonus = 4,
    maxText = 28
}

Config.PresenceSeconds = 30
Config.PresencePoints = 1

Config.Colors = {
    { id = 'red',    hex = '#e74c3c', blip = 1,  ar = 'أحمر',  en = 'Red' },
    { id = 'green',  hex = '#27ae60', blip = 2,  ar = 'أخضر',  en = 'Green' },
    { id = 'blue',   hex = '#3498db', blip = 3,  ar = 'أزرق',  en = 'Blue' },
    { id = 'yellow', hex = '#f1c40f', blip = 5,  ar = 'أصفر',  en = 'Yellow' },
    { id = 'purple', hex = '#9b59b6', blip = 27, ar = 'بنفسجي', en = 'Purple' },
    { id = 'orange', hex = '#e67e22', blip = 17, ar = 'برتقالي', en = 'Orange' },
    { id = 'pink',   hex = '#ff5fa2', blip = 8,  ar = 'وردي',  en = 'Pink' },
    { id = 'white',  hex = '#ecf0f1', blip = 4,  ar = 'أبيض',  en = 'White' }
}

-- Leader picks one; admin must approve before it goes live.
Config.Icons = {
    { id = 'gang',    sprite = 437, ar = 'عصابة',  en = 'Gang' },
    { id = 'skull',   sprite = 84,  ar = 'جمجمة',  en = 'Skull' },
    { id = 'gun',     sprite = 110, ar = 'سلاح',   en = 'Gun' },
    { id = 'money',   sprite = 500, ar = 'فلوس',   en = 'Money' },
    { id = 'star',    sprite = 304, ar = 'نجمة',   en = 'Star' },
    { id = 'mask',    sprite = 102, ar = 'قناع',   en = 'Mask' },
    { id = 'house',   sprite = 40,  ar = 'بيت',    en = 'House' },
    { id = 'car',     sprite = 225, ar = 'سيارة',  en = 'Car' },
    { id = 'crown',   sprite = 439, ar = 'تاج',    en = 'Crown' },
    { id = 'fist',    sprite = 311, ar = 'قبضة',   en = 'Fist' },
    { id = 'target',  sprite = 432, ar = 'هدف',    en = 'Target' },
    { id = 'diamond', sprite = 617, ar = 'ألماس',  en = 'Diamond' }
}

Config.DefaultIcon = 'gang'

-- Custom still PNG/JPG for the tablet map only (no video/webp/svg). GTA pause-map blips cannot
-- take a custom PNG without a streamed texture dictionary, so in-game markers
-- keep the sprite from Config.Icons (default `gang` until a list icon is approved).
Config.IconUpload = {
    maxBytes = 512 * 1024,
    maxDataUrl = 700000,
    size = 128,
    mime = {
        ['image/png'] = true,
        ['image/jpeg'] = true,
        ['image/jpg'] = true
    }
}

-- Tablet PNG is Los Santos city (html/los-santos-map.png). `map` is percent box on that image.
-- `size` is half-extent in meters for in-game SQUARE detection + pause-map area blips (never circles).
-- Sandy / Paleto stay in-game only (off this city map). Admin can open/lock claimable zones,
-- and draw extra custom squares on the tablet map (stored in wsmm_gang_custom_zones).
Config.Zones = {
    { id = 'grove',       label = { ar = 'قروف ستريت', en = 'Grove Street' },       coords = vector3(-132.4, -1609.2, 32.0),  size = 95.0,  map = { x = 46.5, y = 55.5, w = 6.4, h = 6.2 } },
    { id = 'chamberlain', label = { ar = 'تشامبرلين', en = 'Chamberlain Hills' },   coords = vector3(-220.0, -1490.0, 31.0),  size = 90.0,  map = { x = 41.8, y = 51.8, w = 5.6, h = 5.6 } },
    { id = 'forum',       label = { ar = 'فوروم درايف', en = 'Forum Drive' },        coords = vector3(-184.0, -1666.0, 33.0),  size = 80.0,  map = { x = 40.6, y = 57.4, w = 5.2, h = 5.2 } },
    { id = 'davis',       label = { ar = 'ديفيس', en = 'Davis' },                   coords = vector3(96.0, -1735.0, 29.0),    size = 95.0,  map = { x = 51.4, y = 59.2, w = 6.4, h = 6.2 } },
    { id = 'rancho',      label = { ar = 'رانشو', en = 'Rancho' },                  coords = vector3(412.0, -2012.0, 23.0),   size = 110.0, map = { x = 57.2, y = 64.4, w = 7.2, h = 6.8 } },
    { id = 'strawberry',  label = { ar = 'ستروبيري', en = 'Strawberry' },           coords = vector3(56.0, -1350.0, 29.0),    size = 90.0,  map = { x = 47.2, y = 48.8, w = 6.2, h = 5.8 } },
    { id = 'lamesa',      label = { ar = 'لا ميسا', en = 'La Mesa' },               coords = vector3(860.0, -1750.0, 29.0),   size = 110.0, map = { x = 65.8, y = 57.6, w = 7.2, h = 6.8 } },
    { id = 'cypress',     label = { ar = 'سايبريس فلاتس', en = 'Cypress Flats' },    coords = vector3(860.0, -2360.0, 30.0),   size = 120.0, map = { x = 64.8, y = 70.8, w = 7.6, h = 7.0 } },
    { id = 'elburro',     label = { ar = 'إل بورّو', en = 'El Burro Heights' },     coords = vector3(1380.0, -2100.0, 50.0),  size = 130.0, map = { x = 75.4, y = 65.6, w = 8.6, h = 8.0 } },
    { id = 'mirror',      label = { ar = 'ميرور بارك', en = 'Mirror Park' },         coords = vector3(1078.0, -540.0, 58.0),   size = 110.0, map = { x = 70.4, y = 31.4, w = 7.4, h = 7.0 } },
    { id = 'vinewood',    label = { ar = 'فاينوود', en = 'Downtown Vinewood' },     coords = vector3(318.0, 180.0, 103.0),    size = 120.0, map = { x = 55.4, y = 15.6, w = 8.0, h = 7.2 } },
    { id = 'delperro',    label = { ar = 'ديل بيرو', en = 'Del Perro' },             coords = vector3(-1550.0, -580.0, 33.0),  size = 130.0, map = { x = 16.8, y = 32.4, w = 8.8, h = 8.2 } },
    { id = 'sandy',       label = { ar = 'ساندي شورز', en = 'Sandy Shores' },        coords = vector3(1848.0, 3680.0, 34.0),   size = 160.0 },
    { id = 'paleto',      label = { ar = 'باليتو باي', en = 'Paleto Bay' },          coords = vector3(-140.0, 6350.0, 31.0),   size = 170.0 }
}

-- Server-side substring check after light normalize. Keep short to avoid lag.
Config.BannedWords = {
    'fuck', 'shit', 'bitch', 'cunt', 'asshole', 'dick', 'pussy', 'nigger', 'faggot',
    'retard', 'whore', 'slut', 'bastard', 'motherfucker', 'cock', 'rape', 'porn', 'xxx',
    'nsfw', 'nigga',
    'كس', 'كسمك', 'كسامك', 'كس ام', 'كس أم', 'شرموط', 'شرموطه', 'شرموطة',
    'قحبة', 'قحبه', 'قحب', 'عرص', 'زبي', 'زب ', 'طيز', 'متناك', 'منيوك',
    'خنيث', 'لوطي', 'عاهر', 'عاهرة', 'لبوه', 'قواد', 'ديوث', 'خول',
    'ابن الكلب', 'ابن كلب', 'انيك', 'أن يك', 'نيك ', 'تيزك'
}
