local Singletons = {};

Singletons.EnemyManager = nil;
Singletons.GUIManager = nil;
Singletons.GameFlowManager = nil;
Singletons.ChatManager = nil;
Singletons.MissionManager = nil;

Singletons.isInitialized = false;

-------------------------------------------------------------------

---Initializes the singleton manager
function Singletons.Init()
    -- initialized flag will be reset if any of the following inits fails
    Singletons.isInitialized = true;

    Singletons.EnemyManager = Singletons.InitSingleton("app.EnemyManager");
    Singletons.GUIManager = Singletons.InitSingleton("app.GUIManager");
    Singletons.GameFlowManager = Singletons.InitSingleton("app.GameFlowManager");
    Singletons.ChatManager = Singletons.InitSingleton("app.ChatManager");
    Singletons.MissionManager = Singletons.InitSingleton("app.MissionManager");

    return Singletons.isInitialized;
end

-------------------------------------------------------------------

---Tries to get a managed singleton.
---@param name string
---@return REManagedObject|nil singleton
function Singletons.InitSingleton(name)
    local singleton = nil;

    singleton = sdk.get_managed_singleton(name);
    if singleton == nil then
        --Utils.logError("Singleton " .. name .. " not found!");
    end

    Singletons.isInitialized = Singletons.isInitialized and singleton ~= nil;

    return singleton;
end

-------------------------------------------------------------------

---Tries to get a native singleton.
---@param name string
---@return void_ptr|nil singleton
function Singletons.InitSingletonNative(name)
    local singleton = nil;

    singleton = sdk.get_native_singleton(name);
    if singleton == nil then
        --Utils.logError("Singleton " .. name .. " not found!");
    end

    Singletons.isInitialized = Singletons.isInitialized and singleton ~= nil;

    return singleton;
end

-------------------------------------------------------------------

function Singletons.InitModule()
    Singletons.Init();
end

-------------------------------------------------------------------

return Singletons;
