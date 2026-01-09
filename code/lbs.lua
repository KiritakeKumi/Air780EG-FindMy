--[[
    Aprs4G by BG2LBF - 基站数据
]]
local lbsLoc2 = require("lbsLoc2")

local lbsEnable = true

-- 坐标格式转换成ddmm.mmmm格式
local function duToGpsDM(duStr)
    local du = tonumber(duStr)
    if du then
        local isNegative = du < 0 -- 判断是否为负数，即南纬或西经
        local degrees = math.floor(math.abs(du))
        local minutes = (math.abs(du) - degrees) * 60
        local result = degrees * 100 + minutes
        if isNegative then
            result = -result -- 负数表示南纬或西经，将结果设为负数
        end
        return string.format("%.2f", result)
    else
        return "0"
    end
end

local function lbsProcess()
    if mobile and lbsEnable then
        mobile.reqCellInfo(15)
        sys.waitUntil("CELL_INFO_UPDATE", 30000)
        local lat, lng, t = lbsLoc2.request(5000)
        if lat then
            
            log.info("UTC时间戳", os.time())
            local gpsData = {}
            gpsData.lat = tonumber(duToGpsDM(lat))	            -- 纬度
            gpsData.lng = tonumber(duToGpsDM(lng))	            -- 经度
            gpsData.spd = 0	                                    -- 速度
            gpsData.cour = 0		                            -- 航向
            gpsData.alt = 0			                            -- 海拔
            gpsData.hdop = 0                                    -- 位置精度
            gpsData.satuse = 0			                        -- 参与定位的卫星数量
            gpsData.satview = 0				                    -- 总可见卫星数量
            gpsData.time = os.time()                            -- 时间
            gpsData.lngT = gpsData.lng >= 0 and "E" or "W"		-- 判断经度的方向
            gpsData.latT = gpsData.lat >= 0 and "N" or "S"		-- 判断纬度的方向
            gpsData.gps = false;
    
            table.insert(msgTab, gpsData)
            if aprscfg.LOCMODE ~= 3 then
                sys.publish("LOC_LBS_FIXED")
            end
        else
            if aprscfg.LOCMODE ~= 3 then
                sys.publish("LOC_LBS_LOSE")
            end
            
        end
        
        log.info("lbsLoc2", lat, lng, (json.encode(t or {})))
        sys.waitUntil("SEND_LOC_LBS_NOW", aprscfg.BEACON_INTERVAL * 1000)
    end
end

sys.taskInit(function()
    sys.waitUntil("LOC_LBS")

    if aprscfg.PLAT_SENDSELF == 0 then
        return
    end
    
    while true do
        lbsProcess()
        sys.wait(3000)
    end
end)

sys.subscribe("POS_STATE_INITLBS", function()
    lbsEnable = true
    log.info("LBS", "POS_STATE_INITLBS")
end)
sys.subscribe("POS_STATE_CLOSELBS", function()
    lbsEnable = false
end)

sys.subscribe("SEND_APRS_NOW_LBS", function()
    sys.publish("SEND_LOC_LBS_NOW")
end)