--[[
    Aprs4G by BG2LBF - GPS定位数据
]]
local MIN_COURSE = 20			-- 最小航向为20
local MIN_RUNSPD = 3			-- 最小行驶速度为3
local MIN_INTERVAL = 15		    -- 最小间隔为15s
local MAX_INTERVAL = 60		    -- 最大间隔为60s
local STOP_INTERVAL = 60		-- 静止间隔为60s

local gps_uart_id = 2
local gpsDataOld
local reason = 0

local currentDecayValue = 0     -- 当前衰减值
local decayRate = 2             -- 衰减率为2
local maxDecayTimes = 32        -- 最大衰减倍数
local decayFunc
local beaconstatusinterval = 600

local agnsstime = 0
local agnsslimit = 3600       -- 最快1小时更新一次

local gpsEnable = false
local gpsTable = {}
GPS_FIXED = false
GPS_RUNNING_TIME = 0

local sendAprsNow = false       -- 立即发送位置
-- 启用agnss辅助定位
local function exec_agnss()
    if http then
        -- AGNSS 已调通
        while 1 do
            log.info("os.time():", os.time());
            log.info("agnsstime:", agnsstime);
            log.info("agnsslimit:", agnsslimit);
            if (os.time() - agnsstime) > agnsslimit then 
                -- 网络加载
                local code, headers, body = http.request("GET", "http://download.openluat.com/9501-xingli/HXXT_GPS_BDS_AGNSS_DATA.dat").wait()
                log.info("gnss", "AGNSS", code, body and #body or 0)
                if code == 200 and body and #body > 1024 then
                    for offset=1,#body,512 do
                        log.info("gnss", "AGNSS", "write >>>", #body:sub(offset, offset + 511))
                        uart.write(gps_uart_id, body:sub(offset, offset + 511))
                        sys.wait(100) -- 等100ms反而更成功
                    end
                    io.writeFile("/6228.bin", body)
                    agnsstime = os.time()
                    fskv.set("agnsstime", agnsstime)
                    break
                end
            else
                -- 本地加载
                local body6628 = io.readFile("/6228.bin")
                if body6628 and #body6628 > 1024 then
                    for offset=1,#body6628,512 do
                        log.info("gnss", "AGNSS", "loc write >>>", #body6628:sub(offset, offset + 511))
                        uart.write(gps_uart_id, body6628:sub(offset, offset + 511))
                        sys.wait(100) -- 等100ms反而更成功
                    end
                    break
                end
            end
            sys.wait(60*1000)
        end
    end
    sys.wait(20)
    -- "$AIDTIME,year,month,day,hour,minute,second,millisecond"
    local date = os.date("!*t")
    if date.year > 2022 then
        local str = string.format("$AIDTIME,%d,%d,%d,%d,%d,%d,000", 
                         date["year"], date["month"], date["day"], date["hour"], date["min"], date["sec"])
        log.info("gnss", str)
        uart.write(gps_uart_id, str .. "\r\n") 
        sys.wait(20)
    end
end
-- 初始化GPS
local function initGps()
    log.info("initGps")
    libgnss.clear() -- 清空数据,兼初始化
    if DEV_TYPE == "air700" then
        uart.setup(gps_uart_id, 9600)
	    gpio.setup(29, 1, gpio.PULLUP)  -- GPS使能 ，请根据实际情况设置
    elseif DEV_TYPE == "air780e" then
        uart.setup(gps_uart_id, 9600)
	    gpio.setup(25, 1, gpio.PULLUP)  -- GPS使能 ，请根据实际情况设置
    elseif DEV_TYPE == "air780eg" then
        uart.setup(gps_uart_id, 115200)
	    pm.power(pm.GPS, true)          -- GPS使能 ，请根据实际情况设置
    elseif DEV_TYPE == "air780eg-yed" then
        uart.setup(gps_uart_id, 115200)
	    pm.power(pm.GPS, true)          -- GPS使能 ，请根据实际情况设置
    end
	
	libgnss.debug(false)
	sys.wait(1000)               -- GPNSS芯片启动需要时间,大概150ms
	libgnss.rtcAuto(true)       -- 定位成功后,使用GNSS时间设置RTC
	libgnss.bind(gps_uart_id)   -- 绑定uart,底层自动处理GNSS数据

    if aprscfg.AGNSS_ENABLE == 1 then
        exec_agnss()
    end

    
    gpsEnable = true
end

-- 关闭GPS
local function colseGps()
    log.info("colseGps")
    if DEV_TYPE == "air700" then
	    gpio.set(29, 0)                 -- 关闭GPS ，请根据实际情况设置
    elseif DEV_TYPE == "air780e" then
	    gpio.set(25, 0)                 -- 关闭GPS ，请根据实际情况设置
    elseif DEV_TYPE == "air780eg" then
	    pm.power(pm.GPS, false)         -- 关闭GPS ，请根据实际情况设置
    elseif DEV_TYPE == "air780eg-yed" then
	    pm.power(pm.GPS, false)         -- 关闭GPS ，请根据实际情况设置
    end
    gpsEnable = false
end

-- 发射间隔衰减计算，衰减率为2,最大衰减倍数32
local function calcDecay(initialValue)  
    currentDecayValue = initialValue  
    return function()  
        local oldValue = currentDecayValue  
        if currentDecayValue < initialValue * maxDecayTimes then
            currentDecayValue = currentDecayValue * decayRate              
        end
        return oldValue  
    end  
end 
-- 重置衰减值
local function resetDecay()
    currentDecayValue = MAX_INTERVAL
    STOP_INTERVAL = MAX_INTERVAL
    aprscfg.BEACON_STATUS_INTERVAL = beaconstatusinterval
end

-- 角度计算
local function courseDiff(new, old)
    if not new or not old or new > 359 or new < 0 or old > 359 or old < 0 then
        return 0
    end
    local diff = math.abs(new - old)
    if diff > 180 then
        diff = 360 - diff
    end
    return diff
end

-- GPS数据读取封装
local function gpsProcess()
    if not gpsEnable then
        sys.wait(10000)
        return
    end
    if not libgnss.isFix() then
        sys.wait(10000)
        return
    else

		local rmc = libgnss.getRmc(0)
		local gga = libgnss.getGga(2)
		local gsv = libgnss.getGsv()

        local gpsData = {}
        gpsData.lat = tonumber(rmc.lat)		                        -- 纬度
        gpsData.lng = tonumber(rmc.lng)		                        -- 经度
        gpsData.spd = math.floor(rmc.speed)	                        -- 速度
        gpsData.cour = math.floor(rmc.course)		                -- 航向variation
        gpsData.alt = math.floor(gga.altitude * 3.2808399)			-- 海拔
        gpsData.hdop = tonumber(gga.hdop)                           -- 位置精度
        gpsData.satuse =tonumber(gga.satellites_tracked)			-- 参与定位的卫星数量
        gpsData.satview = tonumber(gsv.total_sats)				    -- 总可见卫星数量
		gpsData.time = os.time()                                    -- 时间
		gpsData.lngT = gpsData.lng >= 0 and "E" or "W"		        -- 判断经度的方向
		gpsData.latT = gpsData.lat >= 0 and "N" or "S"		        -- 判断纬度的方向
        gpsData.gps = true;

        if gpsData.spd > 0 then
            GPS_RUNNING_TIME = os.time()
        end
        

        -- fix 可见数量大于参与定位数量的问题
        if gpsData.satuse > gpsData.satview then
            gpsData.satview = gpsData.satuse
        end
        if not gpsDataOld then
            table.insert(msgTab, gpsData)
            gpsDataOld = gpsData
        elseif sendAprsNow then
            sendAprsNow = false
            table.insert(msgTab, gpsData)
            log.info("APRS", "立即发送APRS")
            gpsDataOld = gpsData
            reason = 0
        else
            if gpsData.spd > MIN_RUNSPD  then
                if courseDiff(gpsData.cour, gpsDataOld.cour) >= MIN_COURSE then		--最小航向
                    resetDecay()
                    reason = bit.bor(reason, 1)
					log.info("APRS", "已满足最小航向触发条件")
                end
                if	gpsData.time - gpsDataOld.time >= MAX_INTERVAL then				--最大间隔
                    resetDecay()
                    reason = bit.bor(reason, 2)
					log.info("APRS", "已满足最大时间间隔触发条件")
                end
            elseif	gpsData.time - gpsDataOld.time >= STOP_INTERVAL then		-- 停止间隔
                -- 静止，开始衰减，增加 停止间隔
                STOP_INTERVAL = decayFunc()
                if STOP_INTERVAL > aprscfg.BEACON_STATUS_INTERVAL then
                    aprscfg.BEACON_STATUS_INTERVAL = STOP_INTERVAL
                end
                reason = bit.bor(reason, 4)
				log.info("APRS", "已满足静止时间间隔触发条件")
            end
            if reason > 0 and gpsData.time - gpsDataOld.time >= MIN_INTERVAL then	--最小间隔
                table.insert(msgTab, gpsData)
				log.info("APRS", "已满足最小时间间隔触发条件")
                gpsDataOld = gpsData
                reason = 0
            end
        end
    end
end

sys.taskInit(function()
    sys.waitUntil("LOC_GPS")
    sys.wait(200)
    if fskv.init() then
        local _agnsstime = fskv.get("agnsstime")
        log.warn("_agnsstime:",_agnsstime)
        if _agnsstime == nil then
            _agnsstime = "0"
        end
        agnsstime = tonumber(_agnsstime)
        -- if agnsstime <= 0 then
        --     agnsstime = os.time()
        -- end
    end
    if aprscfg.PLAT_SENDSELF == 0 then
        return
    end

    if aprscfg.TRAVEL_MODE == 0 then
        MIN_RUNSPD = 3
    elseif aprscfg.TRAVEL_MODE == 1 then
        MIN_RUNSPD = 1
    end

    beaconstatusinterval = aprscfg.BEACON_STATUS_INTERVAL
    MAX_INTERVAL = aprscfg.BEACON_INTERVAL
    maxDecayTimes = aprscfg.MAX_DECAY
    STOP_INTERVAL = MAX_INTERVAL
    -- 初始化衰减算法
    decayFunc = calcDecay(STOP_INTERVAL)

    initGps()
    log.info("GPS模块", "初始化完成,正在定位")
    -- sys.waitUntil("LOC_GPS_FIXED")
    -- log.info("GPS模块", "已经定位")
    while true do
        if #gpsTable > 0 then
            if gpsTable[1] == "LAST1MINS_STATIC_STATE_CLOSEGPS" then
                colseGps()
            elseif gpsTable[1] == "LAST1MINS_STATIC_STATE_INITGPS" then
                initGps()
            end
            table.remove(gpsTable, 1)
        end
        gpsProcess()
        sys.wait(1000)
    end
end)

sys.taskInit(function()
    while aprscfg.AGNSS_ENABLE == 1 and gpsEnable do
        sys.wait(2*3600*1000) -- 2??????AGNSS
        local fixed, time_fixed = libgnss.isFix()
        if not fixed then
            exec_agnss()
        end
    end
end)

-- ??:?30???????GPS????
sys.taskInit(function()
    sys.waitUntil("LOC_GPS")
    while true do
        if libgnss.isFix() then
            local rmc = libgnss.getRmc(0) or {}
            local gga = libgnss.getGga(2) or {}
            local gsv = libgnss.getGsv() or {}
            log.info("GPS_DEBUG", string.format("lat:%s lng:%s spd:%s cour:%s alt:%s hdop:%s satuse:%s satview:%s", tostring(rmc.lat), tostring(rmc.lng), tostring(rmc.speed), tostring(rmc.course), tostring(gga.altitude), tostring(gga.hdop), tostring(gga.satellites_tracked), tostring(gsv.total_sats or "")))
        else
            log.info("GPS_DEBUG", "not fixed")
        end
        sys.wait(30000)
    end
end)
sys.subscribe("GNSS_STATE", function(event, ticks)
    -- event取值有
    -- FIXED 定位成功
    -- LOSE  定位丢失
    -- ticks是事件发生的时间,一般可以忽略
    log.info("gnss", "state", event, ticks)
    if event == "FIXED" then
        -- 定位成功
        GPS_FIXED = true
        sys.publish("LOC_GPS_FIXED")
    else
        GPS_FIXED = false
        sys.publish("LOC_GPS_LOSE")
    end
end)

-- sys.subscribe("LAST1MINS_STATIC_STATE", function()
--     -- 低功耗模式 近期姿态改变
--     if aprscfg.POWER_SAVE_MODE == 1 then
--         log.info("gpsEnable", gpsEnable)
--         -- 省电模式  查看是否静止超过5分钟
--         if LAST1MINS_STATIC_STATE == 1 and gpsEnable then
--             -- 近期静止，关闭GPS
--             table.insert(gpsTable, "LAST1MINS_STATIC_STATE_CLOSEGPS")
--         elseif LAST1MINS_STATIC_STATE == 0 and not gpsEnable then
--             table.insert(gpsTable, "LAST1MINS_STATIC_STATE_INITGPS")
--         end 
--     end
-- end)
sys.subscribe("POS_STATE_INITGPS", function()
    table.insert(gpsTable, "LAST1MINS_STATIC_STATE_INITGPS")
    log.info("POS", "POS_STATE_INITGPS")
end)
sys.subscribe("POS_STATE_CLOSEGPS", function()
    table.insert(gpsTable, "LAST1MINS_STATIC_STATE_CLOSEGPS")
end)
sys.subscribe("SEND_APRS_NOW_GPS", function()
    sendAprsNow = true
end)
