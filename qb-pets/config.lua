Config = {}

-- Notifications: 'okok' for okokNotify, 'qb' for QBCore.Functions.Notify
Config.Notify = 'okok'

-- Shop NPC + Target
Config.Shop = {
  PedModel = 's_m_m_ammucountry',  -- change to whatever clerk you like
  PedHeading = 90.0,
  PedCoords = vec3(-269.61, 6284.07, 31.49), -- <- edit location
  TargetIcon = 'fa-solid fa-paw',
  TargetLabel = 'Open Pet Shop',
  TargetDistance = 2.0,
}

-- Animals available to buy. model must be a valid ped model (animal)
Config.Animals = {
  { key='shepherd', label='German Shepherd', model='a_c_shepherd', price=2500 },
  { key='husky',    label='Husky',           model='a_c_husky',    price=2500 },
  { key='pug',      label='Pug',             model='a_c_pug',      price=2000 },
  { key='rott',     label='Rottweiler',      model='a_c_rottweiler',price=2600 },
  { key='cat',      label='Cat',             model='a_c_cat_01',   price=1200 },
}

-- Shop items
Config.ShopItems = {
  food = {
    { name='pet_food',  label='Pet Food',  price=50,  hunger=40 },
    { name='pet_treat', label='Pet Treat', price=25,  hunger=15 },
  },
  drink = {
    { name='pet_water', label='Pet Water', price=20,  thirst=40 },
  },
  health = {
    { name='pet_med',   label='Pet Medkit', price=120, heal=60 },
  }
}

-- Hunger / thirst / health ranges 0-100
Config.TickRateMs = 15000      -- how often to drain needs (pet out)
Config.HungerDrain = 1         -- per tick
Config.ThirstDrain = 1         -- per tick
Config.HealthDrainBelowNeed = 2 -- if hunger/thirst < 10

-- Carry offsets per species (tweak as you like)
Config.CarryOffsets = {
  default = { x=0.2, y=0.15, z=-0.25, bone=57005, rx=0.0, ry=90.0, rz=0.0 }, -- R hand
}

-- Put in car: attach to rear seat bone if animal can’t enter vehicles
Config.VehicleBone = 'seat_pside_r' -- fallback bone
