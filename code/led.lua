--[[
    Aprs4G by BG2LBF - LED控制
]]
local LED_GPS = 30
local LED_APRSNET = 27
if DEV_TYPE == "air700" then
    LED_GPS = 30
    LED_APRSNET = 27
elseif DEV_TYPE == "air780e" then
    LED_GPS = 21
    LED_APRSNET = 27
elseif DEV_TYPE == "air780eg" then
    LED_GPS = 21
    LED_APRSNET = 27
elseif DEV_TYPE == "air780eg-yed" then
    LED_GPS = 27
    LED_APRSNET = 22
end
local LED_POWER_SAVE_MODE = false
local LONG_LED_BLUE = false
local LONG_LED_GREEN = false
-- 蓝灯代表网络连接状况 熄灭代表正常  闪烁代表不正常
local LED_BLUE = gpio.setup(LED_APRSNET, 0, gpio.PULLUP)
-- 绿灯代表GPS定位状况 熄灭代表正常  闪烁代表不正常
local LED_GREEN = gpio.setup(LED_GPS, 0, gpio.PULLUP)

-- 双灯短闪
local function lightLED1()
    LED_BLUE(1)
    sys.wait(30)
    LED_BLUE(0)
    sys.wait(30)
    LED_BLUE(1)
    sys.wait(30)
    LED_BLUE(0)
    sys.wait(100)
    LED_GREEN(1)
    sys.wait(30)
    LED_GREEN(0)
    sys.wait(30)
    LED_GREEN(1)
    sys.wait(30)
    LED_GREEN(0)
end
-- 双灯长闪
local function lightLED2()
    LED_BLUE(1)
    sys.wait(60)
    LED_BLUE(0)
    sys.wait(60)
    LED_BLUE(1)
    sys.wait(60)
    LED_BLUE(0)
    sys.wait(300)
    LED_GREEN(1)
    sys.wait(60)
    LED_GREEN(0)
    sys.wait(60)
    LED_GREEN(1)
    sys.wait(60)
    LED_GREEN(0)
end
-- 蓝灯闪
local function lightLEDBLUE()
    LED_BLUE(1)
    sys.wait(60)
    LED_BLUE(0)
    sys.wait(60)
    LED_BLUE(1)
    sys.wait(60)
    LED_BLUE(0)
end
-- 绿灯闪
local function lightLEDGREEN()
    LED_GREEN(1)
    sys.wait(60)
    LED_GREEN(0)
    sys.wait(60)
    LED_GREEN(1)
    sys.wait(60)
    LED_GREEN(0)
end

sys.taskInit(function()
    -- sys.waitUntil("CFGLOADED")
    while true do
        -- 5s一循环
        sys.wait(5000)
        -- 省电模式点灯-闪灯  
        if LED_POWER_SAVE_MODE then
            lightLED1()
        else
            if LONG_LED_BLUE and LONG_LED_GREEN then
                if gpio.get(LED_APRSNET) ~= 0 or gpio.get(LED_GPS) ~= 0 then
                    -- 都生效就关灯
                    LED_BLUE(0)
                    LED_GREEN(0)
                end
            elseif LONG_LED_BLUE or LONG_LED_GREEN then
                if LONG_LED_BLUE then
                    lightLEDBLUE()
                else
                    lightLEDGREEN()
                end
            else
                lightLED2()
            end 
        end

    end
end)

sys.subscribe("LOGGED_IN", function()
    LONG_LED_BLUE = true
end)
sys.subscribe("LOGGED_OUT", function()
    LONG_LED_BLUE = false
end)
sys.subscribe("LOC_GPS_FIXED", function()
    LONG_LED_GREEN = true
end)
sys.subscribe("LOC_GPS_LOSE", function()
    LONG_LED_GREEN = false
end)
sys.subscribe("LOC_LBS_FIXED", function()
    LONG_LED_GREEN = true
end)
sys.subscribe("LOC_LBS_LOSE", function()
    LONG_LED_GREEN = false
end)
sys.subscribe("LOC_USER_FIXED", function()
    LONG_LED_GREEN = true
end)

