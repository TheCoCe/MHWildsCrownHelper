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

    if Settings.current.sizeDetails.drawMode ~= Settings.DrawMode.Disabled then
        if ShouldDraw then
            SizeGraph.DrawMonsterList();
        end
    end
end

-------------------------------------------------------------------

-- Base offsets
local topOffset = 200 / 1440;
local rightOffset = 10 / 2560;

-- Item spacing
local baseSpacingY = 5 / 1440;

-------------------------------------------------------------------

---Draws the monster list
function SizeGraph.DrawMonsterList()
    if not sizeGraphVisible then return false; end
    local w, h = Drawing.GetWindowSize();

    local posy = topOffset * h + Settings.current.sizeDetails.sizeDetailsOffset.y;
    for monster, widget in pairs(SizeGraphWidgets) do
        -- Skip normal size monsters in crown only modes
        if Settings.current.sizeDetails.showMonsterMode >= Settings.ShowMonstersMode.CrownsOnly and monster.isNormal then goto continue; end;

        local sizeInfo = Monsters.GetSizeInfoForEnemyType(monster.emId);
        if sizeInfo == nil then goto continue; end;

        local isNewRecord = monster.size < sizeInfo.minHuntedSize or monster.size > sizeInfo.maxHuntedSize;

        if Settings.current.sizeDetails.showMonsterMode >= Settings.ShowMonstersMode.HideObtained then
            if (monster.isSmall and sizeInfo.smallCrownObtained) or
                (monster.isBig and sizeInfo.bigCrownObtained) or
                (monster.isKing and sizeInfo.kingCrownObtained) then
                if Settings.current.sizeDetails.showMonsterMode == Settings.ShowMonstersMode.ShowNewRecords then
                    if not isNewRecord then
                        goto continue;
                    end
                else
                    goto continue;
                end
            end
        end

        local headerString = Monsters.GetEnemyName(monster.emId) .. " (" .. tostring(monster.area) .. ")";
        headerString = headerString .. (isNewRecord and " 📙 " or " ");

        posy = widget:draw(headerString, posy, monster.size, sizeInfo.smallBorder, sizeInfo.bigBorder,
            sizeInfo.kingBorder, sizeInfo.baseSize, monster.crownType, isNewRecord);
        posy = posy + baseSpacingY * h + Settings.current.sizeDetails.sizeDetailsOffset.spacing;

        ::continue::
    end
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

function SizeGraphWidget.Draw(s, title, posy, monsterSize, smallBorder, bigBorder, kingBorder,
                              baseSize, crownType, isNewRecord)
    if Settings.current.sizeDetails.drawMode == Settings.DrawMode.Simple then
        return SizeGraph.DrawCollapsed(s, title, posy, crownType, monsterSize, baseSize, isNewRecord);
    else
        return SizeGraph.DrawSizeGraph(s, title, posy, monsterSize, smallBorder, bigBorder, kingBorder, baseSize,
            crownType);
    end
end

-------------------------------------------------------------------

local bgMarginX = 25 / 2560;
local bgMarginY = 5 / 1440;
local titleIconPadding = 2 / 2560;

