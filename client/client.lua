local BlipMarker = {}
BlipMarker.__index = BlipMarker

function BlipMarker.new()
    local self = setmetatable({}, BlipMarker)
    self.lxBlips = {}
    self.cachedBlips = {}
    self.blipsVisible = false
    return self
end

function BlipMarker:createBlip(data)
    local blip = AddBlipForCoord(data.x, data.y, data.z)
    SetBlipSprite(blip, data.sprite or Config.DefaultSprite)
    SetBlipDisplay(blip, 4)
    SetBlipScale(blip, Config.DefaultScale)
    SetBlipColour(blip, data.color or Config.DefaultColor)
    SetBlipAsShortRange(blip, Config.BlipShortRange)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString(data.label)
    EndTextCommandSetBlipName(blip)

    self.lxBlips[data.label] = blip
end

function BlipMarker:deleteBlip()
    if #self.cachedBlips == 0 then
        lib.notify({title = 'No Blips', description = 'You have no blips to delete.', type = 'error'})
        return
    end

    local labelOptions = {}
    for _, blip in ipairs(self.cachedBlips) do
        table.insert(labelOptions, {label = blip.label, value = blip.label})
    end

    local selected = lib.inputDialog('Delete a Blip', {
        {type = 'select', label = 'Select Blip to Delete', options = labelOptions, required = true}
    })

    if not selected or not selected[1] then
        lib.notify({title = 'Cancelled', type = 'error'})
        return
    end

    local label = selected[1]

    local blip = self.lxBlips[label]
    if blip and DoesBlipExist(blip) then
        RemoveBlip(blip)
    end
    self.lxBlips[label] = nil

    for i, blipData in ipairs(self.cachedBlips) do
        if blipData.label == label then
            table.remove(self.cachedBlips, i)
            break
        end
    end

    TriggerServerEvent('lx-blips:deleteBlip', label)
end

function BlipMarker:removeAllBlips()
    for _, blip in pairs(self.lxBlips) do
        if DoesBlipExist(blip) then
            RemoveBlip(blip)
        end
    end
    self.lxBlips = {}
end

function BlipMarker:toggleBlips()
    self.blipsVisible = not self.blipsVisible
    self:removeAllBlips()

    if self.blipsVisible then
        for _, blipData in ipairs(self.cachedBlips) do
            self:createBlip(blipData)
        end
        lib.notify({title = 'Blips Enabled', type = 'inform'})
    else
        lib.notify({title = 'Blips Hidden', type = 'inform'})
    end
end

function BlipMarker:addBlip()
    local spriteOptions = {
        {label = "Circle", value = 1},
        {label = "Safehouse", value = 40},
        {label = "Garage", value = 357},
        {label = "Skull", value = 429},
        {label = "Heart", value = 621},
        {label = "Star", value = 835},
    }

    local colorOptions = {
        {label = "White", value = 0},
        {label = "Red", value = 1},
        {label = "Green", value = 2},
        {label = "Blue", value = 3},
        {label = "Yellow", value = 5},
        {label = "Purple", value = 7},
        {label = "Pink", value = 8},
    }

    local inputs = lib.inputDialog('Mark Current Location', {
        {type = 'input', label = 'Label', placeholder = 'My Location', required = true},
        {type = 'select', label = 'Sprite', options = spriteOptions, required = true},
        {type = 'select', label = 'Color', options = colorOptions, required = true}
    })

    if not inputs then
        lib.notify({title = 'Cancelled', description = 'No input provided', type = 'error'})
        return
    end

    local label = inputs[1]
    if self.lxBlips[label] then
        lib.notify({title = 'Error', description = 'A blip with this label already exists.', type = 'error'})
        return
    end

    local sprite = tonumber(inputs[2])
    local color = tonumber(inputs[3])

    if not sprite or not color then
        lib.notify({title = 'Error', description = 'Invalid sprite or color selection', type = 'error'})
        return
    end

    local coords = GetEntityCoords(PlayerPedId())
    local blipData = {
        label = label,
        x = coords.x,
        y = coords.y,
        z = coords.z,
        sprite = sprite,
        color = color
    }

    self:createBlip(blipData)
    table.insert(self.cachedBlips, blipData)

    TriggerServerEvent('lx-blips:saveBlip', blipData)
    lib.notify({title = 'Blip Added', description = label, type = 'success'})
end

function BlipMarker:onPlayerLoaded()
    lib.callback('lx-blips:getPlayerBlips', false, function(blips)
        self.cachedBlips = blips or {}
        for _, blipData in pairs(self.cachedBlips) do
            self:createBlip(blipData)
        end
        self.blipsVisible = true
    end)
end

function BlipMarker:onResourceStart(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end

    if LocalPlayer and LocalPlayer.state and LocalPlayer.state.isLoggedIn then
        Wait(500)
        lib.callback('lx-blips:getPlayerBlips', false, function(blips)
            self.cachedBlips = blips or {}
            for _, blipData in pairs(self.cachedBlips) do
                self:createBlip(blipData)
            end
            self.blipsVisible = true
        end)
    end
end

local BlipMarker = BlipMarker.new()

RegisterCommand('addblip', function()
    BlipMarker:addBlip()
    TriggerEvent('chat:addSuggestion', '/addblip', 'Mark Location with a Blip', {})
end)

RegisterCommand('deleteblip', function()
    BlipMarker:deleteBlip()
    TriggerEvent('chat:addSuggestion', '/deleteblip', 'Delete Created Blips', {})
end)

RegisterCommand('toggleblip', function()
    BlipMarker:toggleBlips()
    TriggerEvent('chat:addSuggestion', '/toggleblip', 'Hide/Show Created Blips', {})
end, false)

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    BlipMarker:onPlayerLoaded()
end)

AddEventHandler('onClientResourceStart', function(resourceName)
    BlipMarker:onResourceStart(resourceName)
end)