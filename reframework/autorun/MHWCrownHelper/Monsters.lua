local Monsters                   = {};
local Singletons                 = require("MHWCrownHelper.Singletons");
local Quests                     = require("MHWCrownHelper.Quests");
local Utils                      = require("MHWCrownHelper.Utils");
local Event                      = require("MHWCrownHelper.Event");
local Const                      = require("MHWCrownHelper.Const");

---@class EmID
---@class EnemyCharacter
---@class app.cEnemyContext
---@class cSizeData

-- general
local Enemy_ContextHolder        = sdk.find_type_definition("app.EnemyCharacter"):get_field("_Context");
local EnemyContextHolder_Context = sdk.find_type_definition("app.cEnemyContextHolder"):get_field("_Em");

-- name
local GetEnemyNameFunc           = sdk.find_type_definition("app.EnemyDef"):get_method("EnemyName(app.EnemyDef.ID)");
local GetMsgFunc                 = sdk.find_type_definition("via.gui.message"):get_method("get(System.Guid)");

-- Enemy Size
local GetSettingMethod           = sdk.find_type_definition("app.EnemyManager"):get_method("get_Setting()");
local GetSizeMethod              = sdk.find_type_definition("app.user_data.EnemyManagerSetting"):get_method(
    "get_Size()");
local GetSizeDataMethod          = sdk.find_type_definition("app.user_data.EmParamSize"):get_method(
    "getSizeData(app.EnemyDef.ID)");

-- Reports (Size infos of hunted monsters etc.)
local ReportUtil                 = sdk.find_type_definition("app.EnemyReportUtil");
local ReportUtilMinSize          = ReportUtil:get_method("getMinSize(app.EnemyDef.ID)");
local ReportUtilMaxSize          = ReportUtil:get_method("getMaxSize(app.EnemyDef.ID)");

local FindEnemyUniqueIndex       = sdk.find_type_definition("app.EnemyManager"):get_method(
    "findEnemy_UniqueIndex(System.Int32)");
local IsQuestTarget              = sdk.find_type_definition("app.MissionManager"):get_method(
    "isQuestTarget(app.TARGET_ACCESS_KEY)");

-- EmIDs
local ValidEmIDs                 = sdk.find_type_definition("app.EnemyManager"):get_field("_ValidEmIds");
local IsAnimalID                 = sdk.find_type_definition("app.EnemyDef"):get_method("isAnimalID(app.EnemyDef.ID)");
local IsBossID                   = sdk.find_type_definition("app.EnemyDef"):get_method("isBossID(app.EnemyDef.ID)");
local IDToIsFish                 = sdk.find_type_definition("app.EnemyDef"):get_method("IDToIsFish(app.EnemyDef.ID)");
local IsZakoID                   = sdk.find_type_definition("app.EnemyDef"):get_method("isZakoID(app.EnemyDef.ID)");

-- Registered monsters k[ctx], v[monster]
Monsters.monsters                = {};
-- All available monster types k[emType], v[table]
Monsters.monsterDefinitions      = {};
Monsters.sortedKeysByName        = {};

Monsters.UpdateInterval          = 5.0;
local nextRemovalUpdate          = 0.0;
Monsters.CheckForRemovalInterval = 5.0;
Monsters.RemoveAfterInactivity   = 20;

Monsters.onMonsterAdded          = Event.New();
Monsters.onMonsterRemoved        = Event.New();

local monsterDebugIndex          = 0;

-------------------------------------------------------------------

function Monsters.OnLocationChangedCallback()
    -- TODO: Update size infos every time the player kills a monster
    --[[ if Quests.gameStatus == 1 then
        -- Update the size infos when coming back to village
        Monsters.InitSizeInfos();
        Monsters.InitList();
    end ]]

    -- Player changed location
    -- Clear the outdated monster list when on a new quest
    Monsters.InitList();
end

-------------------------------------------------------------------

function Monsters.Update(deltaTime)
    local time = os.time();
    if time < nextRemovalUpdate then
        return;
    end
    nextRemovalUpdate = time + Monsters.CheckForRemovalInterval;

    local monstersToRemove = {};
    -- find monsters that have timed out
    for k, v in pairs(Monsters.monsters) do
        local timeDiff = time - v.LastUpdate;
        if (timeDiff > Monsters.RemoveAfterInactivity) then
            table.insert(monstersToRemove, k);
            Monsters.onMonsterRemoved(v);
        end
    end

    -- remove the timed out monsters
    for _, v in pairs(monstersToRemove) do
        Monsters.monsters[v] = nil;
    end
