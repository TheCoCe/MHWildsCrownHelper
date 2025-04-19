local Singletons = require "MHWCrownHelper.Singletons"
local Const      = require "MHWCrownHelper.Const"
local Utils      = {};

local nameString = "[MHWCrownHelper]: ";

Utils.debugMode  = false;

--[[ Logging ]] --
-------------------------------------------------------------------

--- Logs a info message
---@param message string
function Utils.logInfo(message)
    log.info(nameString .. message);
end

-------------------------------------------------------------------

--- Logs a warning message
---@param message string
function Utils.logWarn(message)
    log.warn(nameString .. message);
end

-------------------------------------------------------------------

--- Logs a error message
---@param message string
function Utils.logError(message)
    log.error(nameString .. message);
end

-------------------------------------------------------------------

--- Logs a debug message
---@param message string
function Utils.logDebug(message)
    if Utils.debugMode then
        log.debug(nameString .. message);
        log.info(nameString .. message);
    end
end

--[[ Formatting ]] --
-------------------------------------------------------------------

--- see https://stackoverflow.com/questions/10989788/format-integer-in-lua#10992898
function Utils.formatNumber(number)
    local i, j, minus, int, fraction = tostring(number):find('([-]?)(%d+)([.]?%d*)')
    -- reverse the int-string and append a comma to all blocks of 3 digits
    int = int:reverse():gsub("(%d%d%d)", "%1,")

    -- reverse the int-string back remove an optional comma and put the
    -- optional minus and fractional part back
    return minus .. int:reverse():gsub("^,", "") .. fraction
end

--[[ Enums ]] --
-------------------------------------------------------------------

function Utils.GenerateEnum(typename)
    local t = sdk.find_type_definition(typename)
    if not t then return {} end

    local fields = t:get_fields()
    local enum = {}

    for _, field in ipairs(fields) do
        if field:is_static() then
            local name = field:get_name()
            local raw_value = field:get_data(nil)

            enum[name] = raw_value
        end
    end

    return enum
end

-------------------------------------------------------------------

function Utils.GenerateEnumValues(typename)
    local t = sdk.find_type_definition(typename)
    if not t then return {} end

    local fields = t:get_fields()
    local enum = {}

    for _, field in ipairs(fields) do
        if field:is_static() then
            local name = field:get_name()
            local raw_value = field:get_data(nil)

            enum[raw_value] = name
        end
    end

    return enum
end

-------------------------------------------------------------------

--see: https://stackoverflow.com/questions/15429236/how-to-check-if-a-module-exists-in-lua
function Utils.IsModuleAvailable(name)
    if package.loaded[name] then
        return true
    else
        ---@diagnostic disable-next-line: deprecated
        for _, searcher in ipairs(package.searchers or package.loaders) do
            local loader = searcher(name)
            if type(loader) == 'function' then
                package.preload[name] = loader
                return true
            end
        end
        return false
    end
end

--[[ Hooks ]] --
-------------------------------------------------------------------

function Utils.Hook(type, method, pre_function, post_function)
    if type == nil or method == nil then return end
    if pre_function == nil then pre_function = function(args) end end
    if post_function == nil then post_function = function(retval) return retval end end

    local t = sdk.find_type_definition(type)
    if t == nil then
        Utils.logError("Nil type: " .. tostring(type))
        return
    end

    local m = t:get_method(method)
    if m == nil then
        Utils.logError("Nil method: " .. tostring(method))
        return
    end

    sdk.hook(
        m,
        pre_function,
        function(retval)
            local ret = post_function(retval)
            if ret == nil then return retval end
            return ret
        end,
        false
    )
end

--[[ Language ]] --
-------------------------------------------------------------------

function Utils.GetLanguage()
    local optionUtil = sdk.find_type_definition("app.OptionUtil");
    local getLanguage = optionUtil:get_method("getTextLanguage()");
    local lang = getLanguage(nil);
    local languageDef = sdk.find_type_definition("app.LanguageDef");
    local covertLanguage = languageDef:get_method("convert(app.LanguageDef.LANGUAGE_APP)");
    return covertLanguage(nil, lang);
end

