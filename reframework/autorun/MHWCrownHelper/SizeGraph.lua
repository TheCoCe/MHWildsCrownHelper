local SizeGraph          = {};
local SizeGraphWidget    = {};

local Animation          = require("MHWCrownHelper.Animation");
local Utils              = require("MHWCrownHelper.Utils")
local Drawing            = require("MHWCrownHelper.Drawing")
local Monsters           = require("MHWCrownHelper.Monsters");
local Settings           = require("MHWCrownHelper.Settings");
local Quests             = require("MHWCrownHelper.Quests");
local Singletons         = require("MHWCrownHelper.Singletons")
local Const              = require("MHWCrownHelper.Const")

-------------------------------------------------------------------

local guiVisible         = sdk.find_type_definition("app.GUIManager"):get_method("isOpenFullScreenUI()");

-------------------------------------------------------------------

local sizeGraphVisible   = false;
local sizeGraphAnimating = false;

local SizeGraphWidgets   = {};
local MonstersToAdd      = {};
local MonstersToRemove   = {};

-------------------------------------------------------------------

function SizeGraph.OnLocationChangedCallback()
    -- TODO: Figure out if something needs to update here (monsters should be removed automatically)
end

-------------------------------------------------------------------

---Opens the size graph
function SizeGraph.SizeGraphOpen()
    sizeGraphVisible = true;
    sizeGraphAnimating = true;
    Utils.logDebug("sizeGraphOpening");

    local tempList = {};
    for m, _ in pairs(SizeGraphWidgets) do
        tempList[#tempList + 1] = m;
    end

    local i = 1;
    local showNextItem = function(f)
        if i <= #tempList then
            local Widget = SizeGraphWidgets[tempList[i]];

            --Utils.logDebug("Animating monster widget: " .. Monsters.GetEnemyName(tempList[i].emId));
            if not Widget.AnimData.visible then
                --Utils.logDebug("widget:show ");
                Widget:show(0.5);
            end

            Animation.Delay(0.1, function()
                i = i + 1;
                f(f);
            end);
        else
            sizeGraphAnimating = false;
        end
    end

    showNextItem(showNextItem);

    if (Settings.current.sizeDetails.autoHide) then
        Animation.Delay(Settings.current.sizeDetails.autoHideAfter, function()
            SizeGraph.SizeGraphClose();
        end)
    end
end

-------------------------------------------------------------------

---Closes the size graph
function SizeGraph.SizeGraphClose()
    local tempList = {};
    for m, _ in pairs(SizeGraphWidgets) do
        tempList[#tempList + 1] = m;
    end

    local i = #tempList;

    local hideNextItem = function(f)
        if i >= 1 then
            local Widget = SizeGraphWidgets[tempList[i]];
            if Widget.AnimData.visible then
                Widget:hide();
            end
            Animation.Delay(0.1, function()
                i = i - 1;
                f(f);
            end)
        else
            sizeGraphVisible = false;
            sizeGraphAnimating = false;
        end
    end

    hideNextItem(hideNextItem);
end

-------------------------------------------------------------------

---Update loop
---@param deltaTime number
function SizeGraph.Update(deltaTime)
    -- TODO: Proper GUI visibility like in rise
    local ShouldDraw = not guiVisible(Singletons.GUIManager);

    if #MonstersToRemove > 0 then
        Utils.logDebug("Monsters to remove > 0");
        if sizeGraphVisible then
            Utils.logDebug("Size graph visible");
            if not sizeGraphAnimating then
                Utils.logDebug("Size graph not animating");

                local monster = MonstersToRemove[1];
                local widget = SizeGraphWidgets[monster];
                if widget ~= nil then
                    Utils.logDebug("Hiding " .. Monsters.GetEnemyName(monster.emId) .. " widget");
                    widget:hide(0.5, function()
                        SizeGraphWidgets[monster] = nil;
                    end);
                    table.remove(MonstersToRemove, 1);
                end
            end
        else
            Utils.logDebug("Size graph not visible");
            -- remove
            for j = #MonstersToRemove, 1, -1 do
                local monster = MonstersToRemove[j];
                Utils.logDebug("Removing " .. Monsters.GetEnemyName(monster.emId) .. " widget");
                SizeGraphWidgets[monster] = nil;
                table.remove(MonstersToRemove, j);
            end
            MonstersToRemove = {};
        end
    end

    -- add/remove new monsters to size graph
    if ShouldDraw then
        if #MonstersToAdd > 0 then
            Utils.logDebug("Monsters to add > 0");
            if sizeGraphVisible then
                Utils.logDebug("sizeGraphVisible == true");
                if not sizeGraphAnimating then
                    Utils.logDebug("not sizeGraphAnimating");
                    local monster = MonstersToAdd[1];
                    Utils.logDebug("Adding  " .. Monsters.GetEnemyName(monster.emId) .. " widget");
                    SizeGraphWidgets[monster] = SizeGraphWidget.New();
                    SizeGraphWidgets[monster]:show(0.5);
                    table.remove(MonstersToAdd, 1);
                end
            else
                Utils.logDebug("sizeGraphVisible == false");
                for i = #MonstersToAdd, 1, -1 do
                    local monster = MonstersToAdd[i];
                    Utils.logDebug("Adding  " .. Monsters.GetEnemyName(monster.emId) .. " widget");
                    SizeGraphWidgets[monster] = SizeGraphWidget.New();
                    table.remove(MonstersToAdd, i);
                end
                Utils.logDebug("Open the size graph");
                SizeGraph.SizeGraphOpen();
            end
        end
    end

    if Settings.current.sizeDetails.showSizeDetails then
        if ShouldDraw then
            local index = 0;
            for m, _ in pairs(SizeGraphWidgets) do
                if SizeGraph.DrawMonsterDetails(m, index) then
                    index = index + 1;
                end
            end
        end
    end
end

-------------------------------------------------------------------

local baseCtPadRight = 0.01302084;  --  25
local baseCtPadTop = 0.0243056;     --  35
local baseCtItemWidth = 0.0449;     -- 115
local baseCtPadItem = 0.006;        --  18
local baseCtPadItemBot = 0.0104167; --  15
local baseCtInfoHeight = 0.029167;  --  42

-------------------------------------------------------------------

local detailInfoSizeGraph = 100;
local bgMarginX = 20;
local bgMarginY = 10;
local bgMarginYComp = 2;
local baseSpacingY = 5;

---Draws the monster details for a specific monster
---@param monster table The monster table
---@param index integer The index used for positioning of the graph
function SizeGraph.DrawMonsterDetails(monster, index)
    if not sizeGraphVisible then return false; end
    -- In compact mode don't draw monsters that do not have a crown size
    if not Settings.current.sizeDetails.drawSizeInfoForNoCrown and monster.isNormal then return false; end;
    -- Check if we should draw size graph for non crown monsters
    if Settings.current.sizeDetails.showSizeGraph and not Settings.current.sizeDetails.drawSizeInfoForNoCrown and monster.isNormal then return false; end;

    local sizeInfo = Monsters.GetSizeInfoForEnemyType(monster.emId);
    if Settings.current.sizeDetails.hideObtained and not sizeInfo.crownNeeded then return false; end;

    if Settings.current.sizeDetails.hideObtained and (
            (monster.isSmall and sizeInfo.smallCrownObtained) or -- missing the small crown
            (monster.isBig and sizeInfo.bigCrownObtained) or     -- missing the big crown
            (monster.isKing and sizeInfo.kingCrownObtained)      -- missing the king crown
        ) then
        return false;
    end

    local headerString = Monsters.GetEnemyName(monster.emId) .. " (" .. tostring(monster.area) .. "): ";
    local crownString = Const.CrownNames[monster.crownType];
    if (sizeInfo and sizeInfo.crownNeeded) and Settings.current.sizeDetails.showHunterRecordIcons and monster.crownType ~= 0 then
        headerString = headerString .. crownString .. " 📙 ";
    else
        headerString = headerString .. crownString .. " ";
    end

    local sizeInfo = Monsters.GetSizeInfoForEnemyType(monster.emId);
    if sizeInfo == nil then return end;

    if not Settings.current.sizeDetails.showSizeGraph and Settings.current.sizeDetails.showActualSize then
        headerString = headerString .. "(" .. string.format("%0.2f", (monster.size / 100 * sizeInfo.baseSize)) .. ")";
    end

    local w, h = Drawing.GetWindowSize();
    local widget = SizeGraphWidgets[monster];
    if Settings.current.sizeDetails.showSizeGraph then
        local posx = (baseCtPadRight * w) + 3 * (baseCtItemWidth * w) + 2 * (baseCtPadItem * w);

        local detailsHeight = detailInfoSizeGraph;

        local posy = (baseCtPadTop * h) + 2 * (baseCtPadItemBot * h) + (baseCtInfoHeight * h) +
            (detailsHeight * index) + ((baseSpacingY + Settings.current.sizeDetails.sizeDetailsOffset.spacing) * index);

        posx, posy = Drawing.FromTopRight(posx, posy);
        posx = posx + Settings.current.sizeDetails.sizeDetailsOffset.x + widget.AnimData.offset.x;
        posy = posy + Settings.current.sizeDetails.sizeDetailsOffset.y + widget.AnimData.offset.y;

        local sizeGraphWidth = ((3 * baseCtItemWidth * w) + (2 * baseCtPadItem * w));

        Drawing.DrawImage(Drawing.imageResources["sgbg"], posx - bgMarginX, posy - bgMarginY,
            sizeGraphWidth + 2 * bgMarginX
            , detailsHeight - bgMarginY, 0, 0);

        -- Draw the following:
        -- Monster name
        --                    114
        -- 90 ├────────────┼──♛───┤ 123

        Drawing.DrawText(headerString, posx, posy, widget.AnimData.textColor, true, 1.5, 1.5,
            widget.AnimData.textShadowColor);

        if Settings.current.sizeDetails.showSizeGraph then
            if sizeInfo ~= nil then
                local _, height = Drawing.MeasureText(headerString);
                posy = posy + height * 1.5;
                widget:draw(posx, posy, sizeGraphWidth, 15, 2,
                    monster.size, sizeInfo.smallBorder, sizeInfo.bigBorder, sizeInfo.kingBorder, sizeInfo.baseSize);
            end
        end
    else
        local width, height = Drawing.MeasureText(headerString);
        local posx = (baseCtPadRight * w) + width;
        -- TODO: use measured height instead and pass y start point to the next draw
        local detailsHeight = 20; --height;
        local posy = (baseCtPadTop * h) + 2 * (baseCtPadItemBot * h) + (baseCtInfoHeight * h) +
            (detailsHeight * index) + ((baseSpacingY + Settings.current.sizeDetails.sizeDetailsOffset.spacing) * index);
        posx, posy = Drawing.FromTopRight(posx, posy);
        posx = posx + Settings.current.sizeDetails.sizeDetailsOffset.x + widget.AnimData.offset.x;
        posy = posy + Settings.current.sizeDetails.sizeDetailsOffset.y + widget.AnimData.offset.y;

        Drawing.DrawImage(Drawing.imageResources["sgbg"], posx - bgMarginX, posy - bgMarginYComp,
            width + 2 * bgMarginX
            , detailsHeight + 2 * bgMarginYComp, 0, 0);
        Drawing.DrawText(headerString, posx, posy, widget.AnimData.textColor, true, 1.5, 1.5,
            widget.AnimData.textShadowColor);
    end

    return true;
end

-------------------------------------------------------------------
-- Size Graph Widget
-------------------------------------------------------------------

---Shows the size graph via an animation
---@param s table
---@param showTime number
---@param callback function
function SizeGraphWidget.ShowAnim(s, showTime, callback)
    s.AnimData.visible = true;
    showTime = showTime or 0.25;

    Animation.AnimLerp(0, 1, showTime, function(v)
        local col1 = Animation.LerpColor(0x00FFFFFF, 0xFFFFFFFF, v);
        local col2 = Animation.LerpColor(0x003f3f3f, 0xFF3f3f3f, v);
        s.AnimData.textColor = col1;
        s.AnimData.textShadowColor = col2;
        s.AnimData.graphColor = col1;
        s.AnimData.iconSize = 32 * v;
    end)

    Animation.AnimLerpV2(500, 0, 0, 0, showTime, function(x, y)
        s.AnimData.offset.x = x;
        s.AnimData.offset.y = y;
    end, "easeInQuad");

    Animation.Delay(showTime, callback);
end

-------------------------------------------------------------------

---Hides the size graph via an animation
---@param s table
---@param hideTime number
---@param callback function
function SizeGraphWidget.HideAnim(s, hideTime, callback)
    hideTime = hideTime or 0.25;

    Animation.AnimLerp(0, 1, hideTime, function(v)
        local col1 = Animation.LerpColor(0xFFFFFFFF, 0x00FFFFFF, v);
        local col2 = Animation.LerpColor(0xFF3f3f3f, 0x003f3f3f, v);
        s.AnimData.textColor = col1;
        s.AnimData.textShadowColor = col2;
        s.AnimData.graphColor = col1;
        s.AnimData.iconSize = 32 * (1 - v);
    end)

    Animation.AnimLerpV2(0, 0, 500, 0, hideTime, function(x, y)
        s.AnimData.offset.x = x;
        s.AnimData.offset.y = y;
    end, "easeOutQuad");

    Animation.Delay(hideTime, function()
        s.AnimData.visible = false;
        callback();
    end);
end

-------------------------------------------------------------------

function SizeGraphWidget.Draw(s, posx, posy, sizex, sizey, lineWidth, monsterSize, smallBorder, bigBorder, kingBorder,
                              baseSize)
    -- draw |---------|-o--|

    local normalizedSize = (monsterSize - smallBorder) / (kingBorder - smallBorder);
    normalizedSize = math.min(math.max(normalizedSize, 0.0), 1.0);

    local normalizedBigSize = (bigBorder - smallBorder) / (kingBorder - smallBorder);
    normalizedBigSize = math.min(math.max(normalizedBigSize, 0.0), 1.0);

    local normalizedNormalSize = (100 - smallBorder) / (kingBorder - smallBorder);
    normalizedNormalSize = math.min(math.max(normalizedNormalSize, 0.0), 1.0);

    local sizeString = string.format("%.2f", (monsterSize / 100) * baseSize);
    local sizeWidth, sizeHeight = Drawing.MeasureText(sizeString);

    local minString = string.format("%.2f", (smallBorder / 100) * baseSize);
    local minWidth, minHeight = Drawing.MeasureText(minString);

    local maxString = string.format("%.2f", (kingBorder / 100) * baseSize);
    local maxWidth, _ = Drawing.MeasureText(maxString);

    local textPadMult = 1.5;
    local heightPadMult = 1.5;

    local scaledSizex = sizex - (minWidth * textPadMult + maxWidth * textPadMult);

    -- Draw:        100             Size
    if Settings.current.sizeDetails.showActualSize then
        Drawing.DrawText(sizeString, posx + minWidth * textPadMult + scaledSizex * normalizedSize - 0.5 * sizeWidth, posy,
            s.AnimData.textColor);
    end
    -- Draw: 90                     MiniCrown
    Drawing.DrawText(minString, posx, posy + heightPadMult * sizeHeight, s.AnimData.textColor);
    -- Draw: 90            123      KingCrown
    Drawing.DrawText(maxString, posx + sizex - maxWidth, posy + heightPadMult * sizeHeight, s.AnimData.textColor);

    local lineHeight = posy + heightPadMult * sizeHeight + 0.5 * minHeight;
    -- Draw: 90 ----------- 123     Line
    Drawing.DrawRect(posx + minWidth * textPadMult, lineHeight, scaledSizex, lineWidth, s.AnimData.graphColor, 0, 0.5);
    -- Draw: 90 |---------- 123     Mini Border
    Drawing.DrawRect(posx + minWidth * textPadMult, lineHeight, lineWidth, sizey, s.AnimData.graphColor, 0.5, 0.5);
    -- Draw: 90 |---------| 123     King Border
    Drawing.DrawRect(posx + minWidth * textPadMult + scaledSizex, lineHeight, lineWidth, sizey, s.AnimData.graphColor,
        0.5, 0.5);
    -- Draw: 90 |------|--| 123     Big Border
    Drawing.DrawRect(posx + minWidth * textPadMult + scaledSizex * normalizedBigSize, lineHeight, lineWidth, sizey,
        s.AnimData.graphColor, 0.5, 0.5);
    -- Draw: 90 |---o--|--| 123     Normal Size
    Drawing.DrawCircle(posx + minWidth * textPadMult + scaledSizex * normalizedNormalSize, lineHeight, 3,
        s.AnimData.graphColor);

    -- draw crown image
    if d2d ~= nil then
        local image = nil;

        if normalizedSize >= normalizedBigSize or normalizedSize == 0 then
            if normalizedSize == 1 then
                image = Drawing.imageResources["kingCrown"];
            elseif normalizedSize >= normalizedBigSize then
                image = Drawing.imageResources["bigCrown"];
            else
                image = Drawing.imageResources["miniCrown"];
            end
        else
            image = Drawing.imageResources["monster"];
        end

        Drawing.DrawImage(image, posx + minWidth * textPadMult + scaledSizex * normalizedSize, lineHeight,
            s.AnimData.iconSize, s.AnimData.iconSize, 0.5, 0.7);
    else
        draw.filled_circle(posx + minWidth * textPadMult + scaledSizex * normalizedSize, lineHeight,
            s.AnimData.iconSize * 0.5, s.AnimData.graphColor, 16);
    end
end

-------------------------------------------------------------------

---Creates a new size graph
---@return table SizeGraph The newly created size graph
function SizeGraphWidget.New()
    local table = {
        AnimData = {
            textColor = 0x00FFFFFF,
            textShadowColor = 0x003f3f3f,
            graphColor = 0x00FFFFFF,
            offset = { x = 500, y = 0 },
            iconSize = 0,
            visible = false,
        },
        show = SizeGraphWidget.ShowAnim,
        hide = SizeGraphWidget.HideAnim,
        draw = SizeGraphWidget.Draw
    };

    return table;
end

-------------------------------------------------------------------
-- Init
-------------------------------------------------------------------

---Initializes the SizeGraph module
function SizeGraph.InitModule()
    Quests.onLocationChanged:add(SizeGraph.OnLocationChangedCallback);

    -- bind monster add event
    Monsters.onMonsterAdded:add(
        function(monster)
            MonstersToAdd[#MonstersToAdd + 1] = monster;
            Utils.logDebug("onMonsterAdded: " .. Monsters.GetEnemyName(monster.emId));
        end);

    -- bind monster remove event
    Monsters.onMonsterRemoved:add(
        function(monster)
            MonstersToRemove[#MonstersToRemove + 1] = monster;
            Utils.logDebug("onMonsterRemoved: " .. Monsters.GetEnemyName(monster.emId));
        end);

    Settings.onSettingsChanged:add(function()
        SizeGraph.SizeGraphOpen();
    end)
end

return SizeGraph;
