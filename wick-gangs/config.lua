Config = {}

Config.Locale = 'ar'
Config.TabletKey = 'F6'
Config.LeaderKey = 'F7'
Config.AdminKey = 'F10'

Config.TabletItem = 'gang_tablet'
Config.SprayItem = 'gang_spray'

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

Config.Zones = {
    { id = 'grove',       label = { ar = 'قروف ستريت', en = 'Grove Street' },       coords = vector3(-132.4, -1609.2, 32.0),  radius = 95.0 },
    { id = 'chamberlain', label = { ar = 'تشامبرلين', en = 'Chamberlain Hills' },   coords = vector3(-220.0, -1490.0, 31.0),  radius = 90.0 },
    { id = 'forum',       label = { ar = 'فوروم درايف', en = 'Forum Drive' },        coords = vector3(-184.0, -1666.0, 33.0),  radius = 80.0 },
    { id = 'davis',       label = { ar = 'ديفيس', en = 'Davis' },                   coords = vector3(96.0, -1735.0, 29.0),    radius = 95.0 },
    { id = 'rancho',      label = { ar = 'رانشو', en = 'Rancho' },                  coords = vector3(412.0, -2012.0, 23.0),   radius = 110.0 },
    { id = 'strawberry',  label = { ar = 'ستروبيري', en = 'Strawberry' },           coords = vector3(56.0, -1350.0, 29.0),    radius = 90.0 },
    { id = 'lamesa',      label = { ar = 'لا ميسا', en = 'La Mesa' },               coords = vector3(860.0, -1750.0, 29.0),   radius = 110.0 },
    { id = 'cypress',     label = { ar = 'سايبريس فلاتس', en = 'Cypress Flats' },    coords = vector3(860.0, -2360.0, 30.0),   radius = 120.0 },
    { id = 'elburro',     label = { ar = 'إل بورّو', en = 'El Burro Heights' },     coords = vector3(1380.0, -2100.0, 50.0),  radius = 130.0 },
    { id = 'mirror',      label = { ar = 'ميرور بارك', en = 'Mirror Park' },         coords = vector3(1078.0, -540.0, 58.0),   radius = 110.0 },
    { id = 'vinewood',    label = { ar = 'فاينوود', en = 'Downtown Vinewood' },     coords = vector3(318.0, 180.0, 103.0),    radius = 120.0 },
    { id = 'delperro',    label = { ar = 'ديل بيرو', en = 'Del Perro' },             coords = vector3(-1550.0, -580.0, 33.0),  radius = 130.0 },
    { id = 'sandy',       label = { ar = 'ساندي شورز', en = 'Sandy Shores' },        coords = vector3(1848.0, 3680.0, 34.0),   radius = 160.0 },
    { id = 'paleto',      label = { ar = 'باليتو باي', en = 'Paleto Bay' },          coords = vector3(-140.0, 6350.0, 31.0),   radius = 170.0 }
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
