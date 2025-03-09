local Time = {};

local application = sdk.get_native_singleton("via.Application");
local applicationTypeDef = sdk.find_type_definition("via.Application");
local getFrameTimeMilliseconds = applicationTypeDef:get_method("get_FrameTimeMillisecond");

Time.timeTotal = 0;
Time.timeDelta = 0;

local lastDrawTime = 0;

Time.timeDeltaD2D = 0;

-------------------------------------------------------------------

-- update the frame time (should be called in on_frame())
function Time.Tick()
    Time.timeDelta = getFrameTimeMilliseconds(application) * 0.001;
    Time.timeTotal = os.clock();
end

-------------------------------------------------------------------

-- update the d2d frame time (should be called in d2d draw function)
function Time.D2DTick()
    local curTime = os.clock();
    Time.timeDeltaD2D = curTime - lastDrawTime;
    lastDrawTime = curTime;
end

-------------------------------------------------------------------

return Time;