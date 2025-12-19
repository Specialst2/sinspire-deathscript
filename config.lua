Config = {}

-- DELAYS (seconds)
Config.ReviveDelaySeconds  = 60     -- time before /revive works
Config.RespawnDelaySeconds = 180    -- time before /respawn works

-- Hold time (ms) to confirm respawn when allowed
Config.RespawnHoldMs = 1500

-- Only respawn key left (since 911 key removed)
Config.KeyRespawn = 'G'

-- Hospitals (add or edit as needed)
Config.Hospitals = {
  { coords = vec3(307.71, -594.90, 43.28), heading = 70.0 },   -- Pillbox
  { coords = vec3(1839.5, 3672.0, 34.28),  heading = 210.0 },  -- Sandy
  { coords = vec3(-246.84, 6331.10, 32.43),heading = 45.0 },   -- Paleto
}

-- Health/armor on revive/respawn
Config.RespawnHealth = 200
Config.RespawnArmor  = 0

-- While downed, player can't move or attack but can free-look and chat
Config.DisableControlsWhileDown = true

-- Gentle audio ducking while downed (1.0 = normal volume, lower = quieter)
Config.AudioDuckVolume = 0.65