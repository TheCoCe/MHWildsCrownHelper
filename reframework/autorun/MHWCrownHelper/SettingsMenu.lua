local SettingsMenu          = {};

local Settings              = require("MHWCrownHelper.Settings");
local CrownTracker          = require("MHWCrownHelper.CrownTracker");
local Notifications         = require("MHWCrownHelper.Notifications")
local Singletons            = require("MHWCrownHelper.Singletons")
local Monsters              = require("MHWCrownHelper.Monsters")
local Const                 = require("MHWCrownHelper.Const")

SettingsMenu.windowPosition = Vector2f.new(400, 200);
SettingsMenu.windowPivot    = Vector2f.new(0, 0);
SettingsMenu.windowSize     = Vector2f.new(400, 400);
SettingsMenu.windowFlags    = 0x10120;

-------------------------------------------------------------------

---Draws the settings menu in a imgui window
function SettingsMenu.Draw()
    --imgui.set_next_window_pos(SettingsMenu.windowPosition, 1 << 3, SettingsMenu.windowPivot);
    --imgui.set_next_window_size(SettingsMenu.windowSize, 1 << 3);
    --SettingsMenu.isOpened = imgui.begin_window("MHR CrownHelper Settings", SettingsMenu.isOpened, SettingsMenu.windowFlags);

    local settingsChanged = false;
    local changed = false;
    local changedKey = "";

    if imgui.tree_node("Size Details") then
        local sgDrawMode = {
            [Settings.DrawMode.Disabled] = "Disabled",
            [Settings.DrawMode.Simple] = "Simple",
            [Settings.DrawMode.SizeGraph] = "Size Graph"
        }
        changed, Settings.current.sizeDetails.drawMode = imgui.combo("Draw Mode", Settings.current.sizeDetails.drawMode,
            sgDrawMode);
        settingsChanged = settingsChanged or changed;

        changed, Settings.current.sizeDetails.showActualSize = imgui.checkbox(
            "Show monster size",
            Settings.current.sizeDetails.showActualSize);
        settingsChanged = settingsChanged or changed;

        local sgMonstersMode = {
            [Settings.ShowMonstersMode.All] = "All monsters",
            [Settings.ShowMonstersMode.CrownsOnly] =
            "Only crown size monsters",
            [Settings.ShowMonstersMode.HideObtained] = "Unobtained crown size monsters",
            [Settings.ShowMonstersMode.ShowNewRecords] = "Unobtained crown size monsters and new records"
        }
        changed, Settings.current.sizeDetails.showMonsterMode = imgui.combo("Displayed monsters",
            Settings.current.sizeDetails.showMonsterMode, sgMonstersMode);
        settingsChanged = settingsChanged or changed;

        if Settings.current.sizeDetails.showMonsterMode ~= Settings.ShowMonstersMode.All then
            changed, Settings.current.sizeDetails.ignoreSilverCrowns = imgui.checkbox(
                "Ignore silver crowns",
                Settings.current.sizeDetails.ignoreSilverCrowns);
            settingsChanged = settingsChanged or changed;
        end

        imgui.text("A blue paper & quill icon will indicate that the monster is a new record.");
        imgui.new_line();

        local options = {
            [Const.Fonts.SIZES.TINY] = "Tiny",
            [Const.Fonts.SIZES.SMALL] = "Small",
            [Const.Fonts.SIZES.MEDIUM] = "Medium",
            [Const.Fonts.SIZES.LARGE] = "Large",
            [Const.Fonts.SIZES.HUGE] = "Huge"
        }
        changed, Settings.current.text.graphSize = imgui.combo("Graph Size", Settings.current.text.graphSize, options);
        settingsChanged = settingsChanged or changed;

        if imgui.tree_node("Auto Hide") then
            changed, Settings.current.sizeDetails.autoHide = imgui.checkbox(
                "Only show info for duration on update", Settings.current.sizeDetails.autoHide);
            changedKey = "autoHide";
            settingsChanged = settingsChanged or changed;

            changed, Settings.current.sizeDetails.autoHideAfter = imgui.drag_float("Info show duration",
                Settings.current.sizeDetails.autoHideAfter, 0.1, 1, 3600, "%.1f");
            changedKey = "autoHide";
            settingsChanged = settingsChanged or changed;

            imgui.tree_pop();
        end

        if imgui.tree_node("Offset") then
            local SizeDetailsOffset = Vector2f.new(Settings.current.sizeDetails.sizeDetailsOffset.x,
                Settings.current.sizeDetails.sizeDetailsOffset.y);
            changed, SizeDetailsOffset = imgui.drag_float2("Size Details Offset", SizeDetailsOffset, 1, 0, 0, "%.1f");
            if changed then
                Settings.current.sizeDetails.sizeDetailsOffset.x = SizeDetailsOffset.x;
                Settings.current.sizeDetails.sizeDetailsOffset.y = SizeDetailsOffset.y;
            end
            settingsChanged = settingsChanged or changed;

            changed, Settings.current.sizeDetails.sizeDetailsOffset.spacing = imgui.drag_float("Size Details Spacing",
                Settings.current.sizeDetails.sizeDetailsOffset.spacing, 0.1, 0, 0, "%.1f");
            settingsChanged = settingsChanged or changed;
            imgui.tree_pop();
        end

        imgui.tree_pop();
    end

    if imgui.tree_node("Crown notifications") then
        local ntfyTypes = {
            [Settings.NotificationType.Disabled] = "Disabled",
            [Settings.NotificationType.Enabled] = "Enabled",
            [Settings.NotificationType.Legacy] = "Legacy"
        }
        changed, Settings.current.notifications.notificationType = imgui.combo("Notification Type",
            Settings.current.notifications.notificationType, ntfyTypes);
        settingsChanged = settingsChanged or changed;

        if Settings.current.notifications.notificationType == Settings.NotificationType.Legacy then
            if imgui.tree_node("Legacy Notification Settings") then
                local options = {
                    [Const.Fonts.SIZES.TINY] = "Tiny",
                    [Const.Fonts.SIZES.SMALL] = "Small",
                    [Const.Fonts.SIZES.MEDIUM] = "Medium",
                    [Const.Fonts.SIZES.LARGE] = "Large",
                    [Const.Fonts.SIZES.HUGE] = "Huge"
                }
                changed, Settings.current.text.ntfySize = imgui.combo("Notification Size", Settings.current.text
                    .ntfySize,
                    options);
                settingsChanged = settingsChanged or changed;

                changed, Settings.current.notifications.notificionDisplayTime = imgui.drag_float("Display time",
                    Settings.current.notifications.notificionDisplayTime, 0.1, 0, 60, "%.1f");
                settingsChanged = settingsChanged or changed;

                if imgui.tree_node("Offset") then
                    local notificationsOffset = Vector2f.new(Settings.current.notifications.notificationsOffset.x,
                        Settings.current.notifications.notificationsOffset.y);
                    changed, notificationsOffset = imgui.drag_float2("Offset", notificationsOffset, 1, 0, 0, "%.1f");
                    if changed then
                        Settings.current.notifications.notificationsOffset.x = notificationsOffset.x;
                        Settings.current.notifications.notificationsOffset.y = notificationsOffset.y;
                    end
                    settingsChanged = settingsChanged or changed;
                    imgui.tree_pop();
                end
                imgui.tree_pop();
            end
        end

        local ntfyMonstersMode = {
            [Settings.ShowMonstersMode.CrownsOnly] = "Only crown size monsters",
            [Settings.ShowMonstersMode.HideObtained] = "Unobtained crown size monsters",
            [Settings.ShowMonstersMode.ShowNewRecords] = "Unobtained crown size monsters and new records"
        }
        changed, Settings.current.notifications.notificationMode = imgui.combo("Displayed monsters",
            Settings.current.notifications.notificationMode, ntfyMonstersMode);
        settingsChanged = settingsChanged or changed;

        changed, Settings.current.notifications.ignoreSilverCrowns = imgui.checkbox(
            "Ignore silver crowns",
            Settings.current.notifications.ignoreSilverCrowns);
        settingsChanged = settingsChanged or changed;

        if Settings.current.notifications.notificationType ~= Settings.NotificationType.Disabled then
            if imgui.button("Show test notification") then
                Notifications.AddSizeRecordNotification(0, 1, 2, 1000, Const.CrownType.King, "TEST", 10);
            end
        end

        imgui.tree_pop();
    end

    if imgui.tree_node("Crown Tracker") then
        if not CrownTracker.crownTableVisible and Settings.current.crownTracker.showCrownTracker then
            if imgui.button("Open Crown Tracker") then
                CrownTracker.crownTableVisible = true;
            end
        end

        local crownTrackerTypes = {
            [Settings.CrownTrackerMode.Disabled] = "Disabled",
            [Settings.CrownTrackerMode.ShowWithREFUI] = "Show with REFramework UI",
            [Settings.CrownTrackerMode.ShowAlways] = "Always show"
        }
        changed, Settings.current.crownTracker.crownTrackerMode = imgui.combo("Crown Tracker Mode",
            Settings.current.crownTracker.crownTrackerMode, crownTrackerTypes);
        settingsChanged = settingsChanged or changed;

        imgui.new_line();

        changed, Settings.current.crownTracker.hideComplete = imgui.checkbox("Hide completed monsters",
            Settings.current.crownTracker.hideComplete);
        settingsChanged = settingsChanged or changed;

        changed, Settings.current.crownTracker.showCurrentRecords = imgui.checkbox("Show current records",
            Settings.current.crownTracker.showCurrentRecords);
        settingsChanged = settingsChanged or changed;

        changed, Settings.current.crownTracker.showSizeBorders = imgui.checkbox("Show size borders",
            Settings.current.crownTracker.showSizeBorders);
        settingsChanged = settingsChanged or changed;

        changed, Settings.current.crownTracker.ignoreSilverCrowns = imgui.checkbox("Show silver crowns",
            Settings.current.crownTracker.ignoreSilverCrowns);
        settingsChanged = settingsChanged or changed;

        local options = {
            [Const.Fonts.SIZES.TINY] = "Tiny",
            [Const.Fonts.SIZES.SMALL] = "Small",
            [Const.Fonts.SIZES.MEDIUM] = "Medium",
            [Const.Fonts.SIZES.LARGE] = "Large",
            [Const.Fonts.SIZES.HUGE] = "Huge"
        }
        changed, Settings.current.text.trackerSize = imgui.combo("Font Size",
            Settings.current.text.trackerSize, options);
        settingsChanged = settingsChanged or changed;
        imgui.text_colored("Font size changes will only apply after using [Reset scripts]!", 0xFF0000FF);

        imgui.new_line();

        if imgui.button("Reset window position/size") then
            CrownTracker.ResetWindow();
        end

        imgui.tree_pop();
    end

    imgui.tree_pop();
    imgui.new_line();

    --imgui.end_window();

    if settingsChanged then
        Settings.Save();
        Settings.onSettingsChanged(changedKey);
    end
end

-------------------------------------------------------------------

return SettingsMenu;
