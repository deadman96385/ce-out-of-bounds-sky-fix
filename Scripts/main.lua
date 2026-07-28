-- Expand Campaign Evolved's finite, inverted-normal sky domes once per level.
--
-- The shipped sky is not an infinite Unreal background. BP_UltraSky renders
-- SM_Sphere_FlipNormal_100cm from the inside; once a modded player physically
-- leaves that sphere, its backfaces disappear and the clear color is black.
-- Normal gameplay never reaches the outside, so the stock game does not need
-- to handle this case. 

local generation = 0
local skyComponents = {}
local SKY_WORLD_SCALE = 1000000.0

local function valid(object)
    if object == nil then return false end
    local ok, result = pcall(function() return object:IsValid() end)
    return ok and result
end

local function fullName(object)
    local ok, result = pcall(function() return object:GetFullName() end)
    return ok and result or "<unknown>"
end

local function getPlayerController()
    local controllers = FindAllOf("PlayerController") or {}
    for _, controller in ipairs(controllers) do
        if valid(controller) then
            local ok, camera = pcall(function() return controller.PlayerCameraManager end)
            if ok and valid(camera) then return controller end
        end
    end
    return nil
end

local function addComponent(component, seen)
    if not valid(component) then return end
    local name = fullName(component)
    if seen[name] then return end
    seen[name] = true
    table.insert(skyComponents, component)
end

local function refreshSkyComponents()
    skyComponents = {}
    local seen = {}

    -- This is the common sky on the Halo 1 campaign maps.
    for _, actor in ipairs(FindAllOf("BP_UltraSky_C") or {}) do
        if valid(actor) then
            local ok, component = pcall(function() return actor.SkyDome end)
            if ok then addComponent(component, seen) end
        end
    end

    -- A few maps use their own SM_*_Skydome / SM_*_Skybox component instead.
    -- Scan once per level load, then keep only the small cached set.
    for _, component in ipairs(FindAllOf("StaticMeshComponent") or {}) do
        if valid(component) then
            local ok, mesh = pcall(function() return component:GetStaticMesh() end)
            if ok and valid(mesh) then
                local meshName = fullName(mesh):lower()
                local inSkyFolder = meshName:find("/env/skybox/skydome/", 1, true) ~= nil
                local isBackdrop =
                    meshName:find("skydome", 1, true) ~= nil
                    or meshName:find("skybox", 1, true) ~= nil
                    or meshName:find("sphere_flipnormal", 1, true) ~= nil
                if inSkyFolder and isBackdrop then addComponent(component, seen) end
            end
        end
    end

end

local function expandSky()
    local controller = getPlayerController()
    if not controller then return end

    local camera = controller.PlayerCameraManager
    local okLocation, cameraLocation =
        pcall(function() return camera:GetCameraLocation() end)
    if not okLocation then return end

    for _, component in ipairs(skyComponents) do
        if valid(component) then
            local hit = {}
            pcall(function()
                component:K2_SetWorldLocation(cameraLocation, false, hit, true)
            end)
            pcall(function()
                component:SetWorldScale3D({
                    X = SKY_WORLD_SCALE,
                    Y = SKY_WORLD_SCALE,
                    Z = SKY_WORLD_SCALE,
                })
            end)
        end
    end
end

local function startForCurrentLevel()
    generation = generation + 1
    local myGeneration = generation

    ExecuteWithDelay(2000, function()
        ExecuteInGameThread(function()
            if myGeneration ~= generation then return end
            refreshSkyComponents()
            expandSky()
        end)
    end)
end

RegisterHook("/Script/Engine.PlayerController:ClientRestart", function()
    startForCurrentLevel()
end)

startForCurrentLevel()