end

-------------------------------------------------------------------

--- Monster hook function.
---@param enemy EnemyCharacter The enemy provided by the hook
function Monsters.doUpdateEndCallback(enemy)
    if enemy == nil then
        return;
    end

    local ctx_holder = Enemy_ContextHolder:get_data(enemy);
    if ctx_holder == nil then return end;

    local ctx = EnemyContextHolder_Context:get_data(ctx_holder);
    if ctx == nil then return end;

    -- only handle boss enemies
    local IsBoss = ctx:get_IsBoss()
    if not IsBoss then return end;

    local monster = Monsters.monsters[ctx];
    local time = os.time();
    if monster == nil then
        monster = Monsters.NewMonster(ctx);
        monster.NextUpdate = time;
    end

    if monster ~= nil then
        if monster.NextUpdate - time <= 0 then
            monster.LastUpdate = time;
            monster.NextUpdate = time + Monsters.UpdateInterval;

            local browser = ctx:get_Browser();
            if browser then
                monster.area = browser:getCurrentAreaNo();
                monster.targetArea = browser:getTargetAreaNo();
            end

            -- Update death state
            if not monster.isDead then
                local chr_ctx = ctx_holder:get_Chara();
                if chr_ctx ~= nil then
                    local health_mgr = chr_ctx:get_HealthManager();
                    if health_mgr ~= nil then
                        monster.isDead = health_mgr:get_Health() <= 0.0;
                    end
                end
            end

            -- Update the current monster action
            local enemyManageInfo = FindEnemyUniqueIndex(Singletons.EnemyManager, monster.uniqueId);
            if enemyManageInfo ~= nil then
                local character = enemyManageInfo:get_Character();
                if character ~= nil then
                    local enemyAction = character:getCurrentAction();
                    if enemyAction ~= nil then
                        local Action = enemyAction:get_type_definition():get_full_name();
                        monster.currentAction = tostring(Action);
                        monster.inCocoon = monster.currentAction:endswith("cWaitCocoon");
                        Utils.logDebug(Monsters.GetEnemyName(monster.emId) .. ": " .. monster.currentAction);
                    end
                end
            end

            if monster.TARGET_ACCESS_KEY ~= nil then
                monster.isQuestTarget = IsQuestTarget(Singletons.MissionManager, monster.TARGET_ACCESS_KEY);
            end
        end
    end
end

-------------------------------------------------------------------

---Registers and caches a new monster from the provided enemy
---@param ctx app.cEnemyContext
---@return table monster The newly created monster table.
function Monsters.NewMonster(ctx)
    -- create a new monster
    local monster = {};
    monster.LastUpdate = os.time();

    -- id
    local id = ctx:get_EmID();
    if id == nil then return {} end;

    monster.emId = id;
    monster.uniqueId = ctx:get_UniqueIndex();

    -- name
    local guid = GetEnemyNameFunc(nil, id);
    local enemyName = GetMsgFunc(nil, guid);
    if enemyName == nil then enemyName = "MISSING" end;

    -- size
    local sizeInfo = Monsters.GetSizeInfoForEnemyType(id);
    if sizeInfo ~= nil then
        local size = ctx:getModelScale_Boss();

        if size ~= nil then
            monster.size = size;

            monster.TARGET_ACCESS_KEY = nil;
            monster.crownType = 0;
            monster.isDead = false;
            monster.area = 0;
            monster.roleId = ctx:get_RoleID();
            monster.legendaryId = ctx:get_LegendaryID();
            monster.isQuestTarget = false;
            monster.inCocoon = false;

            local browser = ctx:get_Browser();
            if browser then
                monster.TARGET_ACCESS_KEY = browser:get_ThisTargetAccessKey();
                monster.crownType = browser:checkCrownType();
                monster.isDead = browser:get_IsHealthZero();
                monster.area = browser:getCurrentAreaNo();
            end

            monster.isNormal = monster.crownType == 0;
            monster.isSmall = monster.crownType == 1;
            monster.isBig = monster.crownType == 2;
            monster.isKing = monster.crownType == 3;
        end

        --[[         Utils.logDebug("Found " .. Monsters.GetEnemyName(monster.emId) .. " in area " .. tostring(monster.area)) ]]
    end

    --[[     Utils.logDebug("registered '" ..
        enemyName .. "' \tSize: '" .. string.format("%.2f", monster.size) .. "' " .. Const.CrownNames[monster.crownType]); ]]

    if Monsters.monsters[ctx] == nil then
        Monsters.monsters[ctx] = monster;
        Monsters.onMonsterAdded(monster);
    end

    return monster;
