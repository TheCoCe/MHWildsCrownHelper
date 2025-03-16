local Settings             = {};
local TableHelpers         = require("MHWCrownHelper.table_helpers");
local Event                = require("MHWCrownHelper.Event")
local Const                = require("MHWCrownHelper.Const")

Settings.current           = nil;
Settings.configFileName    = "MHWCrownHelper/Settings.json";
Settings.default           = {};
Settings.onSettingsChanged = Event.New();

-------------------------------------------------------------------

Settings.DrawMode          = {
    Disabled = 0,
    Simple = 1,
    SizeGraph = 2
};

Settings.ShowMonstersMode  = {
    All = 0,
    CrownsOnly = 1,
    HideObtained = 2,
    ShowNewRecords = 3
};

Settings.NotificationType  = {
    Disabled = 0,
    Enabled = 1,
    Legacy = 2
}

Settings.CrownTrackerMode  = {
    Disabled = 0,
    ShowWithREFUI = 1,
    ShowAlways = 2,
}

-------------------------------------------------------------------

---Initializes the default settings
function Settings.Init()
    Settings.default = {
        sizeDetails = {
            drawMode = Settings.DrawMode.Simple,
            showActualSize = true,
            showMonsterMode = Settings.ShowMonstersMode.CrownsOnly,
            ignoreSilverCrowns = false,

            autoHide = false,
            autoHideAfter = 20,

            sizeDetailsOffset = {
                x = 0,
                y = 0,
                spacing = 0,
            },
        },

        notifications = {
            notificationType = Settings.NotificationType.Enabled,
            notificationMode = Settings.ShowMonstersMode.CrownsOnly,
            ignoreSilverCrowns = false,
            notificionDisplayTime = 5,
            notificationsOffset = {
                x = 0,
                y = 0,
            },
        },

        crownTracker = {
            showCrownTracker = true,
            hideComplete = true,
            showSizeBorders = false,
            showCurrentRecords = false,
            crownTrackerMode = Settings.CrownTrackerMode.ShowWithREFUI,
        },

        text = {
            graphSize = Const.Fonts.SIZES.MEDIUM,
            ntfySize = Const.Fonts.SIZES.MEDIUM,
            trackerSize = Const.Fonts.SIZES.MEDIUM,
        }
    };
end

-------------------------------------------------------------------

---Loads the settings file
function Settings.Load()
    local loadedConfig = json.load_file(Settings.configFileName);
    if loadedConfig ~= nil then
        Settings.current = TableHelpers.merge(Settings.default, loadedConfig);
    else
        Settings.current = TableHelpers.deep_copy(Settings.default, nil);
    end
end

-------------------------------------------------------------------

---Saves the settings file
function Settings.Save()
    local success = json.dump_file(Settings.configFileName, Settings.current);
    if success then
        log.info("[MHW CrownHelper] Settings saved successfully");
    else
        log.error("[MHW CrownHelper] Failed to save settings");
    end
end

-------------------------------------------------------------------

--Resets the settings to default
function Settings.ResetToDefault()
    Settings.current = Settings.default;
    Settings.Save();
end

-------------------------------------------------------------------

function Settings.InitModule()
    Settings.Init();
    Settings.Load();
end

-------------------------------------------------------------------

return Settings;
