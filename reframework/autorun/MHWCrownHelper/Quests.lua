local Quests             = {};
local Event              = require("MHWCrownHelper.Event");
local Utils              = require("MHWCrownHelper.Utils");

Quests.onLocationChanged = Event.New();

-------------------------------------------------------------------

---The update hook function for the
---@param args any
function Quests.OnSceneLoadEndHook(args)
    --[[ local newQuestStatus = sdk.to_int64(args[3]);
    if newQuestStatus ~= nil then
        -- invoke quest status changed event
        if newQuestStatus ~= Quests.gameStatus then
            Quests.gameStatus = newQuestStatus;
            Quests.onGameStatusChanged(Quests.gameStatus);
        end
    end ]]
    Quests.onLocationChanged();
end

-------------------------------------------------------------------

function Quests.InitModule()
    Utils.Hook("app.EnemyManager", "evSceneLoadEnd_ThroughJunction", Quests.OnSceneLoadEndHook);
    Utils.Hook("app.EnemyManager", "evSceneLoadEnd_FastTravel", Quests.OnSceneLoadEndHook);
end

return Quests;