end

-------------------------------------------------------------------

---Iterates all known monsters and calls the provided function with it and its index.
---@param f function The function to call for each monster f(enemy, index)
function Monsters.IterateMonsters(f)
    local i = 0;
    for _, v in ipairs(Monsters.monsters) do
        f(v, i);
        i = i + 1;
    end
end

-------------------------------------------------------------------

---Get the size info for the enemy type provided.
---Set the update flag to update the cached size info.
---@param EmID EmID|nil
---@return table sizeInfo The cached size info table.
function Monsters.GetSizeInfoForEnemyType(EmID)
    local monsterDef = Monsters.monsterDefinitions[EmID];
    if monsterDef == nil or monsterDef.sizeInfo == nil then
        return {
            baseSize = 0,
            smallBorder = 0,
            bigBorder = 0,
            kingBorder = 0,
            smallCrownObtained = false,
            bigCrownObtained = false,
            kingCrownObtained = false,
            minHuntedSize = 0,
            maxHuntedSize = 0,
            crownNeeded = false,
            crownEnabled = false,
        };
    end

    return monsterDef.sizeInfo;
end

-------------------------------------------------------------------

---Initializes/empties the monster list.
function Monsters.InitList()
    for _, v in pairs(Monsters.monsters) do
        Monsters.onMonsterRemoved(v);
    end
    Monsters.monsters = {};
end

-------------------------------------------------------------------

--- Get the name of the specified monster type
---@param EmID EmID
---@return string
function Monsters.GetEnemyName(EmID)
    -- try to find the name in our cached names
    local monsterDef = Monsters.monsterDefinitions[EmID];
    if monsterDef ~= nil then
        return monsterDef.name;
    end

    local name = "";
    --if EmID and EmID >= 0 then
    local guid = GetEnemyNameFunc(nil, EmID);
    name = GetMsgFunc(nil, guid);
    --end
    return name;
end

----------------------------------------------------------------------

--- Initializes the enemyTypes list and caches enemyType, enemyTypeIndex and name.
function Monsters.InitEnemyTypesList()
    Utils.logDebug("Initializing enemy types");
    local enemyEnum = Utils.GenerateEnumValues("app.EnemyDef.ID");

    -- get all valid emIds
    local int_array_getItem = sdk.find_type_definition("app.EnemyDef.ID[]"):get_method("get_Item");
    local validEms = ValidEmIDs:get_data(Singletons.EnemyManager);
    if validEms == nil then return end;

    local size = validEms:get_size();
    for i = 0, size - 1, 1 do
        local EmID = int_array_getItem(validEms, i);
        if enemyEnum[EmID] ~= nil then
            Monsters.monsterDefinitions[EmID] = {
                emType = EmID,
                emString = enemyEnum[EmID],
                name = Monsters.GetEnemyName(EmID),
                isAnimal = IsAnimalID(nil, EmID),
                isBoss = IsBossID(nil, EmID),
                isFish = IDToIsFish(nil, EmID),
                isZako = IsZakoID(nil, EmID),
            };
            table.insert(Monsters.sortedKeysByName, EmID);
        end
    end

    table.sort(Monsters.sortedKeysByName, function(a, b)
        return Monsters.monsterDefinitions[a].name < Monsters.monsterDefinitions[b].name;
    end)
end

-------------------------------------------------------------------

