local Singletons = require "MHWCrownHelper.Singletons"
local Const      = require "MHWCrownHelper.Const"
local Utils = {};

local nameString = "[MHWCrownHelper]: ";

Utils.debugMode = true;

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
    if not Singletons.GUIManager then
        return Const.Language.English;
    end

    return Singletons.GUIManager:getSystemLanguageToApp();
end

-------------------------------------------------------------------

local cachedImguiFonts = {};

--- Load an imgui font
---@param fontSize number|nil
function Utils.InitFontImgui(key, fontSize)
    if fontSize == nil then fontSize = 14 end;
    local language = Utils.GetLanguage();
    local fontConfig = Const.Fonts[language];
    if fontConfig == nil then
        fontConfig = Const.Fonts.Default;
    end

    cachedImguiFonts[key] = imgui.load_font(fontConfig.FONT_NAME, fontSize, fontConfig.GLYPH_RANGES);
    return cachedImguiFonts[key];
end

-------------------------------------------------------------------

function Utils.GetFontImgui(key)
    return cachedImguiFonts[key];
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
    return font[size];
end

return Utils;
