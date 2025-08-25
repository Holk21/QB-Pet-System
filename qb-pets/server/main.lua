local QBCore = exports['qb-core']:GetCoreObject()

-- Utils
local function Notify(src, msg, typ, time)
  typ = typ or 'success'
  time = time or 4500
  if Config.Notify == 'okok' then
    TriggerClientEvent('okokNotify:Alert', src, "Pets", msg, time, typ)
  else
    TriggerClientEvent('QBCore:Notify', src, msg, typ, time)
  end
end

-- Create pet (buy animal)
RegisterNetEvent('qb-pets:server:BuyPet', function(petKey)
  local src = source
  local xPlayer = QBCore.Functions.GetPlayer(src)
  if not xPlayer then return end

  local petDef = nil
  for _, p in ipairs(Config.Animals) do
    if p.key == petKey then petDef = p break end
  end
  if not petDef then
    Notify(src, 'Invalid pet.', 'error')
    return
  end

  if xPlayer.Functions.RemoveMoney('bank', petDef.price, 'buy-pet') then
    local cid = xPlayer.PlayerData.citizenid
    MySQL.insert.await('INSERT INTO player_pets (citizenid, pet_key, pet_model, pet_name, hunger, thirst, health, out_state) VALUES (?, ?, ?, ?, ?, ?, ?, ?)', {
      cid, petDef.key, petDef.model, petDef.label, 100, 100, 100, 0
    })
    Notify(src, ('You bought a %s! Use /pet to manage it.'):format(petDef.label), 'success')
    TriggerClientEvent('qb-pets:client:RefreshPets', src)
  else
    Notify(src, 'Not enough bank balance.', 'error')
  end
end)

-- Buy item (shop)
RegisterNetEvent('qb-pets:server:BuyItem', function(itemName)
  local src = source
  local xPlayer = QBCore.Functions.GetPlayer(src)
  if not xPlayer then return end

  local price
  for _, it in ipairs(Config.ShopItems.food) do if it.name == itemName then price = it.price end end
  for _, it in ipairs(Config.ShopItems.drink) do if it.name == itemName then price = it.price end end
  for _, it in ipairs(Config.ShopItems.health) do if it.name == itemName then price = it.price end end
  if not price then Notify(src, 'Invalid item.', 'error') return end

  if xPlayer.Functions.RemoveMoney('bank', price, 'buy-pet-item') then
    xPlayer.Functions.AddItem(itemName, 1, false, {})
    TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items[itemName], 'add')
    Notify(src, 'Purchased.', 'success')
  else
    Notify(src, 'Not enough bank balance.', 'error')
  end
end)

-- Get player pets
QBCore.Functions.CreateCallback('qb-pets:server:GetPets', function(source, cb)
  local xPlayer = QBCore.Functions.GetPlayer(source)
  if not xPlayer then cb({}) return end
  local rows = MySQL.query.await('SELECT * FROM player_pets WHERE citizenid = ?', { xPlayer.PlayerData.citizenid })
  cb(rows or {})
end)

-- Save pet stats
RegisterNetEvent('qb-pets:server:SavePetStats', function(petId, stats)
  local src = source
  local xPlayer = QBCore.Functions.GetPlayer(src)
  if not xPlayer then return end
  MySQL.update.await('UPDATE player_pets SET hunger=?, thirst=?, health=?, out_state=? WHERE id=? AND citizenid=?', {
    stats.hunger, stats.thirst, stats.health, stats.out_state, petId, xPlayer.PlayerData.citizenid
  })
end)

-- Mark pet in/out
RegisterNetEvent('qb-pets:server:SetPetOutState', function(petId, outState)
  local src = source
  local xPlayer = QBCore.Functions.GetPlayer(src)
  if not xPlayer then return end
  MySQL.update.await('UPDATE player_pets SET out_state=? WHERE id=? AND citizenid=?', {
    outState and 1 or 0, petId, xPlayer.PlayerData.citizenid
  })
end)

-- Consume item (feed/drink/med)
QBCore.Functions.CreateCallback('qb-pets:server:UseItemOnPet', function(source, cb, itemName)
  local xPlayer = QBCore.Functions.GetPlayer(source)
  if not xPlayer then cb(false) return end
  local item = xPlayer.Functions.GetItemByName(itemName)
  if not item or item.amount < 1 then cb(false) return end
  xPlayer.Functions.RemoveItem(itemName, 1)
  TriggerClientEvent('inventory:client:ItemBox', source, QBCore.Shared.Items[itemName], 'remove')
  cb(true)
end)
