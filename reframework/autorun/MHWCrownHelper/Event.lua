local Event = {};

-------------------------------------------------------------------

---Checks if the argument is of type function
---@param f any
---@return boolean isFunction true when the argument is a function
local function IsFunction(f)
    if f and type(f) == 'function' then
        return true;
    else
        return false;
    end
end

-------------------------------------------------------------------

---Adds a listener to the event
---@param e table
---@param f function
---@return boolean success true if adding was successful
local function AddListener(e, f)
    if IsFunction(f) then
        e.__listeners[f] = true;
        return true;
    else
        return false;
    end
end

-------------------------------------------------------------------

---Removes a listener from the event
---@param e table
---@param f function
---@return boolean success true if removing was successful
local function RemoveListener(e, f)
    if IsFunction(f) then
        e.__listeners[f] = nil;
        return true;
    else
        return false;
    end
end

-------------------------------------------------------------------

---Clears all listeners from the event
---@param e table
---@param f function
local function ClearListeners(e, f)
    e.__listeners = {};
end

-------------------------------------------------------------------

function Event.New()
    return setmetatable({
        __listeners = {},
        add = AddListener,
        remove = RemoveListener,
        clear = ClearListeners
    }, {
        __call = function(self, ...)
            for f, _ in pairs(self.__listeners) do f(...) end
        end
    })
end

return Event;
