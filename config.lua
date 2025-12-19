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

-- Cinematic death FX toggle and intensity
Config.DeathFX = true
Config.DeathFXStrength = 0.35         -- intensity of the desaturation (0-1)
Config.DeathFXBlur = true             -- optional light blur overlay
Config.DeathFXBlurFadeMs = 600        -- fade in/out duration for blur
Config.DeathFXFadeOutMs = 500         -- how long to ease visuals out on revive/respawn

-- Heartbeat loop while downed
Config.Heartbeat = true
Config.HeartbeatVolume = 0.20         -- 0.0 to disable the loop entirely
Config.HeartbeatIntervalMs = 1200     -- gap between heartbeat pulses

-- Force unarmed + block weapons while downed
Config.DisableWeaponsWhileDowned = true
