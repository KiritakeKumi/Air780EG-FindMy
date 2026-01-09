--[[
    Aprs4G by BG2LBF - 电源管理
]]
BATTERY_CHARGING = 0            -- 电池充放电状态 0：检测中  1：充电中  2：放电中
BATTERY_SOC = 0                 -- 电池剩余电量百分比
local longCb_id,singleCb_id
local isPowOff = false
local lastPressKey = 0     
-- 长按3s关机
local function longtimCerCb()
    isPowOff = true
    if aprscfg.TOTAL_MILEAGE_AUTOCLEAR == 1 then
        -- 里程归零
        if fskv.init() then
            fskv.set("TOTAL_MILEAGE", 0.0)
        end
    end
    sys.publish("POWER_OFF_VOICE")
end
-- 单击功能
local function singletimCerCb()
    if aprscfg.BTN_MODE == 1 then
        if aprscfg.TRACKERMODE == 1 then
            if aprscfg.LOCMODE == 1 then
                -- GPS
                sys.publish("SEND_APRS_NOW_GPS")
            elseif aprscfg.LOCMODE == 2 then
                -- LBS
                sys.publish("SEND_APRS_NOW_LBS")
            elseif aprscfg.LOCMODE == 3 then
                -- MIX_LOC
                if GPS_FIXED then
                    sys.publish("SEND_APRS_NOW_GPS")
                else
                    sys.publish("SEND_APRS_NOW_LBS")
                end
            else
                log.warn("SEND_APRS_NOW", "unknow")
            end
        elseif aprscfg.TRACKERMODE == 2 then
            -- 固定台
            sys.publish("SEND_APRS_NOW_FIXED")
        end
    elseif aprscfg.BTN_MODE == 2 then
    end
end
--进入静止休眠
local function sleepCb()
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
    elseif DEV_TYPE == "air780eg-yed" then
        pm.power(pm.GPS, false)
    end
    pm.power(pm.WORK_MODE, 3)
    -- pm.request(pm.HIB)
end
--进入关机
local function powOffCb()
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
    elseif DEV_TYPE == "air780eg-yed" then
        pm.power(pm.GPS, false)
    end
    pm.shutdown()
end
-- 初始化按钮 和  USB插入检测
local function initPWKCtl()
    if fskv.init() then
        if fskv.get("PWK_MODE") == 1 then
            pm.power(pm.PWK_MODE, true) -- 加入开机防抖，长按2s开机
        else
            pm.power(pm.PWK_MODE, false) 
        end
    end
    sys.wait(3000)
    -- powerKey检测
    gpio.setup(35, function()
        log.info("pwrkey", gpio.get(35))
        if gpio.get(35) == 1 then
            -- 松开key
            log.info("松开key")
            if not isPowOff then
                sys.timerStop(longCb_id)
                -- 判断是单击还是双击
                if (os.time() - lastPressKey) < 1 then
                    -- 双击
                    sys.timerStop(singleCb_id)
                    log.info("lastPressKey", "双击")
                    return
                end
                lastPressKey = os.time()
                singleCb_id = sys.timerStart(singletimCerCb, 1000)
                
            end
        elseif gpio.get(35) == 0 then
            -- 按下key
            longCb_id = sys.timerStart(longtimCerCb, 3000)
        end
    end, gpio.PULLUP)
    -- USB检测
    gpio.setup(33, function()
        log.info("USB-VBUS", gpio.get(33))
        if gpio.get(33) == 1 then
            BATTERY_CHARGING = 1
        elseif gpio.get(33) == 0 then
            BATTERY_CHARGING = 2
        end
    end, gpio.PULLUP)
  
