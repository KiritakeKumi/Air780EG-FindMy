--[[
    Aprs4G by BG2LBF - 短信指令 - 短信猫 短信转发器
]]
local toBeSentSMS = {}


-- 解析网页中的坐标信息 -- 海聊
function parseLastCoordinate(text)
    local coordinates = {}
    local pattern = "latitude=(%-?%d+%.%d+)&longitude=(%-?%d+%.%d+)"
    local latitude, longitude
    for lat, lon in text:gmatch(pattern) do
        latitude = lat
        longitude = lon
    end
    if latitude and longitude then
        table.insert(coordinates, longitude)
        table.insert(coordinates, latitude)
    end
    return coordinates
end
-- 从文本中解析出网站地址 -- 海聊
local function parseWebsite(text)
    local pattern = "(http[s]?://%S+)"
    local website = string.match(text, pattern)
    return website
end
-- 坐标格式转换
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
-- 解析文本中的5字段呼号、经纬度信息
local function parsingtext(text)
    local coordinates = {}

    local callpattern = "C%[(.-)%]"
    local call = text:match(callpattern)
    if call then
        table.insert(coordinates, call)
    else
        return coordinates
    end
    local iconpattern = "I%[(.-)%]"
    local icon = text:match(iconpattern)
    if icon then
        table.insert(coordinates, string.char(tonumber(icon:sub(1, 2), 16)))
        table.insert(coordinates, string.char(tonumber(icon:sub(3, 4), 16)))
    else
        return coordinates
    end
    local msgpattern = "M%[(.-)%]"
    local msg = text:match(msgpattern)
    if msg then
        table.insert(coordinates, msg)
    else
        return coordinates
    end

    local pattern = "([%-]?%d+°%d+'%d+%.?%d*%\")"
    for match in text:gmatch(pattern) do
        local degrees, minutes, seconds = match:match("([%-]?%d+)°(%d+)'(%d+%.?%d*)\"")
        local coordinate = tonumber(degrees) + tonumber(minutes)/60 + tonumber(seconds)/3600
        table.insert(coordinates, coordinate)
    end
    
    return coordinates
end
-- 解析文本中的2字段经纬度信息-神州天鸿
local function parsingtext2(text)
    local coordinates = {}
    local pattern = "([%-]?%d+°%d+'%d+%.?%d*%\")"
    for match in text:gmatch(pattern) do
        local degrees, minutes, seconds = match:match("([%-]?%d+)°(%d+)'(%d+%.?%d*)\"")
        local coordinate = tonumber(degrees) + tonumber(minutes)/60 + tonumber(seconds)/3600
        table.insert(coordinates, coordinate)
    end
    return coordinates
end
-- 解析文本中的2字段经纬度信息-北斗短信-天汇
function parsingtext2bd(text)
    local coordinates = {}
    local pattern = "#P%[(-?%d+%.%d+),(-?%d+%.%d+)%]"
    local latitude, longitude = string.match(text, pattern)
    table.insert(coordinates, longitude)
    table.insert(coordinates, latitude)
    return coordinates
end
-- 解析文本中的2字段经纬度信息-海聊
local function parsingtext2hl(text)
    local coordinates = {}
    local website = parseWebsite(text)
    local code, headers, body = http.request("GET", website).wait()
    log.info("hailiao1", code)
    if code == 302 then
        code, headers, body = http.request("GET", headers.Location).wait()
        log.info("hailiao2", code)
        if code == 200 then
            coordinates = parseLastCoordinate(body)
        end
    end
    return coordinates
end
-- 验证码计算
local function pwdCal(callin)
    local call = string.upper(callin)
    local hash = 0x73e2
    local i = 1
    while i <= string.len(call) do
        hash = bit.bxor(hash, string.byte(call, i) * 0x100)
        i = i + 1
        if i <= string.len(call) then
            hash = bit.bxor(hash, string.byte(call, i))
            i = i + 1
        end
    end
    hash = bit.band(hash, 0x7fff)
    return hash