function SizeGraph.DrawCollapsed(s, title, posy, crownType, monsterSize, baseSize, isNewRecord)
    local w, h = Drawing.GetWindowSize();
    local textWidth, textHeight = Drawing.MeasureText(title);

    local sizeText = "(" .. string.format("%0.2f", (monsterSize / 100 * baseSize)) .. ")";
    local sizeTextWidth, sizeTextHeight = Drawing.MeasureText(sizeText);
    sizeTextWidth = Settings.current.sizeDetails.showActualSize and sizeTextWidth or 0;
    local imageSize = textHeight * 1.75;

    local isCrown = crownType ~= Const.CrownType.None;
    local crownImageWidth = (isCrown and (2 * titleIconPadding * w + imageSize) or 0);

    local newRecordImageWidth = (isNewRecord and ((isCrown and 1 or 2) * titleIconPadding * w + imageSize) or 0);

    local bgSizeX = textWidth + 2 * bgMarginX * w + crownImageWidth + newRecordImageWidth + sizeTextWidth;
    local bgSizeY = textHeight + 2 * bgMarginY * h;
    local bgPosX = (rightOffset * w) + bgSizeX + Settings.current.sizeDetails.sizeDetailsOffset.x;
    local bgPosY = posy + s.AnimData.offset.y;
    bgPosX, bgPosY = Drawing.FromTopRight(bgPosX, bgPosY);

    Drawing.DrawImage(Drawing.imageResources["sgbg"], bgPosX, bgPosY, bgSizeX, bgSizeY, 0, 0, s.AnimData.offset);

    local textPosX = (rightOffset * w) + textWidth + bgMarginX * w + crownImageWidth + newRecordImageWidth +
    sizeTextWidth + Settings.current.sizeDetails.sizeDetailsOffset.x;
    local textPosY = posy + bgMarginY * h;
    textPosX, textPosY = Drawing.FromTopRight(textPosX, textPosY);

    Drawing.DrawText(title, textPosX, textPosY, s.AnimData.textColor, true, 1.5, 1.5, s.AnimData.textShadowColor,
        s.AnimData.offset);

    if isCrown then
        local image = Drawing.imageResources[crownType];
        if image ~= nil then
            Drawing.DrawImage(image, textPosX + textWidth + titleIconPadding * w, textPosY + textHeight * 0.5, imageSize,
                imageSize, 0, 0.5, s.AnimData.offset);
        end
    end
    if isNewRecord then
        local image = Drawing.imageResources["book"];
        if image ~= nil then
            Drawing.DrawImage(image, textPosX + textWidth + (isCrown and 0 or titleIconPadding * w) + crownImageWidth,
                textPosY + textHeight * 0.5, imageSize, imageSize, 0, 0.5, s.AnimData.offset);
        end
    end

    if Settings.current.sizeDetails.showActualSize then
        Drawing.DrawText(sizeText, textPosX + textWidth + crownImageWidth + newRecordImageWidth, textPosY,
            s.AnimData.textColor, true, 1.5, 1.5, s.AnimData.textShadowColor, s.AnimData.offset);
    end

    return posy + bgSizeY;
end

-------------------------------------------------------------------

local baseGraphWidth = 175 / 2560;
local sgTextMarginX = 20 / 2560;
local sgTextMarginY = 5 / 1440;
local sgLineThickness = 3 / 1440;
local sgMarkerRadius = 4 / 1440;

local sgBgMarginY = 20 / 1440;

