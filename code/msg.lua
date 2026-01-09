--[[
    Aprs4G by BG2LBF - APRS消息封装
]]
msgTab = {}
forwardMsgTab = {}
-- 里程数计数临时存储
local coordinates = {}
local imei, beaconTime, fullImei
-- 静止P  速度 0
local pTable, pSymbol = "\\", "P"
-- 自行车 速度 <15
local sTable, sSymbol = "/", "b"
-- 飞机蓝 速度 >100
local fTable, fSymbol = "\\", "^"
-- 飞机红 速度 >120
local f2Table, f2Symbol = "/", "^"

local t, s
-- 使用了百度地图api实现坐标转换，请自行替换成自己的AK
local function query_bd09(lng, lat)
    local x, y
    if mobile.status() == 1 then
        local code, headers, body = http.request("GET", "https://api.map.baidu.com/geoconv/v2/?coords="..lng..","..lat.."&model=2&ak="..BD_GEOCONV).wait()
        log.info("query_bd09", code )
        log.info("query_bd09", body )
        if code == 200 then
            local obj, result, err = json.decode(body)
            log.info("query_bd09", result )
            if result == 1 then
                log.info("query_bd09", obj.status)
                x = obj.result[1].x
                y = obj.result[1].y
            end
        end
    end
    return x, y
end

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

-- 坐标格式转换成DD.DDDDD格式
local function convertCoordinates(coord)
    local degrees = math.floor(coord / 100)
    local minutes = (coord - degrees * 100) / 60
    local result = degrees + minutes
    return string.format("%.5f", result)
end

-- 文字模板渲染
local function templateRendering(omsg, pointData)
    omsg = string.gsub(omsg, "${imei}", imei)
    omsg = string.gsub(omsg, "${rssi}", mobile.rssi())
    -- 当有卫星信息时才渲染
    if pointData ~= nil and pointData.satuse ~= nil and pointData.satview ~= nil then
        omsg = string.gsub(omsg, "${satuse}", pointData.satuse)
        omsg = string.gsub(omsg, "${sattotal}", pointData.satview)
    else
        omsg = string.gsub(omsg, "${satuse}", 0)
        omsg = string.gsub(omsg, "${sattotal}", 0)
    end
    omsg = string.gsub(omsg, "${temp}", ADC_CPU_TEMP)
    omsg = string.gsub(omsg, "${vol}", ADC_CPU_VOL)
    omsg = string.gsub(omsg, "${pow}", ADC_POWER_VOL)
    omsg = string.gsub(omsg, "${totalm}", string.format("%0.1f", aprscfg.TOTAL_MILEAGE))
    
    -- 当有古诗词时才渲染
    local found = string.find(omsg, "${shici_")
    if found then
        omsg = string.gsub(omsg, "${shici_content}", SHICI_MSG_CONTENT)
        omsg = string.gsub(omsg, "${shici_title}", SHICI_MSG_TITLE)
        omsg = string.gsub(omsg, "${shici_author}", SHICI_MSG_AUTHOR)
    end
    return omsg
end

