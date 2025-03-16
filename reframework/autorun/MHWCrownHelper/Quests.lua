local Quests                = {};
local Event                 = require("MHWCrownHelper.Event");
local Utils                 = require("MHWCrownHelper.Utils");
local Singletons            = require("MHWCrownHelper.Singletons")

Quests.onLocationChanged    = Event.New();
Quests.onPlayerChanged      = Event.New();
local currentPlayerUniqueId = nil;
local hasMasterPlayer       = false;

-------------------------------------------------------------------

function Quests.OnSceneLoadEndHook(args)
    Quests.onLocationChanged();
end

-------------------------------------------------------------------

function Quests.UpdateMasterPlayer()
    Utils.logDebug("Updating current master player");
    hasMasterPlayer = false;
    if Singletons.PlayerManager == nil then return; end;
    local cPlayerManageInfo = Singletons.PlayerManager:getMasterPlayerInfo();
    if cPlayerManageInfo == nil then return; end;
    local cPlayerContextHolder = cPlayerManageInfo:get_ContextHolder();
    if cPlayerContextHolder == nil then return; end;
    local cPlayerContext = cPlayerContextHolder:get_Pl();
    if cPlayerContext == nil then return; end;
    local uniqueId = cPlayerContext:get_UniqueID();
    if uniqueId == nil then return; end;

    hasMasterPlayer = true;
    if currentPlayerUniqueId == nil or currentPlayerUniqueId ~= uniqueId then
        currentPlayerUniqueId = uniqueId;
        Quests.onPlayerChanged();
        Utils.logDebug("New player detected!");
    end
end

-------------------------------------------------------------------

function Quests.PostCreateMasterPlayer()
    Quests.UpdateMasterPlayer();
end

-------------------------------------------------------------------

function Quests.HasMasterPlayer()
    return hasMasterPlayer;
end

-------------------------------------------------------------------

function Quests.InitModule()
    Utils.Hook("app.EnemyManager", "evSceneLoadEnd_ThroughJunction", Quests.OnSceneLoadEndHook);
    Utils.Hook("app.EnemyManager", "evSceneLoadEnd_FastTravel", Quests.OnSceneLoadEndHook);
    Utils.Hook("app.PlayerManager", "registerPlayer", nil, Quests.PostCreateMasterPlayer);
    Quests.UpdateMasterPlayer();
    Utils.logDebug("Quests Initialized");
end

return Quests;
