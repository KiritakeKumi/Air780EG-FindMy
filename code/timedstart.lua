--[[
    Aprs4G by BG2LBF - 定时省电模式-定时启动管理/ 指定时间重启
]]

local wakeupTime = 300   -- 启动5分钟
local startTime = 0
local startTime4Restart = 0
local isHIB = false

sys.taskInit(function()
    sys.wait(15000) -- 等等联网
    startTime = os.time()
    if fskv.init() then
        log.info("fskv", "init complete")
        if fskv.get("POWER_SAVE_MODE_D1TIME") ~= nil then
            wakeupTime = fskv.get("POWER_SAVE_MODE_D1TIME")
        end
        local wakeupTime2 = 3600
        if fskv.get("POWER_SAVE_MODE_D2TIME") ~= nil then
            wakeupTime2 = fskv.get("POWER_SAVE_MODE_D2TIME")
        end
        local save_mode = -1
        if fskv.get("POWER_SAVE_MODE") ~= nil then
            save_mode = fskv.get("POWER_SAVE_MODE")
        end
        if save_mode == 2 then
            while isHIB == false do
                if wakeupTime < os.time() - startTime then
                    -- 到点了 该sleep了
                    pm.dtimerStart(2, wakeupTime2 * 1000)
                    mobile.flymode(0, true)
                    if DEV_TYPE == "air700" then
                        gpio.set(29, 0) 
                    elseif DEV_TYPE == "air780e" then
                        gpio.set(25, 0) 
                    elseif DEV_TYPE == "air780eg" then
                        pm.power(pm.GPS, false) 
                        i2c.send(0, 0x18, {0x0D, 0xFC}, 1)
                        i2c.send(0, 0x18, {0x00, 0x1F}, 1)
                        i2c.send(0, 0x18, {0x12, 0x02}, 1)
                        i2c.send(0, 0x18, {0x0E, 0xC2}, 1)
                        pm.power(pm.DAC_EN, false)
                        -- pm.power(pm.USB, false)
                        -- 关掉中断检测
                        gpio.setup(20, nil)
                    elseif DEV_TYPE == "air780eg-yed" then
                        pm.power(pm.GPS, false)
                    end
                    sys.wait(2000)
                    isHIB = true
                    pm.power(pm.WORK_MODE, 3)
                    -- pm.request(pm.HIB)
                    sys.wait(10000)
                end
                sys.wait(1000)
            end
        end 
    end
    
end)

sys.taskInit(function()
    sys.waitUntil("CFGLOADED")
    sys.wait(1000)
    startTime4Restart = os.time()
    if aprscfg.POWER_RESTART_TIME > 0 then
        local restartTime = aprscfg.POWER_RESTART_TIME * 60 * 60
        while true do
            if restartTime < os.time() - startTime4Restart then
                -- 到点了 该restart了
                sys.wait(1000)
                pm.reboot()
            end
            sys.wait(10000)
        end
    end 
    
end)

sys.taskInit(function()
    sys.waitUntil("CFGLOADED")
    sys.wait(60000)
    local startTime4err = os.time()
    if aprscfg.PLAT == 0 or aprscfg.PLAT == 1 then
        while true do
            if not isReady4Send and GPS_FIXED then
                if (os.time() - startTime4err) > 60 then
                    if (os.time() - startTime4err) < 3600 then
                        sys.wait(500)
                        pm.reboot()
                    else
                        sys.wait(1000)
                        startTime4err = os.time()
                    end
                end
            else
                sys.wait(1000)
                startTime4err = os.time()
            end
            sys.wait(15000)
        end
    end
end)
