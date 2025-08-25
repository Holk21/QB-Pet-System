local QBCore = exports['qb-core']:GetCoreObject()

local ShopPed = nil
local InShop = false

local PlayerPets = {}
local ActivePet = {
  id = nil,
  ent = nil,
  model = nil,
  stats = { hunger=100, thirst=100, health=100, out_state=0 },
  state = 'follow',
}

local function Notify(msg, typ, time)
  if Config.Notify == 'okok' then
    exports['okokNotify']:Alert('Pets', msg, time or 4500, typ or 'success')
  else
    QBCore.Functions.Notify(msg, typ or 'success', time or 4500)
  end
end

local function LoadModel(model)
  if not IsModelValid(model) then return false end
  if not HasModelLoaded(model) then
    RequestModel(model)
    while not HasModelLoaded(model) do Wait(10) end
  end
  return true
end

local function PlayAnim(ped, dict, name, flag, dur)
  RequestAnimDict(dict)
  while not HasAnimDictLoaded(dict) do Wait(0) end
  TaskPlayAnim(ped, dict, name, 8.0, -8.0, dur or -1, flag or 1, 0.0, false, false, false)
end

local function ClearPet()
  if ActivePet.ent and DoesEntityExist(ActivePet.ent) then
    DeleteEntity(ActivePet.ent)
  end
  ActivePet.ent = nil
  ActivePet.id = nil
  ActivePet.model = nil
  ActivePet.stats.out_state = 0
end

local function SaveStats()
  if not ActivePet.id then return end
  TriggerServerEvent('qb-pets:server:SavePetStats', ActivePet.id, ActivePet.stats)
end


RegisterNetEvent('qb-pets:client:OpenShop', function()
  Wait(200)
  SetNuiFocus(true, true)
  InShop = true
  SendNUIMessage({ action='open', animals=Config.Animals, items=Config.ShopItems })
end)
CreateThread(function()
  local coords = Config.Shop.PedCoords
  if LoadModel(Config.Shop.PedModel) then
    ShopPed = CreatePed(4, joaat(Config.Shop.PedModel), coords.x, coords.y, coords.z-1.0, Config.Shop.PedHeading, false, true)
    SetEntityInvincible(ShopPed, true)
    SetBlockingOfNonTemporaryEvents(ShopPed, true)
    FreezeEntityPosition(ShopPed, true)
  end

  exports['qb-target']:AddTargetEntity(ShopPed, {
    options = {
      {
        icon = Config.Shop.TargetIcon,
        label = Config.Shop.TargetLabel,
        type = 'client',
        event = 'qb-pets:client:OpenShop'
      }
    },
    distance = Config.Shop.TargetDistance
  })
end)

RegisterNUICallback('close', function(_, cb)
  -- Hard release NUI focus and input
  SetNuiFocus(false, false)
  if SetNuiFocusKeepInput ~= nil then SetNuiFocusKeepInput(false) end
  Wait(50)
  SetNuiFocus(false, false)
  if SetNuiFocusKeepInput ~= nil then SetNuiFocusKeepInput(false) end
  InShop = false
  cb('ok')
end)

RegisterNUICallback('buyPet', function(data, cb)
  TriggerServerEvent('qb-pets:server:BuyPet', data.key)
  cb('ok')
end)

RegisterNUICallback('buyItem', function(data, cb)
  TriggerServerEvent('qb-pets:server:BuyItem', data.name)
  cb('ok')
end)

RegisterNetEvent('qb-pets:client:RefreshPets', function()
  QBCore.Functions.TriggerCallback('qb-pets:server:GetPets', function(rows)
    PlayerPets = rows or {}
    SendNUIMessage({ action='pets', pets=PlayerPets })
  end)
end)

RegisterNUICallback('initPets', function(_, cb)
  TriggerEvent('qb-pets:client:RefreshPets')
  cb('ok')
end)

