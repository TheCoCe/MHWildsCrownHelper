local Drawing             = {};
local Singletons          = require("MHWCrownHelper.Singletons")
local Settings            = require("MHWCrownHelper.Settings");
local Animation           = require("MHWCrownHelper.Animation")
local Utils               = require("MHWCrownHelper.Utils")
local Const               = require("MHWCrownHelper.Const")

-- window size
local getMainViewMethod   = sdk.find_type_definition("via.SceneManager"):get_method("get_MainView");
local getWindowSizeMethod = sdk.find_type_definition("via.SceneView"):get_method("get_WindowSize");

-- aspect ratio
local getMainCamMethod    = sdk.find_type_definition("app.CameraManager"):get_method("get_PrimaryCamera");
local getAspectRatio      = sdk.find_type_definition("via.Camera"):get_method("get_AspectRatio");

-- font resources
--local imguiFont;
local d2dFont;

Drawing.fontResources     = {};

-- image resources
Drawing.imageResourcePath = "MHWCrownHelper/";
Drawing.imageResources    = {};

---Initializes the requierd resources for drawing
function Drawing.Init()
    if d2d ~= nil then
        Drawing.InitImage(Const.CrownIcons[Const.CrownType.Small], "MiniCrown.png");
        Drawing.InitImage(Const.CrownIcons[Const.CrownType.Big], "BigCrown.png");
        Drawing.InitImage(Const.CrownIcons[Const.CrownType.King], "KingCrown.png");
        Drawing.InitImage("monster", "monster1.png");
        Drawing.InitImage("book", "Book.png");

        Drawing.InitImage("nbgs", "NotificationBgS.png");
        Drawing.InitImage("nbgf", "NotificationBgF.png");
        Drawing.InitImage("nbge", "NotificationBgE.png");

        Drawing.InitImage("sgbg", "SizeGraphBg.png");

        d2dFont = d2d.Font.new("Consolas", Settings.current.text.textSize, false);
        Drawing.InitFont("notification", "Consolas", 25, true, false);
    end
end

-------------------------------------------------------------------

---Initializes a image resource from the given image name to be retrieved later using the given key.
---The image directroy will automatically be prepended to the image path.
---@param key string
---@param image string
function Drawing.InitImage(key, image)
    if d2d ~= nil then
        Drawing.imageResources[key] = d2d.Image.new(Drawing.imageResourcePath .. image);
    end
end

-------------------------------------------------------------------

---comment
---@param key string
---@param font string
---@param size integer
---@param bold boolean
---@param italic boolean
function Drawing.InitFont(key, font, size, bold, italic)
    if d2d ~= nil then
        Drawing.fontResources[key] = d2d.Font.new(font, size, bold, italic);
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
function Drawing.DrawCircle(posx, posy, radius, color)
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
function Drawing.DrawRect(posx, posy, sizex, sizey, color, pivotx, pivoty)
    pivotx = pivotx or 0;
    pivoty = pivoty or 0;

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
function Drawing.DrawText(text, posx, posy, color, drawShadow, shadowOffsetX, shadowOffsetY, shadowColor)
    if text == nil then
        return;
    end

    if drawShadow then
        if d2d ~= nil then
            d2d.text(d2dFont, text, posx + shadowOffsetX, posy + shadowOffsetY, shadowColor);
        else
            draw.text(text, posx + shadowOffsetX, posy + shadowOffsetY, Drawing.ARGBtoABGR(shadowColor));
        end
    end

    if d2d ~= nil then
        d2d.text(d2dFont, text, posx, posy, color);
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
function Drawing.DrawTextFont(text, font, posx, posy, color, drawShadow, shadowOffsetX, shadowOffsetY, shadowColor)
    if text == nil or font == nil then
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
    if d2dFont then
        return d2dFont:measure(text);
    end

    return 0;
end

-------------------------------------------------------------------

---Measures the text in the current drawing font
---@param text string
---@param font userdata
---@return number
function Drawing.MeasureTextWithFont(text, font)
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
function Drawing.DrawImage(image, posx, posy, sizex, sizey, pivotx, pivoty)
    if d2d == nil or image == nil then
        return;
    end

    pivotx = pivotx or 0;
    pivoty = pivoty or 0;

    local imgWidth, imgHeight = image:size();
    sizex = sizex or imgWidth;
    sizey = sizey or imgHeight;

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