-- aprs消息组装
local function point2msg(pointData)
    local pointTime, latT, lngT = os.date("*t", pointData.time), 'N', 'E'
    if pointData.lat < 0 then
        latT = 'S'
        pointData.lat = -pointData.lat
    end
    if pointData.lng < 0 then
        lngT = 'W'
        pointData.lng = -pointData.lng
    end

    local BD09 = ""
    if aprscfg.COORD_ENC == 1 then
        BD09 = " BD09"
        -- 需要将坐标转换成bd09坐标系
        local bdLng, bdLat = query_bd09(convertCoordinates(pointData.lng), convertCoordinates(pointData.lat))
        if bdLat and bdLng then
            pointData.lng = duToGpsDM(bdLng)
            pointData.lat = duToGpsDM(bdLat)
        else
            return
        end
    end

    if pointData.gps then
        -- GPS
        if aprscfg.TRICK_MODE == 1 then
            -- 调皮模式开启
            local curSpd = pointData.spd * 1.852
            if curSpd == 0 then
                -- 静止
                t = pTable
                s = pSymbol
            elseif curSpd < 20 then
                -- 自行车
                t = sTable
                s = sSymbol
            elseif curSpd >= 20 and curSpd < 90 then
                -- 正常
                t = aprscfg.TABLE
                s = aprscfg.SYMBOL
            elseif curSpd >= 90 and curSpd < 120 then
                -- 飞机蓝
                t = fTable
                s = fSymbol
            elseif curSpd >= 120 then
                -- 飞机红
                t = f2Table
                s = f2Symbol
            end
        end
        
        return string.format("%s>APRS4G:/%02d%02d%02dh%07.2f%s%s%08.2f%s%s%03d/%03d/A=%06d %s%s",
            aprscfg.sourceCall, pointTime.hour, pointTime.min, pointTime.sec, pointData.lat, latT, t, pointData.lng, lngT,
            s, pointData.cour, pointData.spd, pointData.alt, templateRendering(aprscfg.BEACON_TEXT, pointData), BD09)
    else
        -- LBS
        return string.format("%s>APRS4G:/%02d%02d%02dh%07.2f%s%s%08.2f%s%s %s%s",
        aprscfg.sourceCall, pointTime.hour, pointTime.min, pointTime.sec, pointData.lat, latT, aprscfg.TABLE, pointData.lng, lngT,
        aprscfg.SYMBOL, templateRendering(aprscfg.BEACON_TEXT, pointData), BD09)
    end
    
end
-- traccar消息组装
local function point2traccarmsg(pointData)
    return string.format(
        "?id=%s&lat=%s&lon=%s&speed=%s&altitude=%s&timestamp=%d&valid=true",
        fullImei,
        convertCoordinates(pointData.lat),
        convertCoordinates(pointData.lng),
        tostring(pointData.spd or 0),
        string.format("%.2f", (pointData.alt or 0) / 3.2808399),
        os.time()
    )
end

-- 转发的traccar消息组装
local function forwardpoint2traccarmsg(pointData)
    if aprscfg.SMS_CAT_ENABLE == 4 then
        return string.format(
            "?id=%s&lat=%s&lon=%s&speed=%s&altitude=%s&timestamp=%d&valid=true",
            fullImei,
            convertCoordinates(pointData.lat),
            convertCoordinates(pointData.lng),
            0,
            0,
            os.time()
        )
    else
        return string.format(
            "?id=%s&lat=%s&lon=%s&speed=%s&altitude=%s&timestamp=%d&valid=true",
            pointData.call,
            convertCoordinates(pointData.lat),
            convertCoordinates(pointData.lng),
            0,
            0,
            os.time()
        )
    end 
end
-- 转发的aprs消息组装
local function forwardpoint2msg(pointData)
    local pointTime, latT, lngT = os.date("*t", os.time()), 'N', 'E'
    if pointData.lat < 0 then
        latT = 'S'
        pointData.lat = -pointData.lat
    end
    if pointData.lng < 0 then
        lngT = 'W'
        pointData.lng = -pointData.lng
    end

    local BD09 = ""
    if aprscfg.COORD_ENC == 1 then
        BD09 = " BD09"
        -- 需要将坐标转换成bd09坐标系
        local bdLng, bdLat = query_bd09(convertCoordinates(pointData.lng), convertCoordinates(pointData.lat))
        if bdLat and bdLng then
            pointData.lng = duToGpsDM(bdLng)
            pointData.lat = duToGpsDM(bdLat)
        else
            return
        end
    end
    if aprscfg.SMS_CAT_ENABLE == 4 then
        return string.format("%s>APRS4G:/%02d%02d%02dh%07.2f%s%s%08.2f%s%s %s%s",
        aprscfg.sourceCall, pointTime.hour, pointTime.min, pointTime.sec, pointData.lat, latT, t,
        pointData.lng, lngT, s, aprscfg.BEACON_TEXT, BD09)
    else
        return string.format("%s>APRS4G,TCPIP*,qAS,%s:/%02d%02d%02dh%07.2f%s%s%08.2f%s%s %s%s",
        pointData.call, aprscfg.sourceCall, pointTime.hour, pointTime.min, pointTime.sec, pointData.lat, latT, pointData.t,
        pointData.lng, lngT, pointData.s, pointData.msg, BD09)
    end 
    