RegisterCommand('pet', function()
  local menu = {
    { header = '🐾 Pet Menu', isMenuHeader = true }
  }

  if not ActivePet.ent then
    menu[#menu+1] = { header = 'Spawn Pet', txt = 'Choose your pet to spawn', params = { event='qb-pets:client:ChoosePetToSpawn' } }
  else
    menu[#menu+1] = { header = 'Put Pet Away', txt = 'Despawn your pet', params = { event='qb-pets:client:PutAway' } }
    menu[#menu+1] = { header = 'Bring Pet', txt = 'Teleport pet to you', params = { event='qb-pets:client:Bring' } }
    menu[#menu+1] = { header = 'Follow', params = { event='qb-pets:client:SetState', args='follow' } }
    menu[#menu+1] = { header = 'Stay', params = { event='qb-pets:client:SetState', args='stay' } }
    menu[#menu+1] = { header = 'Sit', params = { event='qb-pets:client:Sit' } }
    menu[#menu+1] = { header = 'Lie Down', params = { event='qb-pets:client:Lie' } }
    menu[#menu+1] = { header = 'Play', params = { event='qb-pets:client:Play' } }
    menu[#menu+1] = { header = 'Feed Pet', params = { event='qb-pets:client:Feed' } }
    menu[#menu+1] = { header = 'Give Water', params = { event='qb-pets:client:Drink' } }
    menu[#menu+1] = { header = 'Use Medkit', params = { event='qb-pets:client:Med' } }
    menu[#menu+1] = { header = 'Carry Pet', params = { event='qb-pets:client:Carry' } }
    menu[#menu+1] = { header = 'Put In Car', params = { event='qb-pets:client:PutInCar' } }
  end

  exports['qb-menu']:openMenu(menu)
end)

RegisterNetEvent('qb-pets:client:ChoosePetToSpawn', function()
  if #PlayerPets == 0 then
    Notify("You don't own any pets. Visit the pet shop!", 'error')
    return
  end
  local opts = {}
  for _, p in ipairs(PlayerPets) do
    opts[#opts+1] = {
      header = ('Spawn %s'):format(p.pet_name),
      txt = ('H:%d T:%d HP:%d'):format(p.hunger or 100, p.thirst or 100, p.health or 100),
      params = { event='qb-pets:client:SpawnPet', args=p }
    }
  end
  exports['qb-menu']:openMenu(opts)
end)

RegisterNetEvent('qb-pets:client:SpawnPet', function(p)
  if ActivePet.ent then Notify('Pet already out.', 'error') return end
  local model = p.pet_model
  if not LoadModel(model) then Notify('Pet model invalid.', 'error') return end
  local ped = PlayerPedId()
  local coords = GetOffsetFromEntityInWorldCoords(ped, 0.0, 1.0, 0.0)
  local pet = CreatePed(28, joaat(model), coords.x, coords.y, coords.z, GetEntityHeading(ped), true, true)

  SetEntityAsMissionEntity(pet, true, true)
  SetBlockingOfNonTemporaryEvents(pet, true)
  SetPedFleeAttributes(pet, 0, false)
  SetPedCanRagdoll(pet, true)
  SetPedRelationshipGroupHash(pet, `PLAYER`)
  SetEntityInvincible(pet, false)

  ActivePet.ent = pet
  ActivePet.id = p.id
  ActivePet.model = model
  ActivePet.stats.hunger = p.hunger or 100
  ActivePet.stats.thirst = p.thirst or 100
  ActivePet.stats.health = p.health or 100
  ActivePet.stats.out_state = 1
  TriggerServerEvent('qb-pets:server:SetPetOutState', p.id, true)
  Notify(('Spawned %s.'):format(p.pet_name), 'success')
end)

RegisterNetEvent('qb-pets:client:PutAway', function()
  if not ActivePet.ent then return end
  SaveStats()
  TriggerServerEvent('qb-pets:server:SetPetOutState', ActivePet.id, false)
  ClearPet()
  Notify('Pet put away.', 'success')
end)

RegisterNetEvent('qb-pets:client:Bring', function()
  if not ActivePet.ent then return end
  local ped = PlayerPedId()
  local coords = GetOffsetFromEntityInWorldCoords(ped, 0.0, 1.0, 0.0)
  SetEntityCoords(ActivePet.ent, coords.x, coords.y, coords.z, false, false, false, false)
  TaskGoToEntity(ActivePet.ent, ped, -1, 1.5, 2.0, 0, 0)
end)

RegisterNetEvent('qb-pets:client:SetState', function(state)
  if not ActivePet.ent then return end
  ActivePet.state = state
  if state == 'stay' then
    ClearPedTasks(ActivePet.ent)
    TaskStandStill(ActivePet.ent, -1)
  elseif state == 'follow' then
    TaskFollowToOffsetOfEntity(ActivePet.ent, PlayerPedId(), 0.0, -1.5, 0.0, 2.0, -1, 1.0, true)
  end
end)

RegisterNetEvent('qb-pets:client:Sit', function()
  if not ActivePet.ent then return end
  PlayAnim(ActivePet.ent, 'creatures@rottweiler@amb@world_dog_sitting@base', 'base', 1, -1)
end)

RegisterNetEvent('qb-pets:client:Lie', function()
  if not ActivePet.ent then return end
  PlayAnim(ActivePet.ent, 'creatures@rottweiler@amb@sleep_in_kennel@', 'sleep_in_kennel', 1, -1)
end)

RegisterNetEvent('qb-pets:client:Play', function()
  if not ActivePet.ent then return end
  PlayAnim(ActivePet.ent, 'creatures@rottweiler@play@', 'fetch_pickup', 1, 4000)
end)

local function useItemCommon(itemName, delta)
  if not ActivePet.ent then Notify('No pet out.', 'error') return end
  QBCore.Functions.TriggerCallback('qb-pets:server:UseItemOnPet', function(ok)
    if not ok then Notify("You don't have that item.", 'error') return end
    if delta.hunger then
      ActivePet.stats.hunger = math.min(100, (ActivePet.stats.hunger or 0) + delta.hunger)
    end
    if delta.thirst then
      ActivePet.stats.thirst = math.min(100, (ActivePet.stats.thirst or 0) + delta.thirst)
    end
    if delta.health then
      ActivePet.stats.health = math.min(100, (ActivePet.stats.health or 0) + delta.health)
      SetEntityHealth(ActivePet.ent, math.min(200, GetEntityHealth(ActivePet.ent) + math.floor(delta.health/2)))
    end
    SaveStats()
    Notify('Pet cared for.', 'success')
  end, itemName)
end

RegisterNetEvent('qb-pets:client:Feed', function()
  useItemCommon('pet_food', { hunger=40 })
end)

RegisterNetEvent('qb-pets:client:Drink', function()
  useItemCommon('pet_water', { thirst=40 })
end)

RegisterNetEvent('qb-pets:client:Med', function()
  useItemCommon('pet_med', { health=60 })
end)

RegisterNetEvent('qb-pets:client:Carry', function()
  if not ActivePet.ent then return end
  local ped = PlayerPedId()
  local o = Config.CarryOffsets.default
  AttachEntityToEntity(ActivePet.ent, ped, GetPedBoneIndex(ped, o.bone), o.x, o.y, o.z, o.rx, o.ry, o.rz, false, false, false, false, 2, true)
  ActivePet.state = 'carry'
  Notify('Carrying pet. Use /pet → Follow to drop.', 'primary')
end)

RegisterNetEvent('qb-pets:client:PutInCar', function()
  if not ActivePet.ent then return end
  local ped = PlayerPedId()
  local veh = GetVehiclePedIsIn(ped, false)
  if veh == 0 then
    local pos = GetEntityCoords(ped)
    veh = GetClosestVehicle(pos.x, pos.y, pos.z, 7.5, 0, 70)
  end
  if veh == 0 then Notify('No vehicle nearby.', 'error') return end
  local bone = GetEntityBoneIndexByName(veh, Config.VehicleBone)
  if bone == -1 then bone = 0 end
  AttachEntityToEntity(ActivePet.ent, veh, bone, 0.0, -0.5, 0.0, 0.0, 0.0, 0.0, false, false, false, false, 2, true)
  ActivePet.state = 'in_car'
  Notify('Pet placed in vehicle.', 'success')
end)

CreateThread(function()
  while true do
    Wait(Config.TickRateMs)
    if ActivePet.ent and DoesEntityExist(ActivePet.ent) then
      ActivePet.stats.hunger = math.max(0, (ActivePet.stats.hunger or 100) - Config.HungerDrain)
      ActivePet.stats.thirst = math.max(0, (ActivePet.stats.thirst or 100) - Config.ThirstDrain)
      if (ActivePet.stats.hunger < 10 or ActivePet.stats.thirst < 10) then
        ActivePet.stats.health = math.max(0, (ActivePet.stats.health or 100) - Config.HealthDrainBelowNeed)
        if GetEntityHealth(ActivePet.ent) > 100 then
          SetEntityHealth(ActivePet.ent, GetEntityHealth(ActivePet.ent) - 1)
        end
      end
      SaveStats()
      if ActivePet.state == 'follow' then
        TaskFollowToOffsetOfEntity(ActivePet.ent, PlayerPedId(), 0.0, -1.5, 0.0, 2.0, -1, 1.0, true)
      end
    end
  end
end)

AddEventHandler('QBCore:Client:OnPlayerLoaded', function()
  TriggerEvent('qb-pets:client:RefreshPets')
end)

AddEventHandler('onResourceStop', function(res)
  if res ~= GetCurrentResourceName() then return end
  if ActivePet.ent and DoesEntityExist(ActivePet.ent) then
    DeleteEntity(ActivePet.ent)
  end
  if ShopPed and DoesEntityExist(ShopPed) then
    DeleteEntity(ShopPed)
  end
end)


RegisterNUICallback('petAction', function(data, cb)
  local act = data.action
  local id = data.id
  if act == 'Spawn' and id then
    -- find pet row cached on client by requesting fresh list once more
    QBCore.Functions.TriggerCallback('qb-pets:server:GetPets', function(rows)
      local row = nil
      if rows then
        for _, r in ipairs(rows) do if tonumber(r.id) == tonumber(id) then row = r break end end
      end
      if row then TriggerEvent('qb-pets:client:SpawnPet', row) end
    end)
  elseif act == 'PutAway' then
    TriggerEvent('qb-pets:client:PutAway')
  elseif act == 'Bring' then
    TriggerEvent('qb-pets:client:Bring')
  elseif act == 'Follow' then
    TriggerEvent('qb-pets:client:SetState', 'follow')
  elseif act == 'Stay' then
    TriggerEvent('qb-pets:client:SetState', 'stay')
  elseif act == 'Sit' then
    TriggerEvent('qb-pets:client:Sit')
  elseif act == 'Lie' then
    TriggerEvent('qb-pets:client:Lie')
  elseif act == 'Play' then
    TriggerEvent('qb-pets:client:Play')
  elseif act == 'Feed' then
    TriggerEvent('qb-pets:client:Feed')
  elseif act == 'Drink' then
    TriggerEvent('qb-pets:client:Drink')
  elseif act == 'Med' then
    TriggerEvent('qb-pets:client:Med')
  elseif act == 'Carry' then
    TriggerEvent('qb-pets:client:Carry')
  elseif act == 'PutInCar' then
    TriggerEvent('qb-pets:client:PutInCar')
  end
  cb('ok')
end)


-- Backup command to open the new NUI panel directly
RegisterCommand('petui', function()
  SetNuiFocus(true, true)
  SendNUIMessage({ action='openPetPanel' })
  TriggerEvent('qb-pets:client:RefreshPets')
end)


-- /pet opens the slick NUI Pet Control panel
RegisterCommand('pet', function()
  SetNuiFocus(true, true)
  SendNUIMessage({ action='openPetPanel' })
  TriggerEvent('qb-pets:client:RefreshPets')
end)


-- Fallback: manually release NUI focus if cursor ever sticks
RegisterCommand('uiblurreset', function()
  SetNuiFocus(false, false)
  if SetNuiFocusKeepInput ~= nil then SetNuiFocusKeepInput(false) end
end)
