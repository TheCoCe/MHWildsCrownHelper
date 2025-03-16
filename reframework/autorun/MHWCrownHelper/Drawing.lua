local Drawing             = {};
local Singletons          = require("MHWCrownHelper.Singletons")
local Settings            = require("MHWCrownHelper.Settings");
local Animation           = require("MHWCrownHelper.Animation")
local Utils               = require("MHWCrownHelper.Utils")
local Const               = require("MHWCrownHelper.Const")
local d2d                 = d2d;
local draw                = draw;

-- window size
local getMainViewMethod   = sdk.find_type_definition("via.SceneManager"):get_method("get_MainView");
local getWindowSizeMethod = sdk.find_type_definition("via.SceneView"):get_method("get_WindowSize");

-- aspect ratio
local getMainCamMethod    = sdk.find_type_definition("app.CameraManager"):get_method("get_PrimaryCamera");
local getAspectRatio      = sdk.find_type_definition("via.Camera"):get_method("get_AspectRatio");

-- image resources
Drawing.imageResourcePath = "MHWCrownHelper/";
Drawing.imageResources    = {};

---Initializes the requierd resources for drawing
function Drawing.Init()
    if d2d ~= nil then
        Drawing.InitImage(Const.CrownType.None, "monster1.png");
        Drawing.InitImage(Const.CrownType.Small, "MiniCrown.png");
        Drawing.InitImage(Const.CrownType.Big, "BigCrown.png");
        Drawing.InitImage(Const.CrownType.King, "KingCrown.png");
        Drawing.InitImage("small_gs", "MiniCrown_gs.png");
        Drawing.InitImage("big_gs", "BigCrown_gs.png");
        Drawing.InitImage("king_gs", "KingCrown_gs.png");
        Drawing.InitImage("book", "Book.png");
        Drawing.InitImage("new_record", "NewRecord.png");
        Drawing.InitImage("cocoon", "Cocoon.png");
        Drawing.InitImage("quest_target", "QuestTarget.png");

        Drawing.InitImage("nbgs", "NotificationBgS.png");
        Drawing.InitImage("nbgf", "NotificationBgF.png");
        Drawing.InitImage("nbge", "NotificationBgE.png");

        Drawing.InitImage("sgbg", "SizeGraphBg.png");

        -- init d2d fonts
        Utils.InitFontD2D("regular", {
            [Const.Fonts.SIZES.TINY] = 12,
            [Const.Fonts.SIZES.SMALL] = 18,
            [Const.Fonts.SIZES.MEDIUM] = 24,
            [Const.Fonts.SIZES.LARGE] = 30,
            [Const.Fonts.SIZES.HUGE] = 36
        }, true, false);
        Utils.InitFontD2D("notify", {
            [Const.Fonts.SIZES.TINY] = 18,
            [Const.Fonts.SIZES.SMALL] = 24,
            [Const.Fonts.SIZES.MEDIUM] = 30,
            [Const.Fonts.SIZES.LARGE] = 36,
            [Const.Fonts.SIZES.HUGE] = 42
        }, true, false);
    end
end

-------------------------------------------------------------------

---Initializes a image resource from the given image name to be retrieved later using the given key.
---The image directroy will automatically be prepended to the image path.
---@param key any
---@param image string
function Drawing.InitImage(key, image)
    if d2d ~= nil then
        Drawing.imageResources[key] = d2d.Image.new(Drawing.imageResourcePath .. image);
    end
end

-------------------------------------------------------------------

---Update loop (used for animation/ui updates etc.)
---@param deltaTime number
function Drawing.Update(deltaTime)
    Animation.Update(deltaTime);
end

-------------------------------------------------------------------

---Draws a circle at the specified position. Only call this from re.on_frame or re.on_draw_ui!
---@param posx number The x center position.
---@param posy number The y center position.
---@param radius number The circles radius.
---@param color number As hex e.g. 0xFFFFFFFF.
---@param offset Vector2f|nil
function Drawing.DrawCircle(posx, posy, radius, color, offset)
    if offset ~= nil then
        posx = posx + offset.x;
        posy = posy + offset.y;
    end
    if d2d ~= nil then
        d2d.fill_circle(posx, posy, radius, color);
    else
        draw.filled_circle(posx, posy, radius, color, 16);
    end
end

-------------------------------------------------------------------

---Draws a rectangle at the specified location with the specified size
---@param posx number
---@param posy number
---@param sizex number
---@param sizey number
---@param color number
---@param pivotx number
---@param pivoty number
---@param offset Vector2f|nil
function Drawing.DrawRect(posx, posy, sizex, sizey, color, pivotx, pivoty, offset)
    pivotx = pivotx or 0;
    pivoty = pivoty or 0;

    if offset ~= nil then
        posx = posx + offset.x;
        posy = posy + offset.y;
    end
    if d2d ~= nil then
        d2d.fill_rect(posx - sizex * pivotx, posy - sizey * pivoty, sizex, sizey, color);
    else
        draw.filled_rect(posx - sizex * pivotx, posy - sizey * pivoty, sizex, sizey, color);
    end
end

-------------------------------------------------------------------

---Draws a text at the specified location with optional text shadow
---@param text string
---@param posx number
---@param posy number
---@param color number
---@param drawShadow boolean|nil
---@param shadowOffsetX number|nil
---@param shadowOffsetY number|nil
---@param shadowColor integer|nil
---@param offset Vector2f|nil
function Drawing.DrawText(text, posx, posy, color, drawShadow, shadowOffsetX, shadowOffsetY, shadowColor, offset)
    if text == nil then
        return;
    end

    local font = Utils.GetFontD2D("regular", Settings.current.text.graphSize);
    if font == nil then
        Utils.logDebug("No font found for size " .. Settings.current.text.graphSize);
        return;
    end

    if offset ~= nil then
        posx = posx + offset.x;
        posy = posy + offset.y;
    end

    if drawShadow then
        if d2d ~= nil then
            d2d.text(font, text, posx + shadowOffsetX, posy + shadowOffsetY, shadowColor);
        else
            draw.text(text, posx + shadowOffsetX, posy + shadowOffsetY, Drawing.ARGBtoABGR(shadowColor));
        end
    end

    if d2d ~= nil then
        d2d.text(font, text, posx, posy, color);
    else
        draw.text(text, posx, posy, Drawing.ARGBtoABGR(color));
    end