-------------------------------------------------------------------

local currentCachedFont = {
    Font = nil,
    size = -1,
    language = -1
};

local cachedFontSettings = {};

--- Load an imgui font
---@param fontSizes table<any, number>
function Utils.InitFontImgui(key, fontSizes)
    local fontSizeSettings = {};
    for _, v in pairs(Const.Fonts.SIZES) do
        local size = fontSizes[v];
        if size == nil then
            size = Const.Fonts.DEFAULT_FONT_SIZE;
        end

        fontSizeSettings[v] = size;
    end

    cachedFontSettings[key] = fontSizeSettings;
end

-------------------------------------------------------------------

function Utils.GetFontImgui(key, size)
    -- Loading big glyph sets (like CJK language fonts) in quick succession crashes the game.
    -- Due to this we only cache the font once. Changing the size while the script is running will not be allowed. You have to use "Reset script"
    if currentCachedFont.Font == nil then --or Utils.GetLanguage() ~= currentCachedFont.language or reqSize ~= currentCachedFont.size then
        local FontSettings = cachedFontSettings[key];
        if FontSettings == nil then return nil; end
        local reqSize = FontSettings[size];
        --Utils.logDebug("reqSize: " .. tostring(reqSize));
        if reqSize == nil then
            reqSize = Const.Fonts.DEFAULT_FONT_SIZE;
        end;

        local language = Utils.GetLanguage();
        Utils.logDebug("[Utils.InitFontImgui] GetLanguage returned: " .. tostring(language));
        local fontInfo = Const.Fonts[language];
        if not fontInfo then
            Utils.logDebug("Fallback");
            fontInfo = Const.Fonts.Default;
        end

        currentCachedFont.Font = imgui.load_font(fontInfo.FONT_NAME, reqSize, fontInfo.GLYPH_RANGES);
        currentCachedFont.language = language;
        currentCachedFont.size = reqSize;
        Utils.logDebug("[Utils.InitFontImgui] Added font " ..
            fontInfo.FONT_NAME .. " with size " .. size .. " for language " .. language);
    end

    return currentCachedFont.Font;
end

-------------------------------------------------------------------

local cachedD2DFonts = {};

--- Load a d2d font. You can only call this in the d2d register function!
---@param fontSizes table<any, number>
---@param bold boolean|nil
---@param italic boolean|nil
function Utils.InitFontD2D(key, fontSizes, bold, italic)
    local language = Utils.GetLanguage();
    local fontInfo = Const.Fonts[language];
    if not fontInfo then
        fontInfo = Const.Fonts.Default;
    end

    local fonts = {};

    for _, v in pairs(Const.Fonts.SIZES) do
        local size = fontSizes[v];
        if not size then
            size = Const.Fonts.DEFAULT_FONT_SIZE;
        end

        fonts[v] = d2d.Font.new(fontInfo.FONT_FAMILY, math.ceil(size), bold, italic);
    end

    cachedD2DFonts[key] = fonts;
end

-------------------------------------------------------------------

function Utils.GetFontD2D(key, size)
    local font = cachedD2DFonts[key];
    if font ~= nil then
        return font[size];
    end

    return nil;
end

-------------------------------------------------------------------

---@param self string
function string:contains(sub)
    return self:find(sub, 1, true) ~= nil
end

-------------------------------------------------------------------

---@param self string
function string:startswith(start)
    return self:sub(1, #start) == start
end

-------------------------------------------------------------------

---@param self string
function string:endswith(ending)
    return ending == "" or self:sub(- #ending) == ending
end

-------------------------------------------------------------------

---@param self string
function string:replace(old, new)
    local s = self
    local search_start_idx = 1

    while true do
        local start_idx, end_idx = s:find(old, search_start_idx, true)
        if (not start_idx) then
            break
        end

        local postfix = s:sub(end_idx + 1)
        s = s:sub(1, (start_idx - 1)) .. new .. postfix

        search_start_idx = -1 * postfix:len()
    end

    return s
end

-------------------------------------------------------------------

---@param self string
function string:insert(pos, text)
    return self:sub(1, pos - 1) .. text .. self:sub(pos)
end

return Utils;