end
-- 检查电池电量
local function checkPower()
    local battery0 = 3.2
    local battery10 = 3.6
    local battery50 = 3.8
    local battery80 = 4
    local battery100 = 4.2
    local curPower = string.gsub(ADC_CPU_VOL, "V", "")
    log.debug("checkPower", curPower)
    if tonumber(curPower) >= battery100 then
        return ((BATTERY_CHARGING == 1 and BATTERY_SOC < 100) or (BATTERY_CHARGING == 2 and BATTERY_SOC >= 100) or BATTERY_SOC == 0) and 100 or BATTERY_SOC
    elseif tonumber(curPower) >= battery80 then
        return ((BATTERY_CHARGING == 1 and BATTERY_SOC < 80) or (BATTERY_CHARGING == 2 and BATTERY_SOC >= 80) or BATTERY_SOC == 0) and 80 or BATTERY_SOC
    elseif tonumber(curPower) >= battery50 then
        return ((BATTERY_CHARGING == 1 and BATTERY_SOC < 50) or (BATTERY_CHARGING == 2 and BATTERY_SOC >= 50) or BATTERY_SOC == 0) and 50 or BATTERY_SOC
    elseif tonumber(curPower) >= battery10 then
        return ((BATTERY_CHARGING == 1 and BATTERY_SOC < 10) or (BATTERY_CHARGING == 2 and BATTERY_SOC >= 10) or BATTERY_SOC == 0) and 10 or BATTERY_SOC
    else
        return ((BATTERY_CHARGING == 1 and BATTERY_SOC < 5) or (BATTERY_CHARGING == 2 and BATTERY_SOC >= 5) or BATTERY_SOC == 0) and 5 or BATTERY_SOC
    end
end

sys.taskInit(function()
    log.info("UTC时间戳", os.time())
    
	if DEV_TYPE == "air700" then
        while true do
            -- 检查电池剩余电量百分比
            BATTERY_SOC = checkPower()
            BATTERY_CHARGING = (gpio.get(33) == 1) and 1 or 2
            log.info("BatterySOC", BATTERY_SOC, " - ", BATTERY_CHARGING)
            if BATTERY_CHARGING == 1 and BATTERY_SOC >= 100 then
                log.info("BATTERY_CHARGING", "已充满")
            elseif BATTERY_CHARGING == 0 and BATTERY_SOC == 5 then
            end
			sys.waitUntil("POWER_OFF_VOICE", 360000)
		end
	elseif DEV_TYPE == "air780e" then
        initPWKCtl()
        while true do
			if isPowOff then
                sys.wait(3000)
                powOffCb()
            end
            -- 检查电池剩余电量百分比
            BATTERY_SOC = checkPower()
            BATTERY_CHARGING = (gpio.get(33) == 1) and 1 or 2
            log.info("BatterySOC", BATTERY_SOC, " - ", BATTERY_CHARGING)
            if BATTERY_CHARGING == 1 and BATTERY_SOC >= 100 then
                log.info("BATTERY_CHARGING", "已充满")
            elseif BATTERY_CHARGING == 0 and BATTERY_SOC == 5 then
            end
			sys.waitUntil("POWER_OFF_VOICE", 360000)
		end
	elseif DEV_TYPE == "air780eg" then
		initPWKCtl()
        while true do
			if isPowOff then
                sys.wait(3000)
                powOffCb()
            end
            -- 检查电池剩余电量百分比
            BATTERY_SOC = checkPower()
            BATTERY_CHARGING = (gpio.get(33) == 1) and 1 or 2
            log.info("BatterySOC", BATTERY_SOC, " - ", BATTERY_CHARGING)
            if BATTERY_CHARGING == 1 and BATTERY_SOC >= 100 then
                log.info("BATTERY_CHARGING", "已充满")
            elseif BATTERY_CHARGING == 2 and BATTERY_SOC == 5 then
            end
			sys.waitUntil("POWER_OFF_VOICE", 360000)
		end
    elseif DEV_TYPE == "air780eg-yed" then
        -- 震动检测 
        gpio.setup(20, function(val) 
            log.info("发生震动", val)
        end, gpio.PULLUP, gpio.FALLING)
	end

end)

sys.subscribe("STATIC_STATE", function()
    if aprscfg.POWER_SAVE_MODE == 1 then
        if GPS_FIXED and (os.time() - GPS_RUNNING_TIME) < 600 then
            log.info("POW", "混合模式GPS已定位，跳过本次休眠")
        else
            sys.timerStart(sleepCb, 2000)
        end
    elseif aprscfg.POWER_SAVE_MODE == 3 then
        if GPS_FIXED and (os.time() - GPS_RUNNING_TIME) < 600 then
            log.info("POW", "混合模式GPS已定位，跳过本次关机")
        else
            sys.timerStart(powOffCb, 2000)
        end
    end
end)