--- Initializes or updates existing size info for the specified EmID
---@param EmId EmID
function Monsters.InitSizeInfo(EmId)
    Utils.logDebug("InitSizeInfo called");
    local setting = GetSettingMethod(Singletons.EnemyManager);
    if setting == nil then return end;
    Utils.logDebug("setting valid");
    local emParamSize = GetSizeMethod(setting);
    if emParamSize == nil then return end;
    Utils.logDebug("emParamSize valid");

    local monsterDef = Monsters.monsterDefinitions[EmId];
    if monsterDef == nil then return end;
    Utils.logDebug("Initializing size info for emType (" .. monsterDef.name .. "): " .. monsterDef.emString);

    ---@type cSizeData
    local sizeData = GetSizeDataMethod(emParamSize, EmId);
    if sizeData == nil then return end;
    local crownSizeSmall = sizeData:get_CrownSize_Small();
    local crownSizeBig = sizeData:get_CrownSize_Big();
    local crownSizeKing = sizeData:get_CrownSize_King();
    local baseSize = sizeData:get_BaseSize();
    local isDisableRandom = sizeData:get_IsDisableRandom();

    -- get min and max hunted monster size
    local minHuntedSize = ReportUtilMinSize(nil, EmId);
    local maxHuntedSize = ReportUtilMaxSize(nil, EmId);

    if sizeData ~= nil then
        local sizeInfo = {
            baseSize = baseSize,
            smallBorder = crownSizeSmall,
            bigBorder = crownSizeBig,
            kingBorder = crownSizeKing,
            smallCrownObtained = minHuntedSize <= crownSizeSmall,
            bigCrownObtained = maxHuntedSize >= crownSizeBig,
            kingCrownObtained = maxHuntedSize >= crownSizeKing,
            minHuntedSize = minHuntedSize,
            maxHuntedSize = maxHuntedSize,
            crownNeeded = false,
            crownEnabled = not isDisableRandom
        };
        sizeInfo.crownNeeded = not sizeInfo.smallCrownObtained or not sizeInfo.bigCrownObtained or
            not sizeInfo.kingCrownObtained;
        -- set size info on monsterDefinition
        monsterDef.sizeInfo = sizeInfo;
        Utils.logDebug(
            " BaseSize: " .. tostring(sizeInfo.baseSize) ..
            " SmallBorder: " .. tostring(sizeInfo.smallBorder) ..
            " Bigborder: " .. tostring(sizeInfo.bigBorder) ..
            " Kingborder: " .. tostring(sizeInfo.kingBorder) ..
            " Smallcrownobtained: " .. tostring(sizeInfo.smallCrownObtained) ..
            " Bigcrownobtained: " .. tostring(sizeInfo.bigCrownObtained) ..
            " Kingcrownobtained: " .. tostring(sizeInfo.kingCrownObtained) ..
            " Minhuntedsize: " .. tostring(sizeInfo.minHuntedSize) ..
            " Maxhuntedsize: " .. tostring(sizeInfo.maxHuntedSize) ..
            " Crownneeded: " .. tostring(sizeInfo.crownNeeded) ..
            " Crownenabled: " .. tostring(sizeInfo.crownEnabled));
    end
end

-------------------------------------------------------------------

--- Initializes all size infos
function Monsters.InitSizeInfos()
    if #Monsters.monsterDefinitions == 0 then
        Monsters.InitEnemyTypesList();
    end
    for k, _ in pairs(Monsters.monsterDefinitions) do
        Monsters.InitSizeInfo(k);
    end
end

-------------------------------------------------------------------

local pendingUpdateEmId = nil;

function Monsters.OnWriteRecord(emId)
    Utils.logDebug("OnWriteRecord called with " .. tostring(emId));
    Monsters.InitSizeInfo(emId);
end

-------------------------------------------------------------------

-- initializes the module
function Monsters.InitModule()
    -- hook into the enemy update method
    Utils.Hook("app.EnemyCharacter", "doUpdateEnd", function(args)
        pcall(Monsters.doUpdateEndCallback, sdk.to_managed_object(args[2]));
    end);

    Utils.Hook("app.EnemyReportUtil", "setWriteRecord",
        function(args)
            pendingUpdateEmId = sdk.to_int64(args[2]);
        end,
        function(retval)
            if pendingUpdateEmId ~= nil then Monsters.OnWriteRecord(pendingUpdateEmId) end;
            pendingUpdateEmId = nil;
            return retval;
        end);

    Quests.onLocationChanged:add(Monsters.OnLocationChangedCallback);
    -- When the player changes (e.g. loading in the game/changing savegame) then load the size data
    Quests.onPlayerChanged:add(function()
        Utils.logDebug("onPlayerChanged called");
        Monsters.InitSizeInfos();
    end);
    if Quests.HasMasterPlayer() then
        Monsters.InitSizeInfos();
    end
    Utils.logDebug("Monsters Initialized");
end

-------------------------------------------------------------------

return Monsters;
