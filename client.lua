-- sinspire_death/client.lua

local isDead, notifySent = false, false
local respawnTimer, reviveTimer = 0, 0
local canRespawn, canRevive = false, false

local heartbeatRunning, heartbeatSoundId = false, nil
local deathFxActive = false
local weaponLoopActive = false

local heartbeatRunning, heartbeatSoundId = false, nil

local heartbeatRunning, heartbeatSoundId = false, nil

-- ================= visuals =================
local function drawTxt(msg, x, y, scale, r, g, b, a)
    SetTextFont(4)
    SetTextProportional(0)
    SetTextScale(scale or 0.35, scale or 0.35)
    SetTextColour(r or 255, g or 255, b or 255, a or 215)
    SetTextDropShadow(0,0,0,0,255)
    SetTextEdge(2,0,0,0,150)
    SetTextOutline()
    SetTextCentre(true)
    BeginTextCommandDisplayText("STRING")
    AddTextComponentSubstringPlayerName(msg)
    EndTextCommandDisplayText(x or 0.5, y or 0.92)
end

local function drawOverlay(alpha)
    DrawRect(0.5, 0.5, 1.0, 1.0, 20, 20, 20, alpha or 170)
end

-- ================= helpers =================
local function nearestHospital()
    local ped = PlayerPedId()
    local p   = GetEntityCoords(ped)
    local best, bestDist
    for _,h in ipairs(Config.Hospitals) do
        local d = #(p - h.coords)
        if not best or d < bestDist then best, bestDist = h, d end
    end
    return best
end

local function healCommon(ped)
    ClearPedBloodDamage(ped)
    ResetPedVisibleDamage(ped)
    ClearPedTasksImmediately(ped)
    SetEntityHealth(ped, Config.RespawnHealth)
    SetPedArmour(ped, Config.RespawnArmor)
end

local function healCommon(ped)
    ClearPedBloodDamage(ped)
    ResetPedVisibleDamage(ped)
    ClearPedTasksImmediately(ped)
    SetEntityHealth(ped, Config.RespawnHealth)
    SetPedArmour(ped, Config.RespawnArmor)
end

-- ================= audio (light duck, not mute) =================
local AUDIO_SCENE = "MP_MENU_SCENE"
local function startAudioDuck()
    if not IsAudioSceneActive(AUDIO_SCENE) then StartAudioScene(AUDIO_SCENE) end
    SetAudioSceneVariable(AUDIO_SCENE, "KillstreakVolume", Config.AudioDuckVolume)
    SetAudioSceneVariable(AUDIO_SCENE, "MapZoomVolume", Config.AudioDuckVolume)
end
local function stopAudioDuck()
    if IsAudioSceneActive(AUDIO_SCENE) then
        SetAudioSceneVariable(AUDIO_SCENE, "KillstreakVolume", 1.0)
        SetAudioSceneVariable(AUDIO_SCENE, "MapZoomVolume", 1.0)
        StopAudioScene(AUDIO_SCENE)
    end
end

-- ================= cinematic FX (visuals + heartbeat) =================
local function startDownedFx()
    if Config.DownedEffects.Timecycle then
        SetTimecycleModifier(Config.DownedEffects.Timecycle)
        SetTimecycleModifierStrength(Config.DownedEffects.DesatStrength or 0.35)
    end

    if Config.DownedEffects.EnableBlur then
        TriggerScreenblurFadeIn(Config.DownedEffects.BlurFadeMs or 500)
    end

    if (Config.DownedEffects.HeartbeatVolume or 0) > 0 and not heartbeatRunning then
        heartbeatRunning = true
        CreateThread(function()
            local interval = Config.DownedEffects.HeartbeatIntervalMs or 1200
            while heartbeatRunning and isDead do
                heartbeatSoundId = GetSoundId()
                PlaySoundFromEntity(heartbeatSoundId, "HeartBeat", PlayerPedId(), "MP_MISSION_COUNTDOWN_SOUNDSET", false, 0)
                SetVariableOnSound(heartbeatSoundId, "Volume", Config.DownedEffects.HeartbeatVolume)

                local elapsed = 0
                while heartbeatRunning and elapsed < interval do
                    Wait(100)
                    elapsed = elapsed + 100
                end

                StopSound(heartbeatSoundId)
                ReleaseSoundId(heartbeatSoundId)
                heartbeatSoundId = nil
            end
        end)
    end
end

local function stopDownedFx()
    heartbeatRunning = false
    if heartbeatSoundId then
        StopSound(heartbeatSoundId)
        ReleaseSoundId(heartbeatSoundId)
        heartbeatSoundId = nil
    end

    if Config.DownedEffects.EnableBlur then
        TriggerScreenblurFadeOut(Config.DownedEffects.BlurFadeMs or 500)
    end

    if Config.DownedEffects.Timecycle then
        local fade = Config.DownedEffects.FadeOutMs or 0
        if fade > 0 then
            local steps = math.max(1, math.floor(fade / 80))
            for i = steps, 0, -1 do
                local strength = (Config.DownedEffects.DesatStrength or 0.35) * (i / steps)
                SetTimecycleModifierStrength(strength)
                Wait(80)
            end
        end
        ClearTimecycleModifier()
        ClearExtraTimecycleModifier()
    end
end

