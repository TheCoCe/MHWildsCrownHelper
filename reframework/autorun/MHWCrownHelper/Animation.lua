local Easing     = require "MHWCrownHelper.Easing"
local Utils      = require "MHWCrownHelper.Utils"
local Animation  = {}

local coroutines = {};

-------------------------------------------------------------------

function Animation.Update(deltaTime)
    for i = #coroutines, 1, -1 do
        if coroutine.status(coroutines[i]) == "dead" then
            table.remove(coroutines, i);
        else
            coroutine.resume(coroutines[i], deltaTime);
        end
    end
end

-------------------------------------------------------------------

---Starts to lerp the value between fromv and tov and calls the callback with the progress every frame
---@param fromv number
---@param tov number
---@param time number
---@param callback function
---@param easing? ease
function Animation.AnimLerp(fromv, tov, time, callback, easing)
    easing = easing or "linear";
    if not type(callback) == "function" then return; end

    local ease = Easing.Find(easing);

    local co = coroutine.create(function()
        local t = 0;
        local dt = 0;
        while t <= 1 do
            local v = Animation.Lerp(fromv, tov, ease(t));
            callback(v);

            dt = coroutine.yield();
            t = t + (dt / time);
        end
        callback(tov);
    end);

    coroutines[#coroutines + 1] = co;
end

-------------------------------------------------------------------

---Starts to lerp the vector2 between from and to position and calls the callback with the progress every frame
---@param fromx number
---@param fromy number
---@param tox number
---@param toy number
---@param time number
---@param callback function
---@param easing? ease
function Animation.AnimLerpV2(fromx, fromy, tox, toy, time, callback, easing)
    easing = easing or "linear";
    if not type(callback) == "function" then return; end

    local ease = Easing.Find(easing);

    local co = coroutine.create(function()
        local t = 0;
        local dt = 0;
        while t <= 1 do
            local x, y = Animation.LerpV2(fromx, fromy, tox, toy, ease(t));
            callback(x, y);

            dt = coroutine.yield();
            t = t + (dt / time);
        end
        callback(tox, toy);
    end);

    coroutines[#coroutines + 1] = co;
end

-------------------------------------------------------------------

---Starts to lerp the color between from and to colors and calls the callback with the progress every frame
---@param fromCol number
---@param toCol number
---@param time number
---@param callback function
---@param easing? ease
function Animation.AnimLerpColor(fromCol, toCol, time, callback, easing)
    easing = easing or "linear";
    if not type(callback) == "function" then return; end

    local fromA = (fromCol >> 24) & 0xFF;
    local fromR = (fromCol >> 16) & 0xFF;
    local fromG = (fromCol >> 8) & 0xFF;
    local fromB = fromCol & 0xFF;

    local toA = (toCol >> 24) & 0xFF;
    local toR = (toCol >> 16) & 0xFF;
    local toG = (toCol >> 8) & 0xFF;
    local toB = toCol & 0xFF;

    local ease = Easing.Find(easing);

    local co = coroutine.create(function()
        local t = 0;
        local dt = 0;
        while t <= 1 do
            local a = math.ceil(Animation.Lerp(fromA, toA, ease(t)));
            local r = math.ceil(Animation.Lerp(fromR, toR, ease(t)));
            local g = math.ceil(Animation.Lerp(fromG, toG, ease(t)));
            local b = math.ceil(Animation.Lerp(fromB, toB, ease(t)));

            local col = 0x1000000 * a + 0x10000 * r + 0x100 * g + b;
            callback(col);

            dt = coroutine.yield();
            t = t + (dt / time);
        end
        callback(toCol);
    end)

    coroutines[#coroutines + 1] = co;
end

-------------------------------------------------------------------

---Starts a delay and calls the callback when the delay time has run out
---@param time number
---@param callback function
function Animation.Delay(time, callback)
    if callback ~= nil and not (type(callback) == "function") then return; end

    local co = coroutine.create(function()
        local t = 0;
        local dt = 0;

        while t < time do
            t = t + dt;
            dt = coroutine.yield();
        end

        if callback ~= nil then
            callback();
        end
    end)

    coroutines[#coroutines + 1] = co;
end

-------------------------------------------------------------------

function Animation.Lerp(v0, v1, t)
    return v0 + t * (v1 - v0);
end

-------------------------------------------------------------------

function Animation.LerpV2(x0, y0, x1, y1, t)
    return Animation.Lerp(x0, x1, t), Animation.Lerp(y0, y1, t);
end

-------------------------------------------------------------------

function Animation.LerpColor(fromCol, toCol, t)
    local fromA = (fromCol >> 24) & 0xFF;
    local fromR = (fromCol >> 16) & 0xFF;
    local fromG = (fromCol >> 8) & 0xFF;
    local fromB = fromCol & 0xFF;

    local toA = (toCol >> 24) & 0xFF;
    local toR = (toCol >> 16) & 0xFF;
    local toG = (toCol >> 8) & 0xFF;
    local toB = toCol & 0xFF;

    local a = math.ceil(Animation.Lerp(fromA, toA, t));
    local r = math.ceil(Animation.Lerp(fromR, toR, t));
    local g = math.ceil(Animation.Lerp(fromG, toG, t));
    local b = math.ceil(Animation.Lerp(fromB, toB, t));

    return 0x1000000 * a + 0x10000 * r + 0x100 * g + b;
end

return Animation;