end
-- 计算坐标点间距离
local function calculateDistance(coordinates)
    local earthRadius = 6371 -- 地球半径（单位：公里）
    local function toRadians(degree)
        return degree * (math.pi / 180)
    end
    local function calculateHaversine(lat1, lon1, lat2, lon2)
        local dLat = toRadians(lat2 - lat1)
        local dLon = toRadians(lon2 - lon1)

        local a = math.sin(dLat / 2) * math.sin(dLat / 2) +
                  math.cos(toRadians(lat1)) * math.cos(toRadians(lat2)) *
                  math.sin(dLon / 2) * math.sin(dLon / 2)
        local c = 2 * math.asin(math.sqrt(a))

        return earthRadius * c
    end
    local totalDistance = 0
    for i = 2, #coordinates do
        local lat1 = coordinates[i - 1][1]
        local lon1 = coordinates[i - 1][2]
        local lat2 = coordinates[i][1]
        local lon2 = coordinates[i][2]

        totalDistance = totalDistance + calculateHaversine(lat1, lon1, lat2, lon2)
    end
    return totalDistance
end

sys.taskInit(function()
    sys.waitUntil("LOGGED_IN")
    imei = string.sub(mobile.imei(), -3, -1)
    fullImei = mobile.imei()

    t = aprscfg.TABLE
    s = aprscfg.SYMBOL
    beaconTime = os.time()

    local hasFsKV = false
    if not fskv then
        while true do
            log.error("fskv", "this app need fskv")
            sys.wait(1000)
        end
    end
    -- 初始化kv数据库
    if fskv.init() then
        hasFsKV = true
        log.info("fskv", "init complete")
    end
    while true do
        local isRemoveMsg = false
        local isRemoveForwardMsg = false
        if aprscfg.PLAT == 0 or aprscfg.PLAT == 1 then
            -- APRS 上送
            if aprscfg.BEACON_STATUS_INTERVAL ~= 0 and os.time() - beaconTime >= aprscfg.BEACON_STATUS_INTERVAL then
                local beaconMsg = ""
                if aprscfg.DISPLAY_VER == 1 then
                    beaconMsg = string.format("%s>APRS4G:>%s %s", aprscfg.sourceCall, templateRendering(aprscfg.BEACON), VERSION)
                else
                    beaconMsg = string.format("%s>APRS4G:>%s", aprscfg.sourceCall, templateRendering(aprscfg.BEACON))
                end
                beaconTime = os.time()
                if aprscfg.PLAT_SENDSELF == 1 then
                    sys.publish("SEND_APRS_MSG", beaconMsg)
                    sys.wait(500)
                end
            end
            if msgTab and #msgTab > 0 then
                -- 累加里程数
                table.insert(coordinates, {convertCoordinates(msgTab[1].lat), convertCoordinates(msgTab[1].lng)})
                if #coordinates > 2 then
                    table.remove(coordinates, 1)
                end
                if #coordinates == 2 then
                    aprscfg.TOTAL_MILEAGE = aprscfg.TOTAL_MILEAGE + tonumber(string.format("%02.4f", calculateDistance(coordinates)))
                    if hasFsKV then
                        fskv.set("TOTAL_MILEAGE", aprscfg.TOTAL_MILEAGE)
                    end
                end

                sys.publish("SEND_APRS_MSG", point2msg(msgTab[1]))
                isRemoveMsg = true
            end
            if forwardMsgTab and #forwardMsgTab > 0 then
                sys.publish("SEND_APRS_MSG", forwardpoint2msg(forwardMsgTab[1]))
                isRemoveForwardMsg = true
            end
        end
        if aprscfg.PLAT == 0 or aprscfg.PLAT == 2 then
            -- TRACCAR 上送
            if msgTab and #msgTab > 0 then
                sys.publish("SEND_TRACCAR_MSG", point2traccarmsg(msgTab[1]))
                isRemoveMsg = true
            end
            if forwardMsgTab and #forwardMsgTab > 0 then
                sys.publish("SEND_TRACCAR_MSG", forwardpoint2traccarmsg(forwardMsgTab[1]))
                isRemoveForwardMsg = true
            end
        end

        if isRemoveMsg then
            table.remove(msgTab, 1)
        end
        if isRemoveForwardMsg then
            table.remove(forwardMsgTab, 1)
        end
        sys.wait(1000)
    end
end)
