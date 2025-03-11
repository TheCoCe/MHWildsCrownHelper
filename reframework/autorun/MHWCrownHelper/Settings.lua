local Settings             = {};
local TableHelpers         = require("MHWCrownHelper.table_helpers");
local Event                = require("MHWCrownHelper.Event")
local Const                = require("MHWCrownHelper.Const")

Settings.current           = nil;
Settings.configFileName    = "MHWCrownHelper/Settings.json";
Settings.default           = {};
Settings.onSettingsChanged = Event.New();

-------------------------------------------------------------------

---Initializes the default settings
function Settings.Init()
    Settings.default = {
        sizeDetails = {
            showSizeDetails = true,
            showHunterRecordIcons = true,
            showSizeGraph = false,
            drawSizeInfoForNoCrown = true,
            hideObtained = true,
            showActualSize = true,
            autoHide = false,
            autoHideAfter = 20,

            sizeDetailsOffset = {
                x = 0,
                y = 0,
                spacing = 0,
            }
        },

        notifications = {
            showNotifications = true,
            useLegacyNotifications = false,
            ignoreSilverCrowns = false,
            ignoreObtainedCrowns = false,
            notificionDisplayTime = 5,
            notificationsOffset = {
                x = 0,
                y = 0,
            }
        },

        crownTracker = {
            showCrownTracker = true,
            hideComplete = true,
            showSizeBorders = false,
            showCurrentRecords = false
        },

        text = {
            size = Const.Fonts.SIZES.MEDIUM,
            ntfySize = Const.Fonts.SIZES.MEDIUM
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
