--[[
    MIT License

    Copyright (c) 2022 GreenComfyTea

    Permission is hereby granted, free of charge, to any person obtaining a copy
    of this software and associated documentation files (the "Software"), to deal
    in the Software without restriction, including without limitation the rights
    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
    copies of the Software, and to permit persons to whom the Software is
    furnished to do so, subject to the following conditions:

    The above copyright notice and this permission notice shall be included in all
    copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
    SOFTWARE.
]]

local table_helpers = {};

function table_helpers.deep_copy(original, copies)
    copies = copies or {};
    local original_type = type(original);
    local copy;
    if original_type == 'table' then
        if copies[original] then
            copy = copies[original];
        else
            copy = {};
            copies[original] = copy;
            for original_key, original_value in next, original, nil do
                copy[table_helpers.deep_copy(original_key, copies)] = table_helpers.deep_copy(original_value, copies);
            end
            setmetatable(copy, table_helpers.deep_copy(getmetatable(original), copies));
        end
    else -- number, string, boolean, etc
        copy = original;
    end
    return copy;
end

function table_helpers.find_index(table, value, nullable)
    for i = 1, #table do
        if table[i] == value then
            return i;
        end
    end

    if not nullable then
        return 1;
    end

    return nil;
end

function table_helpers.merge(...)
    local tables_to_merge = { ... };
    assert(#tables_to_merge > 1, "There should be at least two tables to merge them");

    for key, table in ipairs(tables_to_merge) do
        assert(type(table) == "table", string.format("Expected a table as function parameter %d", key));
    end

    local result = table_helpers.deep_copy(tables_to_merge[1]);

    for i = 2, #tables_to_merge do
        local from = tables_to_merge[i];
        for key, value in pairs(from) do
            if type(value) == "table" then
                result[key] = result[key] or {};
                assert(type(result[key]) == "table", string.format("Expected a table: '%s'", key));
                result[key] = table_helpers.merge(result[key], value);
            else
                result[key] = value;
            end
        end
    end

    return result;
end

-------------------------------------------------------------------
-- Sorted key iterator: http://lua-users.org/wiki/SortedIteration
-------------------------------------------------------------------

local function __genOrderedIndex(t)
    local orderedIndex = {}
    for key in pairs(t) do
        table.insert(orderedIndex, key)
    end
    table.sort(orderedIndex)
    return orderedIndex
end

local function orderedNext(t, state)
    -- Equivalent of the next function, but returns the keys in the alphabetic
    -- order. We use a temporary ordered key table that is stored in the
    -- table being iterated.

    local key = nil
    --print("orderedNext: state = "..tostring(state) )
    if state == nil then
        -- the first time, generate the index
        t.__orderedIndex = __genOrderedIndex(t)
        key = t.__orderedIndex[1]
    else
        -- fetch the next value
        for i = 1, #t.__orderedIndex do
            if t.__orderedIndex[i] == state then
                key = t.__orderedIndex[i + 1]
            end
        end
    end

    if key then
        return key, t[key]
    end

    -- no more value to return, cleanup
    t.__orderedIndex = nil
    return
end

function table_helpers.orderedPairs(t)
    -- Equivalent of the pairs() function on tables. Allows to iterate
    -- in order
    return orderedNext, t, nil
end

return table_helpers;
