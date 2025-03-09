local Monsters                   = {};
local Singletons                 = require("MHWCrownHelper.Singletons");
local Quests                     = require("MHWCrownHelper.Quests");
local Utils                      = require("MHWCrownHelper.Utils");
local table_helpers              = require("MHWCrownHelper.table_helpers")
local Event                      = require("MHWCrownHelper.Event")
local Notifications              = require("MHWCrownHelper.Notifications")
local Drawing                    = require("MHWCrownHelper.Drawing")
local Settings                   = require("MHWCrownHelper.Settings")
local Const                      = require("MHWCrownHelper.Const")

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
function Monsters.UpdateMonster(enemy)
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

    if monster ~= nil then
        if monster.NextUpdate - time <= 0 then
            monster.LastUpdate = time;
            monster.NextUpdate = time + Monsters.UpdateInterval;

            local previousIsDead = monster.isDead;
            local browser = ctx:get_Browser()
            if browser then
                monster.isDead = browser:get_IsHealthZero();
                monster.area = browser:getCurrentAreaNo();
            end
            -- check if death state changend and update the size info if it did
            if previousIsDead ~= monster.isDead then
                Monsters.InitSizeInfo(monster.emId);
            end
        end
    else
        local monster = Monsters.NewMonster(ctx);
        monster.NextUpdate = time + Monsters.UpdateInterval;
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

            local crownType = 0;
            local isDead = false;
            local area = 0;
            local browser = ctx:get_Browser();
            if browser then
                crownType = browser:checkCrownType();
                isDead = browser:get_IsHealthZero();
                area = browser:getCurrentAreaNo();
            end
            monster.crownType = crownType;
            monster.isNormal = crownType == 0;
            monster.isSmall = crownType == 1;
            monster.isBig = crownType == 2;
            monster.isKing = crownType == 3;
            monster.isDead = isDead;
            monster.area = area;
        end

        if (monster.isSmall or (monster.isBig and not Settings.current.notifications.ignoreSilverCrowns) or monster.isKing) and
            (sizeInfo.crownNeeded or not Settings.current.notifications.ignoreObtainedCrowns) and not monster.isDead then
            Notifications.AddSizeRecordNotification(monster.emId, ctx:get_RoleID(), ctx:get_LegendaryID(),
                math.floor(monster.size * sizeInfo.baseSize),
                monster.crownType,
                Monsters.GetEnemyName(monster.emId), monster.area);
        end

        Utils.logDebug("Found " .. Monsters.GetEnemyName(monster.emId) .. " in area " .. tostring(monster.area))
    end

    local sizeString = (monster.isSmall and "[small]" or (monster.isKing and "[king]" or (monster.isBig and "[big]" or "")));
    Utils.logDebug("registered '" ..
        enemyName .. "' \tSize: '" .. string.format("%.2f", monster.size) .. "' " .. sizeString);

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
    --[[ for i = 1, #orderedMapMonsters, 1 do
        f(orderedMapMonsters[i], i - 1);
    end ]]
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
        end
    end
end

-------------------------------------------------------------------

--- Initializes or updates existing size info for the specified EmID
---@param EmId EmID
function Monsters.InitSizeInfo(EmId)
    local setting = GetSettingMethod(Singletons.EnemyManager);
    if setting == nil then return end;
    local emParamSize = GetSizeMethod(setting);
    if emParamSize == nil then return end;

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
    for k, v in pairs(Monsters.monsterDefinitions) do
        Monsters.InitSizeInfo(k);
    end
end

-------------------------------------------------------------------

-- initializes the module
function Monsters.InitModule()
    -- hook into the enemy update method
    Utils.Hook("app.EnemyCharacter", "doUpdateEnd", function(args)
        pcall(Monsters.UpdateMonster, sdk.to_managed_object(args[2]));
    end);

    Monsters.InitEnemyTypesList();
    Monsters.InitSizeInfos();
    Quests.onLocationChanged:add(Monsters.OnLocationChangedCallback);
end

-------------------------------------------------------------------

return Monsters;
