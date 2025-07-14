local QBCore = exports['qbx-core']:GetCoreObject()

local BlipMarker = {}
BlipMarker.__index = BlipMarker

function BlipMarker.new()
    local self = setmetatable({}, BlipMarker)
    self.maxBlipsPerPlayer = Config.MaxBlipsPerPlayer or 10
    return self
end

function BlipMarker:saveBlip(src, blipData)
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return false, "Player not found" end

    local cid = Player.PlayerData.citizenid

    local countResult = MySQL.query.await('SELECT COUNT(*) as count FROM player_blips WHERE citizenid = ?', {cid})
    if countResult[1].count >= self.maxBlipsPerPlayer then
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'Max Blips Reached',
            description = 'You cannot add more than ' .. self.maxBlipsPerPlayer .. ' blips.',
            type = 'error'
        })
        return false, "Max blips reached"
    end

    MySQL.insert.await('INSERT INTO player_blips (citizenid, label, x, y, z, sprite, color) VALUES (?, ?, ?, ?, ?, ?, ?)', {
        cid,
        blipData.label,
        blipData.x,
        blipData.y,
        blipData.z,
        tonumber(blipData.sprite),
        tonumber(blipData.color)
    })

    return true
end

function BlipMarker:getPlayerBlips(src)
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return {} end

    local cid = Player.PlayerData.citizenid
    local result = MySQL.query.await('SELECT * FROM player_blips WHERE citizenid = ?', {cid})
    return result or {}
end

function BlipMarker:deleteBlip(src, label)
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return false, "Player not found" end

    local cid = Player.PlayerData.citizenid
    local result = MySQL.query.await('DELETE FROM player_blips WHERE citizenid = ? AND label = ?', {cid, label})

    return result
end


local BlipMarkers = BlipMarker.new()

RegisterNetEvent('lx-blips:saveBlip', function(blipData)
    local src = source
    local success, err = BlipMarkers:saveBlip(src, blipData)
    if not success then
        print("Error saving blip: " .. (err or "unknown"))
    end
end)

RegisterNetEvent('lx-blips:deleteBlip', function(label)
    local src = source
    local success = BlipMarkers:deleteBlip(src, label)
    if not success then
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'Delete Failed',
            description = 'Blip could not be removed.',
            type = 'error'
        })
    else
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'Blip Deleted',
            description = 'Blip "' .. label .. '" has been removed.',
            type = 'success'
        })
    end
end)

lib.callback.register('lx-blips:getPlayerBlips', function(source)
    return BlipMarkers:getPlayerBlips(source)
end)
