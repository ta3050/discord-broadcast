-- WSMM GANGS. Copyright (c) 2026 WSMM GANGS.
-- Auto-appended on first start if ox_inventory is running.
-- Manual copy into ox_inventory/data/items.lua only if auto-install is off.
['gang_tablet'] = {
    label = 'WSMM GANGS',
    weight = 400,
    stack = false,
    close = true,
    client = { event = 'wsmm_gangs:openTablet' }
},

['gang_spray'] = {
    label = 'بخاخ WSMM GANGS',
    weight = 200,
    stack = true,
    close = true,
    client = { event = 'wsmm_gangs:trySpray' }
},
