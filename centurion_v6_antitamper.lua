local function expectFailure(callback)
    local ok = pcall(callback)
    return not ok
end

local function checkCoreLibraries()
    if type(debug) ~= "table" or type(debug.info) ~= "function" then
        error("This environment is not supported. Verify that the debug library is fully accessible.")
    end

    if type(coroutine) ~= "table" or type(coroutine.wrap) ~= "function" then
        error("This environment is not supported. Verify that the coroutine library is fully accessible.")
    end
end

local function checkMetamethodSupport()
    local backing = {}
    local observedNewIndex = false

    local proxy = setmetatable({}, {
        __index = function(_, key)
            return backing[key]
        end,

        __newindex = function(_, key, value)
            observedNewIndex = true
            backing[key] = value
        end,

        __concat = function(left, right)
            return tostring(left) .. tostring(right)
        end,

        __tostring = function()
            return "uKlYB"
        end,

        __len = function()
            return 1
        end,

        __call = function(_, ...)
            return ...
        end,

        __metatable = "uKlYB",
    })

    proxy.value = 1

    return tostring(proxy) == "uKlYB"
        and backing.value == 1
        and observedNewIndex
        and getmetatable(proxy) == "uKlYB"
end

local function testClosureIntrospection()
    local hasIsCClosure = type(iscclosure) == "function"
    local hasIsLClosure = type(islclosure) == "function"
    local hasTaskSpawn = type(task) == "table" and type(task.spawn) == "function"

    if not hasIsCClosure or not hasIsLClosure then
        return false, false, hasTaskSpawn
    end

    local luaClosure = function() end
    local cClosureResult = iscclosure(Instance.new)
    local luaClosureResult = islclosure(luaClosure)

    return cClosureResult, luaClosureResult, hasTaskSpawn
end

local function testDebugAndEnvironmentFunctions()
    local sourceA = debug.info(1, "s")
    local sourceB = debug.info(1, "s")

    local getEnvironmentOk = pcall(function()
        return getfenv()
    end)

    local setEnvironmentOk = pcall(function()
        local function probe() end
        local environment = getfenv(probe)
        setfenv(probe, environment)
    end)

    return sourceA, sourceB, getEnvironmentOk, setEnvironmentOk
end

local function testLoadstringEnvironment()
    if type(loadstring) ~= "function" then
        return false
    end

    local environment = getfenv()
    local previous = environment.TSagp
    local marker = "TSagp"

    environment.TSagp = marker

    local compiled = loadstring("return TSagp")
    local ok = compiled ~= nil and compiled() == marker

    environment.TSagp = previous
    return ok
end

local function infiniteLoopProbe()
    while true do
    end
end

local function testSchedulerPrimitives()
    local spawnAvailable = type(task) == "table" and type(task.spawn) == "function"
    local deferAvailable = type(task) == "table" and type(task.defer) == "function"
    return spawnAvailable, deferAvailable, infiniteLoopProbe
end

local function runAntiTamperChecks()
    checkCoreLibraries()

    return {
        metamethods = checkMetamethodSupport(),
        closures = table.pack(testClosureIntrospection()),
        debugEnvironment = table.pack(testDebugAndEnvironmentFunctions()),
        loadstringEnvironment = testLoadstringEnvironment(),
        scheduler = table.pack(testSchedulerPrimitives()),
    }
end

return {
    run = runAntiTamperChecks,
    expectFailure = expectFailure,
}
