-- sinspire_death/server.lua

-- ===== STATE =====
local down = {}  -- [playerId] = { reviveAt = unix, respawnAt = unix }

-- ===== UTILS =====
local function now() return os.time() end
local function online(id) return id and GetPlayerPing(id) and GetPlayerPing(id) > 0 end
local function secsLeft(t) local d=(t or 0)-now(); return d>0 and d or 0 end
local function msg(target, text, tag)
  TriggerClientEvent('chat:addMessage', target, { args = { tag or '^2System', text } })
end

local function isDown(target, notify)
  local st = down[target]
  if not st then
    msg(notify or target, 'You are not down right now.', '^3System')
    return false
  end
  return true, st
end

local function hasAce(src, perm)
  if src == 0 then return true end -- console always allowed
  return IsPlayerAceAllowed(src, perm)
end

-- ===== CLIENT → SERVER =====
RegisterNetEvent('sinspire_death:setDownState', function(reviveDelay, respawnDelay)
  local src = source
  reviveDelay  = tonumber(reviveDelay)  or 0
  respawnDelay = tonumber(respawnDelay) or 0
  down[src] = { reviveAt = now() + reviveDelay, respawnAt = now() + respawnDelay }
  print(('[sinspire_death] %s down: revive+%ss respawn+%ss'):format(src, reviveDelay, respawnDelay))
end)

AddEventHandler('playerDropped', function()
  down[source] = nil
end)

-- ===== DEBUG =====
RegisterCommand('deathstatus', function(src, args)
  local target = tonumber(args[1] or '') or src
  if not online(target) then return msg(src, 'Player not online.', '^1System') end
  local st = down[target]
  if not st then return msg(src, 'No down record (client didn’t signal death).', '^3System') end
  msg(src, ('Revive in: %ss | Respawn in: %ss'):format(secsLeft(st.reviveAt), secsLeft(st.respawnAt)))
end, false)

-- ===== STANDARD (respect timers) =====
RegisterCommand('revive', function(src, args)
  local target = tonumber(args[1] or '') or src
  if not online(target) then return msg(src, 'Player not online.', '^1System') end
  local ok, st = isDown(target, src)
  if not ok then return end
  local left = secsLeft(st.reviveAt)
  if left > 0 then return msg(src, ('Revive available in %ss'):format(left), '^3System') end
  TriggerClientEvent('sinspire_death:reviveClient', target)
  down[target] = nil
  if target ~= src then
    msg(src,    ('Revived %s.'):format(GetPlayerName(target) or target))
    msg(target, 'You were revived.')
  end
end, false)

RegisterCommand('respawn', function(src, args)
  local target = tonumber(args[1] or '') or src
  if not online(target) then return msg(src, 'Player not online.', '^1System') end
  local ok, st = isDown(target, src)
  if not ok then return end
  local left = secsLeft(st.respawnAt)
  if left > 0 then return msg(src, ('Respawn available in %ss'):format(left), '^3System') end
  TriggerClientEvent('sinspire_death:respawnClient', target)
  down[target] = nil
  if target ~= src then
    msg(src,    ('Respawned %s at hospital.'):format(GetPlayerName(target) or target))
    msg(target, 'You were respawned at hospital.')
  end
end, false)

RegisterNetEvent('sinspire_death:reqRespawn', function()
  local src = source
  local ok, st = isDown(src)
  if not ok then return end
  local left = secsLeft(st.respawnAt)
  if left > 0 then return msg(src, ('Respawn available in %ss'):format(left), '^3System') end
  TriggerClientEvent('sinspire_death:respawnClient', src)
  down[src] = nil
end)

-- ===== ADMIN (ACE-locked) =====
-- Permissions used:
--   sinspire.adrev
--   sinspire.adres

RegisterCommand('adrev', function(src, args)
  if not hasAce(src, 'sinspire.adrev') then return msg(src, 'No permission.', '^1System') end
  local target = tonumber(args[1] or '') or src
  if not online(target) then return msg(src, 'Invalid or offline ID.', '^1System') end
  TriggerClientEvent('sinspire_death:reviveClient', target)
  down[target] = nil
  if target == src then
    msg(src, '^2Admin: You revived yourself.')
  else
    msg(src,    ('^2Admin: You revived %s.'):format(GetPlayerName(target) or target))
    msg(target, '^2Admin: An admin revived you.')
  end
end, false)

RegisterCommand('adres', function(src, args)
  if not hasAce(src, 'sinspire.adres') then return msg(src, 'No permission.', '^1System') end
  local target = tonumber(args[1] or '') or src
  if not online(target) then return msg(src, 'Invalid or offline ID.', '^1System') end
  TriggerClientEvent('sinspire_death:respawnClient', target)
  down[target] = nil
  if target == src then
    msg(src, '^2Admin: You respawned yourself at a hospital.')
  else
    msg(src,    ('^2Admin: You respawned %s at a hospital.'):format(GetPlayerName(target) or target))
    msg(target, '^2Admin: An admin respawned you at a hospital.')
  end
end, false)

-- ===== OPTIONAL SIMPLE 911 BROADCAST =====
RegisterNetEvent('sinspire_death:notifyEMS', function()
  local src = source
  local name = GetPlayerName(src) or ('ID %s'):format(src)
  local ped  = GetPlayerPed(src)
  local txt
  if ped ~= 0 then
    local c = GetEntityCoords(ped)
    txt = ('^7%s is down near ^5(%.1f, %.1f)^7.'):format(name, c.x, c.y)
  else
    txt = ('^7%s reported down (no coords).'):format(name)
  end
  TriggerClientEvent('chat:addMessage', -1, { args = { '^3[911]^0', txt } })
end)