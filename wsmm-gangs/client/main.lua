-- WSMM GANGS. Copyright (c) 2026 WSMM GANGS.
local ESX
local lang = Config.Locale
local tabletOpen = false
local pendingSummon = nil

CreateThread(function()
    while ESX == nil do
        if GetResourceState('es_extended') == 'started' then
            local ok, obj = pcall(function()
                return exports['es_extended']:getSharedObject()
            end)
            if ok and obj then ESX = obj break end
        end
        TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
        Wait(150)
    end
end)

local function nui(action, data)
    SendNUIMessage({ action = action, data = data })
end

function WGToast(msg)
    nui('toast', { text = msg })
    BeginTextCommandThefeedDisplay('STRING')
    AddTextComponentSubstringPlayerName(msg)
    EndTextCommandThefeedDisplayTicker(false, false)
end

RegisterNetEvent('wsmm_gangs:toast', function(msg)
    WGToast(msg)
end)

local function openTablet()
    if tabletOpen then return end
    TriggerServerEvent('wsmm_gangs:requestTablet', lang)
end

RegisterNetEvent('wsmm_gangs:tabletData', function(data)
    if not data or not data.ok then
        WGToast(_L(data and data.reason or 'not_member', lang))
        return
    end
    tabletOpen = true
    SetNuiFocus(true, true)
    nui('openTablet', WGScrubTablet(data))
end)

RegisterNetEvent('wsmm_gangs:openTablet', function()
    openTablet()
end)

RegisterNUICallback('close', function(_, cb)
    tabletOpen = false
    SetNuiFocus(false, false)
    nui('close', {})
    cb({ ok = true })
end)

RegisterNUICallback('setLang', function(data, cb)
    lang = (data and data.lang == 'en') and 'en' or 'ar'
    cb({ ok = true, strings = Locales[lang] })
end)

RegisterNUICallback('action', function(data, cb)
    data = data or {}
    TriggerServerEvent('wsmm_gangs:action', data.a, data)
    cb({ ok = true })
end)

RegisterNUICallback('uploadIcon', function(data, cb)
    TriggerLatentServerEvent('wsmm_gangs:uploadIcon', 40000, data or {})
    cb({ ok = true })
end)

RegisterNUICallback('refresh', function(_, cb)
    TriggerServerEvent('wsmm_gangs:requestTablet', lang)
    cb({ ok = true })
end)

RegisterNUICallback('acceptSummon', function(_, cb)
    if pendingSummon then
        SetNewWaypoint(pendingSummon.x + 0.0, pendingSummon.y + 0.0)
        if pendingSummon.blip and DoesBlipExist(pendingSummon.blip) then
            SetBlipRoute(pendingSummon.blip, true)
            SetBlipRouteColour(pendingSummon.blip, pendingSummon.blipColor or 1)
        end
        WGToast(_L('gps', lang))
    end
    nui('hideSummon', {})
    cb({ ok = true })
end)

RegisterNUICallback('ignoreSummon', function(_, cb)
    nui('hideSummon', {})
    cb({ ok = true })
end)

RegisterNetEvent('wsmm_gangs:summon', function(p)
    pendingSummon = p
    local blip = AddBlipForCoord(p.x, p.y, p.z)
    SetBlipSprite(blip, p.sprite or 161)
    SetBlipColour(blip, p.blipColor or 1)
    SetBlipScale(blip, 1.05)
    SetBlipFlashes(blip, true)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentString(p.label or 'Summon')
    EndTextCommandSetBlipName(blip)
    pendingSummon.blip = blip
    nui('summon', {
        caller = WGSafeText(p.caller, 40),
        label = WGSafeText(p.label, 40),
        strings = Locales[lang] or Locales['ar']
    })
    WGToast(_L('summon_banner', lang) .. ': ' .. WGSafeText(p.caller, 40))
    SetTimeout((p.minutes or 8) * 60 * 1000, function()
        if pendingSummon and pendingSummon.blip == blip and DoesBlipExist(blip) then
            RemoveBlip(blip)
        end
    end)
end)

RegisterCommand('gangtablet', function()
    openTablet()
end, false)

RegisterCommand('gangleader', function()
    openTablet()
end, false)

RegisterCommand('gangadmin', function()
    openTablet()
end, false)

RegisterCommand('gangsummon', function()
    TriggerServerEvent('wsmm_gangs:action', 'summon', {})
end, false)

RegisterKeyMapping('gangtablet', 'WSMM GANGS tablet', 'keyboard', Config.TabletKey)
RegisterKeyMapping('gangleader', 'WSMM GANGS leader menu', 'keyboard', Config.LeaderKey)
RegisterKeyMapping('gangadmin', 'WSMM GANGS admin menu', 'keyboard', Config.AdminKey)

CreateThread(function()
    Wait(1500)
    TriggerServerEvent('wsmm_gangs:requestBlips')
end)