end

-- 校验服务器地址
local function JudgeIPString(ipStr)
    if type(ipStr) ~= "string" then
        return false;
    end
    local len = string.len(ipStr);
    if len < 7 or len > 15 then
        return false;
    end
    local point = string.find(ipStr, "%p", 1);
    local pointNum = 0;
    while point ~= nil do
        if string.sub(ipStr, point, point) ~= "." then
            return false;
        end
        pointNum = pointNum + 1;
        point = string.find(ipStr, "%p", point + 1);
        if pointNum > 3 then
            return false;
        end
    end
    if pointNum ~= 3 then
        return false;
    end
    local num = {};
    for w in string.gmatch(ipStr, "%d+") do
        num[#num + 1] = w;
        local kk = tonumber(w);
        if kk == nil or kk > 255 then
            return false;
        end
    end
    if #num ~= 4 then
        return false;
    end
    return ipStr;
end

-- 获取字符串长度
local function utf8len(input)
    local len  = string.len(input)
    local left = len
    local cnt  = 0
    local arr  = {0, 0xc0, 0xe0, 0xf0, 0xf8, 0xfc}
    while left ~= 0 do
      local tmp = string.byte(input, -left)
      local i   = #arr
      while arr[i] do
        if tmp >= arr[i] then
          left = left - i
          break
        end
        i = i - 1
      end
      cnt = cnt + 1
    end
    return cnt
end

-- 更改其他平台参数 暂无
local function gpsCmd(result)

end

-- 更改aprs参数
local function aprsCmd(result)
    if (#result - 2) > 0 and (#result - 2)%2 == 0 then
        if fskv.init() then
            log.info("fskv", "init complete")
        end
        for i = 2,(#result - 2),2  do
            log.info("短信指令：%s-%s", result[i], result[i+1])
            if "CALLSIGN" == result[i] then
                if not result[i+1] then
                    log.error("配置校验", "呼号未设置")
                    goto continue
                else
                    result[i+1] = string.upper(result[i+1])
                    if not (result[i+1]:match('^[1-9]%u%u?%d%u%u?%u?%u?$') or
                        result[i+1]:match('^%u[2-9A-Z]?%d%u%u?%u?%u?$')) then
                        log.error("配置校验", "呼号不合法")
                        goto continue
                    end
                    if string.len(result[i+1]) < 3 or string.len(result[i+1]) > 7 then
                        log.error("配置校验", "呼号长度需要在 3-7 个字符")
                        goto continue
                    end
                    fskv.set(result[i], result[i+1])
                end
            elseif "PASSCODE" == result[i] then
                if not result[i+1] then
                    log.error("配置校验", "验证码未设置")
                    goto continue
                else
                    local pscode = pwdCal(result[i+1])
                    if not tonumber(result[i+1]) or tonumber(result[i+1]) ~= pscode then
                        log.error("配置校验", "验证码错误")
                        goto continue
                    end
                    fskv.set(result[i], result[i+1])
                end
            elseif "SSID" == result[i] then
                if result[i+1] then
                    result[i+1] = string.upper(result[i+1])
                    if not (result[i+1]:match('^%d%u?$') or result[i+1]:match('^[1][0-5]$') or result[i+1]:match('^%u%w?$')) then
                        log.error("配置校验",
                            "SSID不合法，只能是1-2个字母、数字；如果是2位数字，则不可以大于15")
                            goto continue
                    end
                    if string.len(aprscfg.CALLSIGN) + string.len(result[i+1]) > 8 then
                        log.error("配置校验", "呼号+SSID的总长度不能超过8个字符")
                        goto continue
                    end
                    fskv.set(result[i], result[i+1])
                end
            elseif "SERVER" == result[i] then
                if result[i+1] then
                    if not (result[i+1]:match('%.*%w[%w%-]*%.%a%a%a?%a?%a?%a?$') or JudgeIPString(result[i+1])) then
                        log.error("配置校验", "服务器地址非法")
                        goto continue
                    end
                    fskv.set(result[i], result[i+1])
                end
            elseif "PORT" == result[i] then
                if result[i+1] then
                    local portTmp = tonumber(result[i+1])
                    if not portTmp or portTmp < 1024 or portTmp > 49151 then
                        log.error("配置校验", "端口号非法，需要1024-49151之间")
                        goto continue
                    end
                    fskv.set(result[i], result[i+1])
                end
            elseif "TABLE" == result[i] then
                if result[i+1] then
                    result[i+1] = string.upper(result[i+1])
                    if not result[i+1]:match('^[/\\2DEGIRY]$') then
                        log.error("配置校验", "TABLE设置错误")
                        goto continue
                    end
                    fskv.set(result[i], result[i+1])
                end
            elseif "SYMBOL" == result[i] then
                if result[i+1] then
                    if not result[i+1]:match('^[%w%p]$') then
                        log.error("配置校验", "SYMBOL设置错误")
                        goto continue
                    end
                    fskv.set(result[i], result[i+1])
                end
            elseif "BEACON" == result[i] then
                if result[i+1] then
                    if utf8len(result[i+1]) > 100 then
                        log.error("配置校验", "BEACON长度过长，最大100个字符")
                        goto continue
                    end
                    fskv.set(result[i], result[i+1])
                end
            elseif "BEACON_TEXT" == result[i] then
                if result[i+1] then
                    if utf8len(result[i+1]) > 200 then
                        log.error("配置校验", "BEACON_TEXT长度过长，最大200个字符")
                        goto continue
                    end
                    fskv.set(result[i], result[i+1])
                end
            elseif "BEACON_INTERVAL" == result[i] then
                if result[i+1] then
                    local v = tonumber(result[i+1])
                    if not v or ((v < 10 or v > 1*60*60) and v ~= 0) then
                        log.error("配置校验", "BEACON_INTERVAL错误，正确范围为10秒-1小时")
                        goto continue
                    end
                    fskv.set(result[i], result[i+1])
                end
            elseif "BEACON_STATUS_INTERVAL" == result[i] then
                if result[i+1] then
                    local v = tonumber(result[i+1])
                    if not v or ((v < 60 or v >  24*60*60) and v ~= 0) then
                        log.error("配置校验", "BEACON_STATUS_INTERVAL错误，正确范围为60秒-24小时")
                        return false
                    end
                    fskv.set(result[i], result[i+1])
                end
            elseif "TRACKERMODE" == result[i] then
                if result[i+1] then
                    local v = tonumber(result[i+1])
                    if not v and v < 1 or v > 2 then
                        log.error("配置校验", "TRACKERMODE 错误，只能配置为 1 至 2 ")
                        return false
                    end
                    fskv.set(result[i], result[i+1])
                end
            elseif "FIXLOC_LAT" == result[i] then
                if result[i+1] then
                    local v = tonumber(result[i+1])
                    if not v then
                        log.error("配置校验", "FIXLOC_LAT 错误，只能是数字 ")
                        return false
                    end
                    fskv.set(result[i], result[i+1])
                end
            elseif "FIXLOC_LNG" == result[i] then
                if result[i+1] then
                    local v = tonumber(result[i+1])
                    if not v then
                        log.error("配置校验", "FIXLOC_LNG 错误，只能是数字 ")
                        return false
                    end
                    fskv.set(result[i], result[i+1])
                end
            elseif "LOCMODE" == result[i] then
                if result[i+1] then
                    if tonumber(result[i+1]) < 1 or tonumber(result[i+1]) > 4 then
                        log.error("配置校验", "LOCMODE 错误，只能配置为 1 至 4 ")
                        goto continue
                    end
                    fskv.set(result[i], tonumber(result[i+1]))
                end
            elseif "TRACCAR_HOST" == result[i] then
                if result[i+1]:len() > 100 then
                    log.error("配置校验", "TRACCAR_HOST长度过长，最大100个字符")
                    return false
                end
                fskv.set(result[i], result[i+1])
            elseif "PLAT" == result[i] then
                if result[i+1] then
                    if tonumber(result[i+1]) < 0 or tonumber(result[i+1]) > 2 then
                        log.error("配置校验", "PLAT 错误，只能配置为 0 至 2 ")
                        goto continue
                    end
                    fskv.set(result[i], tonumber(result[i+1]))
                end
            elseif "PLAT_SENDSELF" == result[i] then
                if result[i+1] then
                    if tonumber(result[i+1]) < 0 or tonumber(result[i+1]) > 1 then
                        log.error("配置校验", "PLAT_SENDSELF 错误，只能配置为 0 至 1 ")
                        goto continue
                    end
                    fskv.set(result[i], tonumber(result[i+1]))
                end
            elseif "WEBCMD_HOST" == result[i] then
                if result[i+1]:len() > 100 then
                    log.error("配置校验", "WEBCMD_HOST长度过长，最大100个字符")
                    return false
                end
                fskv.set(result[i], result[i+1])
            elseif "MAX_DECAY" == result[i] then
                local v = tonumber(result[i+1])
                if not v then
                    log.error("配置校验", "MAX_DECAY 错误，只能是数字 ")
                    return false
                end
                if v < 1 or v > 32 then
                    log.error("配置校验", "MAX_DECAY 错误，只能配置为 1 至 32 ")
                    return false
                end
                fskv.set(result[i], result[i+1])
            elseif "TRICK_MODE" == result[i] then
                if result[i+1] then
                    if tonumber(result[i+1]) < 0 or tonumber(result[i+1]) > 1 then
                        log.error("配置校验", "TRICK_MODE 错误，只能配置为 0 至 1 ")
                        goto continue
                    end
                    fskv.set(result[i], tonumber(result[i+1]))
                end
            elseif "AGNSS_ENABLE" == result[i] then
                if result[i+1] then
                    if tonumber(result[i+1]) < 0 or tonumber(result[i+1]) > 1 then
                        log.error("配置校验", "AGNSS_ENABLE 错误，只能配置为 0 至 1 ")
                        goto continue
                    end
                    fskv.set(result[i], tonumber(result[i+1]))
                end
            elseif "AUDIO_ENABLE" == result[i] then
                if result[i+1] then
                    if tonumber(result[i+1]) < 0 or tonumber(result[i+1]) > 1 then
                        log.error("配置校验", "AUDIO_ENABLE 错误，只能配置为 0 至 1 ")
                        goto continue
                    end
                    fskv.set(result[i], tonumber(result[i+1]))
                end
            elseif "AUDIO_VOL" == result[i] then
                if result[i+1] then
                    if tonumber(result[i+1]) < 1 or tonumber(result[i+1]) > 30 then
                        log.error("配置校验", "AUDIO_VOL 错误，只能配置为 1 至 30 ")
                        goto continue
                    end
                    fskv.set(result[i], tonumber(result[i+1]))
                end
            elseif "AUDIO_VOICE_PROMPT" == result[i] then
                if result[i+1]:len() ~= AUDIO_VOICE_PROMPT_LEN then
                    log.error("配置校验", "AUDIO_VOICE_PROMPT长度错误")
                    return false
                end
                fskv.set(result[i], result[i+1])
            elseif "POWER_SAVE_MODE" == result[i] then
                if result[i+1] then
                    if tonumber(result[i+1]) < 0 or tonumber(result[i+1]) > 3 then
                        log.error("配置校验", "POWER_SAVE_MODE 错误，只能配置为 0 至 3 ")
                        goto continue
                    end
                    fskv.set(result[i], tonumber(result[i+1]))
                end
            elseif "POWER_SAVE_MODE_TIME" == result[i] then
                if result[i+1] then
                    local v = tonumber(result[i+1])
                    if not v or (v < 60 or v > 1*60*60) then
                        log.error("配置校验", "POWER_SAVE_MODE_TIME错误，正确范围为大于60秒-3600秒")
                        goto continue
                    end
                    fskv.set(result[i], result[i+1])
                end
            elseif "POWER_SAVE_MODE_D1TIME" == result[i] then
                if result[i+1] then
                    local v = tonumber(result[i+1])
                    if not v or (v < 60 or v > 1*60*60) then
                        log.error("配置校验", "POWER_SAVE_MODE_D1TIME错误，正确范围为大于1分钟-1天")
                        goto continue
                    end
                    fskv.set(result[i], result[i+1])
                end
            elseif "POWER_SAVE_MODE_D2TIME" == result[i] then
                if result[i+1] then
                    local v = tonumber(result[i+1])
                    if not v or (v < 60*3 or v > 1*60*60*24*7) then
                        log.error("配置校验", "POWER_SAVE_MODE_D2TIME错误，正确范围为大于半小时-七天")
                        goto continue
                    end
                    fskv.set(result[i], result[i+1])
                end
            elseif "TRAVEL_MODE" == result[i] then
                if result[i+1] then
                    if tonumber(result[i+1]) < 0 or tonumber(result[i+1]) > 1 then
                        log.error("配置校验", "TRAVEL_MODE 错误，只能配置为 0 至 1 ")
                        goto continue
                    end
                    fskv.set(result[i], tonumber(result[i+1]))
                end 
            elseif "DISPLAY_VER" == result[i] then
                if result[i+1] then
                    if tonumber(result[i+1]) < 0 or tonumber(result[i+1]) > 1 then
                        log.error("配置校验", "DISPLAY_VER 错误，只能配置为 0 至 1 ")
                        goto continue
                    end
                    fskv.set(result[i], tonumber(result[i+1]))
                end
            elseif "SMS_CAT_ENABLE" == result[i] then
                if result[i+1] then
                    if tonumber(result[i+1]) < 0 or tonumber(result[i+1]) > 4 then
                        log.error("配置校验", "SMS_CAT_ENABLE 错误，只能配置为 0 至 4 ")
                        goto continue
                    end
                    fskv.set(result[i], tonumber(result[i+1]))
                end
            elseif "SMS_CAT_MOBILE" == result[i] then
                if result[i+1]:len() > 15 then
                    log.error("配置校验", "SMS_CAT_MOBILE长度过长，最大15个字符")
                    return false
                end
                fskv.set(result[i], result[i+1])
            elseif "TOTAL_MILEAGE" == result[i] then
                if result[i+1] then
                    local v = tonumber(result[i+1])
                    if not v then
                        log.error("配置校验", "TOTAL_MILEAGE 错误，只能是数字 ")
                        return false
                    end
                    fskv.set(result[i], result[i+1])
                end
            elseif "TOTAL_MILEAGE_AUTOCLEAR" == result[i] then
                if result[i+1] then
                    if tonumber(result[i+1]) < 0 or tonumber(result[i+1]) > 1 then
                        log.error("配置校验", "TOTAL_MILEAGE_AUTOCLEAR 错误，只能配置为 0 至 1 ")
                        goto continue
                    end
                    fskv.set(result[i], tonumber(result[i+1]))
                end
            elseif "SHICI_TYPE" == result[i] then
                if result[i+1] then
                    if utf8len(result[i+1]) > 50 then
                        log.error("配置校验", "SHICI_TYPE长度过长，最大50个字符")
                        goto continue
                    end
                    fskv.set(result[i], result[i+1])
                end
            elseif "TALK_MODE" == result[i] then
                if result[i+1] then
                    if tonumber(result[i+1]) < 0 or tonumber(result[i+1]) > 1 then
                        log.error("配置校验", "TALK_MODE 错误，只能配置为 0 至 1 ")
                        goto continue
                    end
                    fskv.set(result[i], tonumber(result[i+1]))
                end
            elseif "TALK_CHANNEL" == result[i] then
                if result[i+1] then
                    if utf8len(result[i+1]) > 50 then
                        log.error("配置校验", "TALK_CHANNEL长度过长，最大50个字符")
                        goto continue
                    end
                    fskv.set(result[i], result[i+1])
                end
            elseif "BTN_MODE" == result[i] then
                if result[i+1] then
                    local v = tonumber(result[i+1])
                    if not v and v < 1 or v > 2 then
                        log.error("配置校验", "BTN_MODE 错误，只能配置为 1 至 2 ")
                        return false
                    end
                    fskv.set(result[i], result[i+1])
                end
            elseif "POWER_RESTART_TIME" == result[i] then
                if result[i+1] then
                    if tonumber(result[i+1]) < 0 then
                        log.error("配置校验", "POWER_RESTART_TIME 错误，不能小于零 ")
                        goto continue
                    end
                    fskv.set(result[i], tonumber(result[i+1]))
                end
            elseif "COORD_ENC" == result[i] then
                if result[i+1] then
                    if tonumber(result[i+1]) < 0 or tonumber(result[i+1]) > 1 then
                        log.error("配置校验", "COORD_ENC 错误，只能配置为 0 至 1 ")
                        goto continue
                    end
                    fskv.set(result[i], tonumber(result[i+1]))
                end
            elseif "PWK_MODE" == result[i] then
                if result[i+1] then
                    if tonumber(result[i+1]) < 0 or tonumber(result[i+1]) > 1 then
                        log.error("配置校验", "PWK_MODE 错误，只能配置为 0 至 1 ")
                        goto continue
                    end
                    fskv.set(result[i], tonumber(result[i+1]))
                end
            else
                log.error("配置校验", "未找到匹配项")
            end
            
            ::continue::
        end
        sys.wait(2000)
        pm.reboot()
    else
        log.error("短信指令", "格式不正确")
    end
end
-- 向其他手机转发短信
local function sms_send_data(params)
    sms.send(aprscfg.SMS_CAT_MOBILE, params)
end
-- 向平台转发短信
local function sms_upload_data(params)
    local code, headers, body = http.request("GET", aprscfg.WEBCMD_HOST.."sms?imei="..mobile.imei().."&data="..string.toBase64(params)).wait()
    return code
end
-- 接收短信, 支持多种方式, 选一种就可以了
-- 1. 设置回调函数
--sms.setNewSmsCb(sms_handler)
-- 2. 订阅系统消息
--sys.subscribe("SMS_INC", sms_handler)
-- 3. 在task里等着
sys.taskInit(function()
    while true do
        local ret, num, txt = sys.waitUntil("SMS_INC", 300000)
        if num then
            -- 短信内容格式：APRS,SSID,2,BEACON_INTERVAL,90,0#
            log.info("收到来自%s的短信指令：%s", num, txt)
            local result = {}
            for match in txt:gmatch("([^,]+)") do
                table.insert(result, match)
            end
            
            if result[1] == "APRS" and result[#result] == "0#" then
                aprsCmd(result)
            elseif result[1] == "GPS" and result[#result] == "0#" then
                gpsCmd(result)
            else
                log.error("短信指令", "非指令短信")
                -- 仅转发非指令短信
                table.insert(toBeSentSMS, "["..num.."]"..txt)
                sys.publish("READY_SEND_SMS")
                
            end
            
        end
    end
end)

sys.taskInit(function()
    sys.waitUntil("CFGLOADED")
    while SMS_CAT_ENABLE ~= 0 do 
        sys.waitUntil("READY_SEND_SMS", 60000)
        if mobile.status() == 1 then
            while #toBeSentSMS > 0 do
                if aprscfg.SMS_CAT_ENABLE == 1 then
                    -- 需要转发手机
                    sms_send_data(toBeSentSMS[1])
                elseif aprscfg.SMS_CAT_ENABLE == 2 then
                    -- 需要转发平台
                    local code = sms_upload_data(toBeSentSMS[1])
                    if code == 200 then
                        log.info("READY_SEND_SMS", toBeSentSMS[1].." 成功")
                    else
                        log.warn("READY_SEND_SMS", toBeSentSMS[1].." 失败")
                    end
                elseif aprscfg.SMS_CAT_ENABLE == 3 or aprscfg.SMS_CAT_ENABLE == 4 then
                    local ret
                    -- 需要解析并转发到aprs
                    if aprscfg.SMS_CAT_ENABLE == 4 then 
                        ret = parsingtext2(toBeSentSMS[1])
                        if #ret ~= 2 then
                            ret = parsingtext2bd(toBeSentSMS[1])
                            if #ret ~= 2 then
                                ret = parsingtext2hl(toBeSentSMS[1])
                            end
                        end
                    else 
                        ret = parsingtext(toBeSentSMS[1])
                    end 
                    
                    if #ret == 6 and aprscfg.SMS_CAT_ENABLE == 3 then
                        -- 解析到经纬度等信息，发送aprs
                        log.info("sms2aprs", ret[1]..ret[2]..ret[3]..ret[4]..ret[5]..ret[6])
                        local fData = {}
                        fData.call = ret[1]
                        fData.t = ret[2]
                        fData.s = ret[3]
                        fData.msg = ret[4]
                        fData.lng = tonumber(duToGpsDM(ret[5]))		                        -- 经度
                        fData.lat = tonumber(duToGpsDM(ret[6]))		                        -- 纬度
                        fData.spd = 0	                                                    -- 速度
                        fData.cour = 0                              		                -- 航向variation
                        fData.alt = 0                                           			-- 海拔
                        fData.hdop = 1                                                      -- 位置精度
                        fData.satuse = 0			                                        -- 参与定位的卫星数量
                        fData.satview = 0                               				    -- 总可见卫星数量
                        fData.time = os.time()                                              -- 时间
                        fData.lngT = fData.lng >= 0 and "E" or "W"		                    -- 判断经度的方向
                        fData.latT = fData.lat >= 0 and "N" or "S"		                    -- 判断纬度的方向
                        table.insert(forwardMsgTab, fData)
                    elseif #ret == 2 and aprscfg.SMS_CAT_ENABLE == 4 then 
                        -- 解析到经纬度等信息，发送aprs
                        log.info("sms2aprs2", ret[1]..ret[2])
                        local fData = {}
                        fData.msg = "Forward SMS"
                        fData.lng = tonumber(duToGpsDM(ret[1]))		                        -- 经度
                        fData.lat = tonumber(duToGpsDM(ret[2]))		                        -- 纬度
                        fData.spd = 0	                                                    -- 速度
                        fData.cour = 0                              		                -- 航向variation
                        fData.alt = 0                                           			-- 海拔
                        fData.hdop = 1                                                      -- 位置精度
                        fData.satuse = 0			                                        -- 参与定位的卫星数量
                        fData.satview = 0                               				    -- 总可见卫星数量
                        fData.time = os.time()                                              -- 时间
                        fData.lngT = fData.lng >= 0 and "E" or "W"		                    -- 判断经度的方向
                        fData.latT = fData.lat >= 0 and "N" or "S"		                    -- 判断纬度的方向
                        table.insert(forwardMsgTab, fData)
                    else 
                        -- 未解析到经纬度，可以转发给平台
                        local code = sms_upload_data(toBeSentSMS[1])
                        if code == 200 then
                            log.info("READY_SEND_SMS", toBeSentSMS[1].." 成功")
                        else
                            log.warn("READY_SEND_SMS", toBeSentSMS[1].." 失败")
                        end
                    end
                end
                
                table.remove(toBeSentSMS, 1)
                sys.wait(500)
            end 
        end
    end
end)