end

-------------------------------------------------------------------

---Draws a text at the specified location with optional text shadow
---@param text string
---@param font userdata
---@param posx number
---@param posy number
---@param color number
---@param drawShadow boolean|nil
---@param shadowOffsetX number|nil
---@param shadowOffsetY number|nil
---@param shadowColor integer|nil
---@param offset Vector2f|nil
function Drawing.DrawTextFont(text, font, posx, posy, color, drawShadow, shadowOffsetX, shadowOffsetY, shadowColor)
    if text == nil then
        return;
    end

    if font == nil then font = Utils.GetFontD2D("regular", Settings.current.text.graphSize); end
    if font == nil then
        Utils.logDebug("No font found for size " .. Settings.current.text.graphSize);
        return;
    end

    if drawShadow then
        if d2d ~= nil then
            d2d.text(font, text, posx + shadowOffsetX, posy + shadowOffsetY, shadowColor);
        else
            draw.text(text, posx + shadowOffsetX, posy + shadowOffsetY, Drawing.ARGBtoABGR(shadowColor));
        end
    end

    if d2d ~= nil then
        d2d.text(font, text, posx, posy, color);
    else
        draw.text(text, posx, posy, Drawing.ARGBtoABGR(color));
    end
end

-------------------------------------------------------------------

---Measures the text in the current drawing font
---@param text string
---@return number
function Drawing.MeasureText(text)
    local font = Utils.GetFontD2D("regular", Settings.current.text.graphSize);
    if font then
        return font:measure(text);
    end

    return 0;
end

-------------------------------------------------------------------

---Measures the text in the current drawing font
---@param text string
---@param font any|nil
---@return number
function Drawing.MeasureTextWithFont(text, font)
    if font == nil then font = Utils.GetFontD2D("regular", Settings.current.text.graphSize); end
    if font then
        return font:measure(text);
    end

    return 0;
end

-------------------------------------------------------------------

---Draws an image at the specified location with optional size and pivot
---@param image any
---@param posx number
---@param posy number
---@param sizex number|nil
---@param sizey number|nil
---@param pivotx number|nil
---@param pivoty number|nil
---@param offset Vector2f|nil
function Drawing.DrawImage(image, posx, posy, sizex, sizey, pivotx, pivoty, offset)
    if d2d == nil or image == nil then
        return;
    end

    pivotx = pivotx or 0;
    pivoty = pivoty or 0;

    local imgWidth, imgHeight = image:size();
    sizex = sizex or imgWidth;
    sizey = sizey or imgHeight;

    if offset ~= nil then
        posx = posx + offset.x;
        posy = posy + offset.y;
    end

    posx = posx - pivotx * sizex;
    posy = posy - pivoty * sizey

    d2d.image(image, posx, posy, sizex, sizey);
end

-------------------------------------------------------------------

---Gets the current window size
---@return number width Width of the window
---@return number height Height of the window
function Drawing.GetWindowSize()
    local windowSize = getWindowSizeMethod(getMainViewMethod(Singletons.SceneManager));

    local w = windowSize.w;
    local h = windowSize.h;

    return w, h;
end

-------------------------------------------------------------------

---Gets the current aspect ratio
---@return number aspectRatio
function Drawing.GetAspectRatio()
    local cam = getMainCamMethod(Singletons.GameCamera);
    if cam ~= nil then
        return getAspectRatio(cam);
    end

    return 1;
end

-------------------------------------------------------------------

---Converts the location for top left to top right
---@param posx number
---@param posy number
---@return number posx
---@return number posy
function Drawing.FromTopRight(posx, posy)
    local w, h = Drawing.GetWindowSize();
    return w - posx, posy;
end

-------------------------------------------------------------------

---Converts the location for top left to bottom right
---@param posx number
---@param posy number
---@return number posx
---@return number posy
function Drawing.FromBottomRight(posx, posy)
    local w, h = Drawing.GetWindowSize();
    return w - posx, h - posy;
end

-------------------------------------------------------------------

---Converts the location for top left to bottom left
---@param posx number
---@param posy number
---@return number posx
---@return number posy
function Drawing.FromBottomLeft(posx, posy)
    local w, h = Drawing.GetWindowSize();
    return posx, h - posy;
end

-------------------------------------------------------------------

---Conerts a color from ARGB to ABGR: 0x00112233 -> 0x00332211
---@param ARGBColor integer|nil
---@return integer ABGRColor The color in the format ABGR
function Drawing.ARGBtoABGR(ARGBColor)
    local a = (ARGBColor >> 24) & 0xFF;
    local r = (ARGBColor >> 16) & 0xFF;
    local g = (ARGBColor >> 8) & 0xFF;
    local b = ARGBColor & 0xFF;

    local ABGRColor = 0x1000000 * a + 0x10000 * b + 0x100 * g + r;

    return ABGRColor;
end

-------------------------------------------------------------------

---Initializes the Drawing module
function Drawing.InitModule()
    --imguiFont = imgui.load_font("NotoSansKR-Bold.otf", Settings.current.text.textSize, { 0x1, 0xFFFF, 0 });
    Drawing.Init();
end

-------------------------------------------------------------------

return Drawing;
