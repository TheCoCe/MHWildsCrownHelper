local CrownTracker             = {};
local Settings                 = require("MHWCrownHelper.Settings");
local Monsters                 = require("MHWCrownHelper.Monsters");
local Drawing                  = require("MHWCrownHelper.Drawing");
local Utils                    = require("MHWCrownHelper.Utils");
local Const                    = require("MHWCrownHelper.Const");

CrownTracker.crownTableVisible = true;

local windowPosSizeFlags       = 1 << 2;
local defaultWindowSize        = { -1, 500 };
-- ImGuiTableFlags_Resizable | ImGuiTableFlags_Reorderable | ImGuiTableFlags_BordersInnerH |ImGuiTableFlags_BordersInnerV | ImGuiTableFlags_SizingStretchProp
local tableFlags               = 1 << 7 | 1 << 9 | 1 << 13 | 1 << 8 | 1 << 10;

local resetWindow              = false;

-------------------------------------------------------------------

local function GetDefaultWindowSize()
    return defaultWindowSize;
end

-------------------------------------------------------------------

local function GetDefaultWindowPos()
    local x, y = Drawing.GetWindowSize();
    return { 50, y - 50 - defaultWindowSize[2] };
end

-------------------------------------------------------------------

function CrownTracker.ResetWindow()
    resetWindow = true;
end

-------------------------------------------------------------------

local function GetWindowFlags()
    if resetWindow then
        resetWindow = false;
        return 1 << 0;
    end

    return windowPosSizeFlags;
end

-------------------------------------------------------------------

function CrownTracker.InitModule()
    Utils.InitFontImgui("regular", {
        [Const.Fonts.SIZES.TINY] = 12,
        [Const.Fonts.SIZES.SMALL] = 16,
        [Const.Fonts.SIZES.MEDIUM] = 20,
        [Const.Fonts.SIZES.LARGE] = 24,
        [Const.Fonts.SIZES.HUGE] = 30
    });
    Utils.logDebug("CrownTracker Initialized");
end

-------------------------------------------------------------------

---Draws the crown tracker window
function CrownTracker.DrawCrownTracker()
    local font = Utils.GetFontImgui("regular", Settings.current.text.trackerSize);
    if font ~= nil then
        imgui.push_font(font);
    end

    if Settings.current.crownTracker.crownTrackerMode == Settings.CrownTrackerMode.ShowAlways or
        (Settings.current.crownTracker.crownTrackerMode == Settings.CrownTrackerMode.ShowWithREFUI and reframework:is_drawing_ui()) then
        local flags = GetWindowFlags();
        imgui.set_next_window_size(GetDefaultWindowSize(), flags);
        imgui.set_next_window_pos(GetDefaultWindowPos(), flags);
        if imgui.begin_window("Monster Crown Tracker", CrownTracker.crownTableVisible, 1 << 14 | 1 << 16) then
            CrownTracker.DrawMonsterSizeTable();
            imgui.end_window();
        else
            CrownTracker.crownTableVisible = false;
        end
    end

    if font ~= nil then
        imgui.pop_font();
    end
end

-------------------------------------------------------------------

---Draws the monster size table in an imgui window.
function CrownTracker.DrawMonsterSizeTable()
    local tableSize = 4;
    if Settings.current.crownTracker.showSizeBorders then
        tableSize = tableSize + 3;
    end
    if Settings.current.crownTracker.showCurrentRecords then
        tableSize = tableSize + 2;
    end

    if imgui.begin_table("Monster Crown Tracker", tableSize, tableFlags) then
        imgui.table_setup_column("Monster");
        imgui.table_setup_column("M");
        imgui.table_setup_column("S");
        imgui.table_setup_column("G");

        if Settings.current.crownTracker.showCurrentRecords then
            imgui.table_setup_column("Smallest");
            imgui.table_setup_column("Largest");
        end

        if Settings.current.crownTracker.showSizeBorders then
            imgui.table_setup_column("Max Mini Size");
            imgui.table_setup_column("Min Silver Size");
            imgui.table_setup_column("Min Gold Size");
        end

        imgui.table_headers_row();

        for _, v in pairs(Monsters.monsterDefinitions) do
            if not v.isBoss then goto continue end;
            local sizeDetails = Monsters.GetSizeInfoForEnemyType(v.emType);

            if sizeDetails ~= nil then
                if not sizeDetails.crownEnabled or (Settings.current.crownTracker.hideComplete and sizeDetails.smallCrownObtained and
                        sizeDetails.bigCrownObtained and sizeDetails.kingCrownObtained) then
                    goto continue;
                end

                imgui.table_next_row();
                imgui.table_next_column();
                imgui.text(v.name);

                imgui.table_next_column();
                if sizeDetails.smallCrownObtained then
                    imgui.text("X");
                end

                if not Settings.current.crownTracker.ignoreSilverCrowns then
                    imgui.table_next_column();
                    if sizeDetails.bigCrownObtained then
                        imgui.text("X");
                    end
                end

                imgui.table_next_column();
                if sizeDetails.kingCrownObtained then
                    imgui.text("X");
                end

                if Settings.current.crownTracker.showCurrentRecords then
                    imgui.table_next_column();
                    imgui.text(string.format("%.2f", (sizeDetails.minHuntedSize / 100) * sizeDetails.baseSize));

                    imgui.table_next_column();
                    imgui.text(string.format("%.2f", (sizeDetails.maxHuntedSize / 100) * sizeDetails.baseSize));
                end

                if Settings.current.crownTracker.showSizeBorders then
                    imgui.table_next_column();
                    imgui.text(string.format("%.2f", (sizeDetails.smallBorder / 100) * sizeDetails.baseSize));

                    imgui.table_next_column();
                    imgui.text(string.format("%.2f", (sizeDetails.bigBorder / 100) * sizeDetails.baseSize));

                    imgui.table_next_column();
                    imgui.text(string.format("%.2f", (sizeDetails.kingBorder / 100) * sizeDetails.baseSize));
                end
            end

            ::continue::
        end

        imgui.end_table();
    end

    if font ~= nil then
        imgui.pop_font();
    end
end

return CrownTracker;
