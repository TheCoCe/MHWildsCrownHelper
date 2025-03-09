local Easing = {};

Easing.Functions = {};

local sin = math.sin;
local cos = math.cos;
local pi = math.pi;

---@alias ease
---| '"linear"' 
---| '"easeInSine"'
---| '"easeOutSine"'
---| '"easeInOutSine"'
---| '"easeInQuad"'
---| '"easeOutQuad"'
---| '"easeInOutQuad"'

---comment
---@param easeType ease
---@return function
function Easing.Find(easeType)
    return Easing.Functions[easeType] or Easing.Functions["linear"];
end

Easing.Functions["linear"] = function (num)
    return num;
end

Easing.Functions["easeInSine"] = function (num)
    return 1 - cos((num * pi) * 0.5);
end

Easing.Functions["easeOutSine"] = function (num)
    return sin((num * pi) * 0.5);
end

Easing.Functions["easeInOutSine"] = function (num)
    return -(cos(pi * num) - 1) * 0.5;
end

Easing.Functions["easeInQuad"] = function (num)
    return num * num;
end

Easing.Functions["easeOutQuad"] = function (num)
    return 1 - (1 - num) * (1 - num);
end

Easing.Functions["easeInOutQuad"] = function (num)
    if num < 0.5 then
        return 2 * num * num;
    else
        return 1 - ((-2 * num + 2) ^ 2) * 0.5;
    end
end

return Easing;