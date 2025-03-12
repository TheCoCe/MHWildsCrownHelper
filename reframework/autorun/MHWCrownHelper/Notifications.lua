local Notifications       = {};
local NotificationWidget  = {};

local Animation           = require("MHWCrownHelper.Animation");
local Drawing             = require("MHWCrownHelper.Drawing");
local Utils               = require("MHWCrownHelper.Utils");
local Settings            = require("MHWCrownHelper.Settings");
local Singletons          = require("MHWCrownHelper.Singletons");
local Const               = require("MHWCrownHelper.Const");
local Monsters            = require("MHWCrownHelper.Monsters");

local firstUpdate         = true;
local NotificationQueue   = {};
local CurrentNotification = nil;

-------------------------------------------------------------------

function OnMonsterAdded(monster)
    if Settings.current.notifications.notificationType == Settings.NotificationType.Disabled then return; end;
    if monster == nil then return; end;
    if monster.isNormal or monster.isDead then return; end;
    local sizeInfo = Monsters.GetSizeInfoForEnemyType(monster.emId);
    if sizeInfo == nil then return; end;
    local isNewRecord = monster.size < sizeInfo.minHuntedSize or monster.size > sizeInfo.maxHuntedSize;
    if Settings.current.notifications.notificationMode >= Settings.ShowMonstersMode.HideObtained then
        if (monster.isSmall and sizeInfo.smallCrownObtained) or
            (monster.isBig and sizeInfo.bigCrownObtained) or
            (monster.isKing and sizeInfo.kingCrownObtained) then
            if Settings.current.notifications.notificationMode == Settings.ShowMonstersMode.ShowNewRecords then
                if not isNewRecord then
                    return;
                end
            else
                return;
            end
        end
    end

    Notifications.AddSizeRecordNotification(monster.emId, monster.roleId, monster.legendaryId,
        math.floor(monster.size * sizeInfo.baseSize), monster.crownType, Monsters.GetEnemyName(monster.emId),
        monster.area);
end

-------------------------------------------------------------------

function Notifications.Update()
    if not Settings.current.notifications.showNotifications then
        return;
    end

    local sw, sh = Drawing.GetWindowSize();

    if #NotificationQueue > 0 and not CurrentNotification then
        CurrentNotification = NotificationWidget.New(NotificationQueue[1].message, NotificationQueue[1].icon);
        table.remove(NotificationQueue, 1);
        CurrentNotification:show(0.25, 0.25, function()
            Animation.Delay(Settings.current.notifications.notificionDisplayTime, function()
                CurrentNotification:hide(0.25, 0.25, function()
                    CurrentNotification = nil;
                end)
            end)
        end)
    end

    if CurrentNotification then
        CurrentNotification:draw(sw * 0.5, 200);
    end
end

-------------------------------------------------------------------