-- ================= revive / respawn =================
local function reviveHere()
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local heading = GetEntityHeading(ped)

    DoScreenFadeOut(120); while not IsScreenFadedOut() do Wait(0) end
    stopAudioDuck()
    stopDownedFx()
    RenderScriptCams(false, false, 0, true, true)

    NetworkResurrectLocalPlayer(coords.x, coords.y, coords.z, heading, true, true, false)
    healCommon(ped)
    isDead, notifySent = false, false
    respawnTimer, reviveTimer = 0, 0
    canRespawn, canRevive = false, false
    DoScreenFadeIn(220)
end

local function respawnHospital()
    local spot = nearestHospital()
    local ped  = PlayerPedId()

    DoScreenFadeOut(160); while not IsScreenFadedOut() do Wait(0) end
    stopAudioDuck()
    stopDownedFx()
    RenderScriptCams(false, false, 0, true, true)

    NetworkResurrectLocalPlayer(spot.coords.x, spot.coords.y, spot.coords.z, spot.heading or 0.0, true, true, false)
    healCommon(ped)
    isDead, notifySent = false, false
    respawnTimer, reviveTimer = 0, 0
    canRespawn, canRevive = false, false
    DoScreenFadeIn(260)
end

-- ================= hold-to-respawn key =================
RegisterKeyMapping('+sinspire_respawn', 'Respawn (when allowed)', 'keyboard', Config.KeyRespawn)

local holding = false
RegisterCommand('+sinspire_respawn', function()
    if isDead and canRespawn and not holding then
        holding = true
        local start = GetGameTimer()
        while holding and GetGameTimer() - start < Config.RespawnHoldMs do
            Wait(0)
            local pct = ((GetGameTimer()-start)/Config.RespawnHoldMs)*100.0
            drawTxt(('Respawning... %.0f%%'):format(pct), 0.5, 0.86, 0.5, 0, 200, 0)
        end
        if holding then TriggerServerEvent('sinspire_death:reqRespawn') end
        holding = false
    end
end, false)
RegisterCommand('-sinspire_respawn', function() holding = false end, false)

-- ================= main loop =================
CreateThread(function()
    local wasDead = false

    while true do
        local sleep = 350
        local ped = PlayerPedId()
        local nowDead = IsEntityDead(ped)

        if nowDead and not wasDead then
            isDead = true
            notifySent = false
            respawnTimer = Config.RespawnDelaySeconds
            reviveTimer  = Config.ReviveDelaySeconds
            canRespawn, canRevive = false, false

            startAudioDuck()
            startDownedFx()
            RenderScriptCams(false, false, 0, true, true)

            TriggerServerEvent('sinspire_death:setDownState', Config.ReviveDelaySeconds, Config.RespawnDelaySeconds)

        elseif not nowDead and wasDead then
            stopAudioDuck()
            stopDownedFx()
            RenderScriptCams(false, false, 0, true, true)
            isDead, notifySent = false, false
            respawnTimer, reviveTimer = 0, 0
            canRespawn, canRevive = false, false
        end
        wasDead = nowDead

        if isDead then
            sleep = 0

            -- dark overlay
            drawOverlay(180)

            -- block movement/attack; leave camera + chat alone
            if Config.DisableControlsWhileDown then
                DisableControlAction(0, 30,  true)  -- Move LR
                DisableControlAction(0, 31,  true)  -- Move UD
                DisableControlAction(0, 32,  true)  -- W
                DisableControlAction(0, 33,  true)  -- S
                DisableControlAction(0, 34,  true)  -- A
                DisableControlAction(0, 35,  true)  -- D
                DisableControlAction(0, 21,  true)  -- Sprint
                DisableControlAction(0, 22,  true)  -- Jump
                DisableControlAction(0, 36,  true)  -- Stealth
                DisableControlAction(0, 24,  true)  -- Attack
                DisableControlAction(0, 25,  true)  -- Aim
                DisableControlAction(0, 37,  true)  -- Weapon wheel
                DisableControlAction(0, 44,  true)  -- Cover
                DisableControlAction(0, 140, true)  -- Melee
                DisableControlAction(0, 141, true)
                DisableControlAction(0, 142, true)

                -- Explicitly allow free-look (mouse/controller) while downed
                EnableControlAction(0, 1, true)   -- Look left/right
                EnableControlAction(0, 2, true)   -- Look up/down
            end

            -- let GTA handle the default death cam — no camera overrides here

            -- timers + UI
            if respawnTimer > 0 or reviveTimer > 0 then
                drawTxt(('Respawn available in: %ss'):format(math.max(0, respawnTimer)), 0.5, 0.845, 0.50, 0, 150, 255)  -- blue
                drawTxt(('Revive available in: %ss'):format(math.max(0, reviveTimer)),   0.5, 0.875, 0.50, 220, 40, 40)  -- red
            else
                canRespawn, canRevive = true, true
                drawTxt(('Hold %s to respawn at hospital OR use /revive to stand up.'):format(Config.KeyRespawn), 0.5, 0.875, 0.50, 235, 235, 235)
            end
        end

        Wait(sleep)
    end
end)

-- timer thread
CreateThread(function()
    while true do
        if isDead then
            Wait(1000)
            if respawnTimer > 0 then respawnTimer = respawnTimer - 1 end
            if reviveTimer  > 0 then reviveTimer  = reviveTimer  - 1 end
        else
            Wait(600)
        end
    end
end)

-- ================= server -> client =================
RegisterNetEvent('sinspire_death:reviveClient', function()
    reviveHere()
end)

RegisterNetEvent('sinspire_death:respawnClient', function()
    respawnHospital()
end)
