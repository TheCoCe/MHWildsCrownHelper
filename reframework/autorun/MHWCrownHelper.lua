local CrownHelper        = {};
local Singletons         = require("MHWCrownHelper.Singletons");
local Quests             = require("MHWCrownHelper.Quests");
local Monsters           = require("MHWCrownHelper.Monsters");
local Drawing            = require("MHWCrownHelper.Drawing");
local Time               = require("MHWCrownHelper.Time");
local Settings           = require("MHWCrownHelper.Settings");
local SettingsMenu       = require("MHWCrownHelper.SettingsMenu");
local NativeSettingsMenu = require("MHWCrownHelper.NativeSettingsMenu");
local Utils              = require("MHWCrownHelper.Utils");
local CrownTracker       = require("MHWCrownHelper.CrownTracker");
local SizeGraph          = require("MHWCrownHelper.SizeGraph");
local Notifications      = require("MHWCrownHelper.Notifications");

local IsPlayableScene    = sdk.find_type_definition("app.GameFlowManager"):get_method("get_IsPlayableScene()");

Settings.InitModule();
NativeSettingsMenu.InitModule();
CrownHelper.isInitialized = false;

-------------------------------------------------------------------

function CrownHelper.HandleInit()
    -- Init all singletons
    if not Singletons.isInitialized then
        if Singletons.Init() then
            -- Init modules that require all singletons to be set up
            Quests.InitModule();
        end
    else
        -- Init modules that require ingame
        Monsters.InitModule();
        SizeGraph.InitModule();
        CrownTracker.InitModule();
        Notifications.InitModule();
        CrownHelper.isInitialized = true;
        Utils.logInfo("All modules initialized");
    end
end

-------------------------------------------------------------------

function CrownHelper.OnFrame()
    -- frame time currently unused -> no need to tick
    Time.Tick();

    -- init
    if not CrownHelper.isInitialized then
        CrownHelper.HandleInit();
        -- player ingame
    else
        if not IsPlayableScene(Singletons.GameFlowManager) then
            return;
        end

        CrownTracker.DrawCrownTracker();
        Monsters.Update(Time.timeDelta);
    end
end

-------------------------------------------------------------------

function CrownHelper.DrawD2D()
    if not IsPlayableScene(Singletons.GameFlowManager) then
        return;
    end

    Time.D2DTick();
    SizeGraph.Update(Time.timeDeltaD2D);
    Drawing.Update(Time.timeDeltaD2D);

    Notifications.Update();
end

-------------------------------------------------------------------

function CrownHelper.InitD2D()
    -- register fonts and stuff here
    Drawing.InitModule();
end

-------------------------------------------------------------------

-- init stuff

re.on_draw_ui(function()
    if imgui.collapsing_header("MHW Crown Helper") then
        pcall(SettingsMenu.Draw);
    end
end)

-------------------------------------------------------------------

function CrownHelper.CheckModuleAvailability()
    if Utils.IsModuleAvailable("coroutine") and d2d then
        if not Utils.IsModuleAvailable("ModOptionsMenu.ModMenuApi") then
            Utils.logInfo("Mod Options Menu not found. Using default Settings menu.");
        end

        return true;
    end

    Utils.logError(
        "REFramework outdated or REFramework Direct2D missing! Please make sure to download the latest versions for the mod to work!");
    return false;
end

-------------------------------------------------------------------

if CrownHelper.CheckModuleAvailability() then
    -- init d2d
    d2d.register(CrownHelper.InitD2D, CrownHelper.DrawD2D);
    Utils.logDebug("Init d2d");

    -- init update loop
    re.on_frame(CrownHelper.OnFrame);
end

-------------------------------------------------------------------

return CrownHelper;
