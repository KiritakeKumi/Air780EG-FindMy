--[[
    Aprs4G by BG2LBF - 固定台站
]]

sys.taskInit(function()
    sys.waitUntil("LOC_USER_FIXED")

    if aprscfg.PLAT_SENDSELF == 0 then
        return
    end
    
    log.info("loc", "固定坐标台站")
    while true do
        local gpsData = {}
        gpsData.lat = aprscfg.FIXLOC_LAT	                -- 纬度
        gpsData.lng = aprscfg.FIXLOC_LNG	                -- 经度
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

        sys.waitUntil("SEND_LOC_USER_FIXED_NOW", aprscfg.BEACON_INTERVAL * 1000)
    end
end)

sys.subscribe("SEND_APRS_NOW_FIXED", function()
    sys.publish("SEND_LOC_USER_FIXED_NOW")
end)