function Notifications.AddNotification(message, icon)
    if Settings.current.notifications.showNotifications then
        NotificationQueue[#NotificationQueue + 1] = { message = message, icon = icon };
    end
end

-------------------------------------------------------------------

function Notifications.AddSizeRecordNotification(emId, roleId, legendaryId, size, crownType, monsterName, area)
    if Settings.current.notifications.notificationType == Settings.NotificationType.Legacy then
        local crownString = Const.CrownNames[crownType] ..
            " Crown " .. monsterName .. " spotted!";
        Notifications.AddNotification(crownString, Drawing.imageResources[crownType]);
    else
        local systemMessage = "Spotted ";
        if crownType > 0 then
            systemMessage = systemMessage .. Const.CrownNames[crownType] .. " Crown ";
        end
        systemMessage = systemMessage .. monsterName .. " in Area " .. tostring(area);
        Singletons.ChatManager:addSystemLog(systemMessage);
        Singletons.ChatManager:addEnemySizeLog(emId, roleId, legendaryId, size, crownType);
    end
end

-------------------------------------------------------------------

---Shows the size graph via an animation
---@param s table
---@param showTime number
---@param callback function
function NotificationWidget.ShowAnim(s, showTime, openTime, callback)
    s.AnimData.visible = true;
    showTime = showTime or 0.25;
    openTime = openTime or 0.25;

    Animation.AnimLerpV2(0, -500, 0, 0, showTime, function(x, y)
        s.AnimData.offset.x = x;
        s.AnimData.offset.y = y;
    end, "easeInOutQuad");

    Animation.Delay(showTime, function()
        Animation.AnimLerp(0, 1, openTime, function(v)
            s.AnimData.scrollPercent = v;
        end)
        Animation.AnimLerp(0, 1, openTime * 0.25, function(v)
            s.AnimData.iconSize = v;
        end)
    end)

    Animation.Delay(showTime + openTime, callback);
end

-------------------------------------------------------------------

---Hides the size graph via an animation
---@param s table
---@param hideTime number
---@param closeTime number
---@param callback function
function NotificationWidget.HideAnim(s, hideTime, closeTime, callback)
    hideTime = hideTime or 0.25;
    closeTime = closeTime or 0.25;

    Animation.AnimLerp(1, 0, hideTime, function(v)
        s.AnimData.scrollPercent = v;
    end)

    Animation.Delay(closeTime * 0.5, function()
        Animation.AnimLerp(1, 0, closeTime * 0.75, function(v)
            s.AnimData.iconSize = v;
        end)
    end)

    Animation.Delay(hideTime, function()
        Animation.AnimLerpV2(0, 0, 0, -500, hideTime, function(x, y)
            s.AnimData.offset.x = x;
            s.AnimData.offset.y = y;
        end, "easeOutQuad");
    end)

    Animation.Delay(hideTime + closeTime, function()
        s.AnimData.visible = false;
        callback();
    end);
end

-------------------------------------------------------------------

local iconPadding = 10;
local textPaddingLeft = 20;
local textPaddingRight = 10;
local bgSizeMult = 1.5;

---Draw the notification window with its current AnimData
---@param s table
---@param posx number
---@param posy number
function NotificationWidget.Draw(s, posx, posy)
    local t = s.AnimData.scrollPercent;
    posx = posx + s.AnimData.offset.x + Settings.current.notifications.notificationsOffset.x;
    posy = posy + s.AnimData.offset.y + Settings.current.notifications.notificationsOffset.y;

    local left = posx - (s.bgData.contentWidth * 0.5) * t;
    local right = posx + (s.bgData.contentWidth * 0.5) * t;

    Drawing.DrawImage(s.bgData.s, left + 0.2, posy, s.bgData.sw * bgSizeMult, s.bgData.sh * bgSizeMult, 1, 0.5);
    Drawing.DrawImage(s.bgData.e, right - 0.8, posy, s.bgData.ew * bgSizeMult, s.bgData.eh * bgSizeMult, 0, 0.5);
    Drawing.DrawImage(s.bgData.f, left, posy, (s.bgData.contentWidth * t), s.bgData.fh * bgSizeMult, 0, 0.5);

    if s.icon then
        Drawing.DrawImage(s.icon, left + iconPadding, posy, s.iconSize.x * s.AnimData.iconSize,
            s.iconSize.y * s.AnimData.iconSize, 0, 0.5);
    end

    local textBeginPercent = 1 - (s.messageSize.width / s.bgData.contentWidth);
    local norm = (math.max(textBeginPercent, s.AnimData.scrollPercent) - textBeginPercent) / (1 - textBeginPercent) *
        (1.0 - 0.0) + 0.0;
    local msg = string.sub(s.message, 1, math.floor(string.len(s.message) * norm));

    Drawing.DrawTextFont(msg, Utils.GetFontD2D("notify", Settings.current.text.ntfySize),
        left + iconPadding + s.iconSize.x + textPaddingLeft,
        posy - s.messageSize.height * 0.5, s.AnimData.textColor, true, 2, 2, s.AnimData.textShadowColor);

    --[[
    local left = posx - math.max(s.bgData.contentWidth * 0.5, s.bgData.bgWidth * 0.5);
    local fillLeft = left + (s.bgData.images.scrollBgSW * t);

    for i = 0, s.bgData.fillCount - 1, 1 do
        -- we need a little bit of overlap so draw the fill a little bigger than it would have to be
        Drawing.DrawImage(s.bgData.images.scrollBgF, fillLeft - 1, posy, (s.bgData.images.scrollBgFW * t + 2) , nil, 0, 0.5);
        fillLeft = fillLeft + s.bgData.images.scrollBgFW * t - 1;
    end

    Drawing.DrawImage(s.bgData.images.scrollBgS, left, posy, s.bgData.images.scrollBgSW * t, nil, 0, 0.5);
    Drawing.DrawImage(s.bgData.images.scrollBgE, fillLeft, posy, s.bgData.images.scrollBgEW * t, nil, 0, 0.5);

    Drawing.DrawImage(s.bgData.images.scroll, left, posy, nil, nil, 0.5, 0.5);
    Drawing.DrawImage(s.bgData.images.scroll, fillLeft + s.bgData.images.scrollBgEW * t, posy, nil, nil, 0.5, 0.5);

    if s.icon then
        Drawing.DrawImage(s.icon, left + iconPadding, posy, s.iconSize.x * s.AnimData.iconSize, s.iconSize.y * s.AnimData.iconSize, 0, 0.5);
    end

    local textBeginPercent = 1 - (s.messageSize.width / s.bgData.bgWidth);

    local norm = (math.max(textBeginPercent, s.AnimData.scrollPercent) - textBeginPercent) / (1 - textBeginPercent) * (1.0 - 0.0) + 0.0;
    local msg = string.sub(s.message, 1, math.floor(string.len(s.message) * norm));

    Drawing.DrawTextFont(msg, Drawing.fontResources["notification"], left + iconPadding + s.iconSize.x + textPaddingLeft, posy - s.messageSize.height * 0.5, s.AnimData.textColor, true, 2, 2, s.AnimData.textShadowColor);
    ]]
end

-------------------------------------------------------------------

---Creates a new size graph
---@return table SizeGraph The newly created size graph
function NotificationWidget.New(message, icon, iconSizeX, iconSizeY)
    iconSizeX = iconSizeX or 64;
    iconSizeY = iconSizeY or 64;

    local bgS = Drawing.imageResources["nbgs"];
    local bgF = Drawing.imageResources["nbgf"];
    local bgE = Drawing.imageResources["nbge"];

    local bgSW, bgSH = bgS:size();
    local bgFW, bgFH = bgF:size();
    local bgEW, bgEH = bgE:size();

    local minBgSize = bgSW + bgFW + bgEW;

    local contentWidth = 0;
    local iconWidth = 0;
    if icon then
        iconWidth = iconPadding + iconSizeX;
    end
    contentWidth = contentWidth + iconWidth;

    local msgW, msgH = Drawing.MeasureTextWithFont(message, Utils.GetFontD2D("notify", Settings.current.text.ntfySize));
    contentWidth = contentWidth + textPaddingLeft + msgW + textPaddingRight;

    local table = {
        AnimData = {
            textColor = 0xFFEEEEEE,
            textShadowColor = 0xFF3f3f3f,
            offset = { x = 0, y = -500 },
            iconSize = 0,
            scrollPercent = 0,
            visible = false,
        },
        message = message,
        messageSize = { width = msgW, height = msgH },
        bgData = {
            s = bgS,
            sw = bgSW,
            sh = bgSH,
            f = bgF,
            fw = bgFW,
            fh = bgFH,
            e = bgE,
            ew = bgEW,
            eh = bgEH,
            contentWidth = contentWidth,
            bgWidth = minBgSize,
        },
        icon = icon,
        iconSize = { x = iconSizeX, y = iconSizeY },
        show = NotificationWidget.ShowAnim,
        hide = NotificationWidget.HideAnim,
        draw = NotificationWidget.Draw
    };

    return table;
end

-------------------------------------------------------------------

function Notifications.InitModule()
    Monsters.onMonsterAdded:add(OnMonsterAdded);
end

return Notifications;