function SizeGraph.DrawSizeGraph(s, title, posy, monsterSize, smallBorder, bigBorder, kingBorder, baseSize, crownType)
    local w, h = Drawing.GetWindowSize();
    -- draw |---------|-o--|
    local normalizedSize = (monsterSize - smallBorder) / (kingBorder - smallBorder);
    normalizedSize = math.min(math.max(normalizedSize, 0.0), 1.0);

    local normalizedBigSize = (bigBorder - smallBorder) / (kingBorder - smallBorder);
    normalizedBigSize = math.min(math.max(normalizedBigSize, 0.0), 1.0);

    local normalizedNormalSize = (100 - smallBorder) / (kingBorder - smallBorder);
    normalizedNormalSize = math.min(math.max(normalizedNormalSize, 0.0), 1.0);

    local size = string.format("%.2f", (monsterSize / 100) * baseSize);
    local sizeX, sizeY = Drawing.MeasureText(size);

    local mini = string.format("%.2f", (smallBorder / 100) * baseSize);
    local miniX, miniY = Drawing.MeasureText(mini);

    local king = string.format("%.2f", (kingBorder / 100) * baseSize);
    local kingX, kingY = Drawing.MeasureText(king);

    local titleX, titleY = Drawing.MeasureText(title);

    -- General width
    local kingTextPosX = rightOffset * w + bgMarginX * w + kingX;
    local sgKingPosX = kingTextPosX + sgTextMarginX * w;
    local sgMiniPosX = sgKingPosX + baseGraphWidth * w;
    local miniTextPosX = sgMiniPosX + sgTextMarginX * w + miniX;

    -- Title
    local titlePosY = posy + bgMarginY * h;
    local titlePosX = math.max(miniTextPosX, titleX + bgMarginX * w + rightOffset * w);
    titlePosX, titlePosY = Drawing.FromTopRight(titlePosX, titlePosY);

    -- Optional size
    local currentSizePosY = titlePosY + titleY + sgTextMarginY * h;
    local currentSizePosX = sgKingPosX + (sgMiniPosX - sgKingPosX) * (1.0 - normalizedSize) + sizeX * 0.5;
    currentSizePosX, currentSizePosY = Drawing.FromTopRight(currentSizePosX, currentSizePosY);

    -- King size
    local kingTextPosY = Settings.current.sizeDetails.showActualSize and (currentSizePosY + sizeY + sgTextMarginY * h) or
    currentSizePosY;
    kingTextPosX, kingTextPosY = Drawing.FromTopRight(kingTextPosX, kingTextPosY);;

    -- Size graph
    local sgBigPosX = sgKingPosX + (sgMiniPosX - sgKingPosX) * (1.0 - normalizedBigSize);
    local sgPosY = kingTextPosY + kingY * 0.5;
    sgMiniPosX, _ = Drawing.FromTopRight(sgMiniPosX, 0);
    sgKingPosX, _ = Drawing.FromTopRight(sgKingPosX, 0);
    sgBigPosX, _ = Drawing.FromTopRight(sgBigPosX, 0);

    -- Mini size
    miniTextPosX, _ = Drawing.FromTopRight(miniTextPosX, 0);

    -- Background
    local bgSizeX = 2 * bgMarginX * w + kingX + 2 * sgTextMarginX * w + baseGraphWidth * w + miniX;
    local bgSizeY = kingTextPosY - posy + sgBgMarginY * h + kingY;
    local bgPosX = titlePosX - bgMarginX * w;

    -- Draw in correct order
    Drawing.DrawImage(Drawing.imageResources["sgbg"], bgPosX, posy, bgSizeX, bgSizeY, 0, 0, s.AnimData.offset);

    Drawing.DrawText(title, titlePosX, titlePosY, s.AnimData.textColor, true, 1.5, 1.5, s.AnimData.textShadowColor,
        s.AnimData.offset);
    if Settings.current.sizeDetails.showActualSize then
        Drawing.DrawText(size, currentSizePosX, currentSizePosY, s.AnimData.textColor, true, 1.5, 1.5,
            s.AnimData.textShadowColor, s.AnimData.offset);
    end
    Drawing.DrawText(king, kingTextPosX, kingTextPosY, s.AnimData.textColor, true, 1.5, 1.5, s.AnimData.textShadowColor,
        s.AnimData.offset);

    Drawing.DrawRect(sgMiniPosX, sgPosY, sgKingPosX - sgMiniPosX, sgLineThickness * h, s.AnimData.graphColor, 0, 0.5,
        s.AnimData.offset);
    Drawing.DrawCircle(sgMiniPosX, sgPosY, sgMarkerRadius * h, s.AnimData.graphColor, s.AnimData.offset);
    Drawing.DrawCircle(sgKingPosX, sgPosY, sgMarkerRadius * h, s.AnimData.graphColor, s.AnimData.offset);
    Drawing.DrawCircle(sgBigPosX, sgPosY, sgMarkerRadius * h, s.AnimData.graphColor, s.AnimData.offset);

    local image = Drawing.imageResources["small_gs"];
    if image ~= nil then
        Drawing.DrawImage(image, sgMiniPosX, sgPosY, s.AnimData.iconSize * 0.75, s.AnimData.iconSize * 0.75, 0.5, -0.1,
            s.AnimData.offset);
    end

    image = Drawing.imageResources["big_gs"];
    if image ~= nil then
        Drawing.DrawImage(image, sgBigPosX, sgPosY, s.AnimData.iconSize * 0.75, s.AnimData.iconSize * 0.75, 0.5, -0.1,
            s.AnimData.offset);
    end

    image = Drawing.imageResources["king_gs"];
    if image ~= nil then
        Drawing.DrawImage(image, sgKingPosX, sgPosY, s.AnimData.iconSize * 0.75, s.AnimData.iconSize * 0.75, 0.5, -0.1,
            s.AnimData.offset);
    end

    Drawing.DrawText(mini, miniTextPosX, kingTextPosY, s.AnimData.textColor, true, 1.5, 1.5, s.AnimData.textShadowColor,
        s.AnimData.offset);

    image = Drawing.imageResources[crownType];
    if image ~= nil then
        Drawing.DrawImage(image, sgMiniPosX + (sgKingPosX - sgMiniPosX) * normalizedSize, sgPosY, s.AnimData.iconSize,
            s.AnimData.iconSize, 0.5, 0.6, s.AnimData.offset);
    end

    return posy + (kingTextPosY - posy + sgBgMarginY * h + kingY);
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
