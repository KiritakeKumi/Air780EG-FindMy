--[[
    Aprs4G by BG2LBF - web指令
]]

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

-- 更改aprs参数
local function changeAprsConf(newconf)
    if fskv.init() then
        log.info("fskv", "init complete")
        log.info("web指令更新：%s", json.encode(newconf))
        sys.wait(500)
        fskv.set("CALLSIGN", newconf.CALLSIGN)
        fskv.set("PASSCODE", newconf.PASSCODE)
        fskv.set("SSID", newconf.SSID)
        fskv.set("SERVER", newconf.SERVER)
        fskv.set("PORT", newconf.PORT)
        fskv.set("TABLE", newconf.TABLE)
        fskv.set("SYMBOL", newconf.SYMBOL)
        fskv.set("BEACON", newconf.BEACON)
        fskv.set("BEACON_TEXT", newconf.BEACON_TEXT)
        fskv.set("BEACON_INTERVAL", newconf.BEACON_INTERVAL)
        fskv.set("BEACON_STATUS_INTERVAL", newconf.BEACON_STATUS_INTERVAL)
        fskv.set("TRACKERMODE", newconf.TRACKERMODE)
        fskv.set("FIXLOC_LAT", newconf.FIXLOC_LAT)
        fskv.set("FIXLOC_LNG", newconf.FIXLOC_LNG)
        fskv.set("LOCMODE", newconf.LOCMODE)
        fskv.set("TRACCAR_HOST", newconf.TRACCAR_HOST)
        fskv.set("PLAT", newconf.PLAT)
        fskv.set("PLAT_SENDSELF", newconf.PLAT_SENDSELF)
        fskv.set("WEBCMD_HOST", newconf.WEBCMD_HOST)
        fskv.set("MAX_DECAY", newconf.MAX_DECAY)
        fskv.set("TRICK_MODE", newconf.TRICK_MODE)
        fskv.set("TRAVEL_MODE", newconf.TRAVEL_MODE)
        fskv.set("DISPLAY_VER", newconf.DISPLAY_VER)
        fskv.set("AGNSS_ENABLE", newconf.AGNSS_ENABLE)
        fskv.set("AUDIO_ENABLE", newconf.AUDIO_ENABLE)
        fskv.set("AUDIO_VOL", newconf.AUDIO_VOL)
        fskv.set("AUDIO_VOICE_PROMPT", newconf.AUDIO_VOICE_PROMPT)
        fskv.set("POWER_SAVE_MODE", newconf.POWER_SAVE_MODE)
        fskv.set("POWER_SAVE_MODE_TIME", newconf.POWER_SAVE_MODE_TIME)
        fskv.set("POWER_SAVE_MODE_D1TIME", newconf.POWER_SAVE_MODE_D1TIME)
        fskv.set("POWER_SAVE_MODE_D2TIME", newconf.POWER_SAVE_MODE_D2TIME)
        fskv.set("SMS_CAT_ENABLE", newconf.SMS_CAT_ENABLE)
        fskv.set("SMS_CAT_MOBILE", newconf.SMS_CAT_MOBILE)
        fskv.set("TOTAL_MILEAGE", newconf.TOTAL_MILEAGE)
        fskv.set("TOTAL_MILEAGE_AUTOCLEAR", newconf.TOTAL_MILEAGE_AUTOCLEAR)
        fskv.set("SHICI_TYPE", newconf.SHICI_TYPE)
        fskv.set("TALK_MODE", newconf.TALK_MODE)
        fskv.set("TALK_CHANNEL", newconf.TALK_CHANNEL)
        fskv.set("BTN_MODE", newconf.BTN_MODE)
        fskv.set("POWER_RESTART_TIME", newconf.POWER_RESTART_TIME)
        fskv.set("COORD_ENC", newconf.COORD_ENC)
        fskv.set("PWK_MODE", newconf.PWK_MODE)
        log.info("web指令更新：%s", "更新完成，正在重启")
        sys.wait(2000)
        pm.reboot()
    end
end

-- 参数检查
local function iniChk(iniFile)
    if not iniFile.CALLSIGN then
        log.error("配置校验", "呼号未设置")
        return false
    else
        iniFile.CALLSIGN = string.upper(iniFile.CALLSIGN)
        if not (iniFile.CALLSIGN:match('^[1-9]%u%u?%d%u%u?%u?%u?$') or
            iniFile.CALLSIGN:match('^%u[2-9A-Z]?%d%u%u?%u?%u?$')) then
            log.error("配置校验", "呼号不合法")
            return false
        end
        if string.len(iniFile.CALLSIGN) < 3 or string.len(iniFile.CALLSIGN) > 7 then
            log.error("配置校验", "呼号长度需要在 3-7 个字符")
            return false
        end
    end
    if not iniFile.PASSCODE then
        log.error("配置校验", "验证码未设置")
        return false
    else
        local pscode = pwdCal(iniFile.CALLSIGN)
        if not tonumber(iniFile.PASSCODE) or tonumber(iniFile.PASSCODE) ~= pscode then
            log.error("配置校验", "验证码错误")
            return false
        end
        iniFile.PASSCODE = pscode
    end
    if iniFile.SSID then
        iniFile.SSID = string.upper(iniFile.SSID)
        if not (iniFile.SSID:match('^%d%u?$') or iniFile.SSID:match('^[1][0-5]$') or iniFile.SSID:match('^%u%w?$')) then
            log.error("配置校验",
                "SSID不合法，只能是1-2个字母、数字；如果是2位数字，则不可以大于15")
            return false
        end
        if string.len(iniFile.CALLSIGN) + string.len(iniFile.SSID) > 8 then
            log.error("配置校验", "呼号+SSID的总长度不能超过8个字符")
            return false
        end
    end
    if iniFile.SERVER then
        if not (iniFile.SERVER:match('%.*%w[%w%-]*%.%a%a%a?%a?%a?%a?$') or JudgeIPString(iniFile.SERVER)) then
            log.error("配置校验", "服务器地址非法")
            return false
        end
    end
    if iniFile.PORT then
        local portTmp = tonumber(iniFile.PORT)
        if not portTmp or portTmp < 1024 or portTmp > 49151 then
            log.error("配置校验", "端口号非法，需要1024-49151之间")
            return false
        end
        iniFile.PORT = portTmp
    end
    if iniFile.TABLE then
        iniFile.TABLE = string.upper(iniFile.TABLE)
        if not iniFile.TABLE:match('^[/\\2DEGIRY]$') then
            log.error("配置校验", "TABLE设置错误")
            return false
        end
    end
    if iniFile.SYMBOL then
        if not iniFile.SYMBOL:match('^[%w%p]$') then
            log.error("配置校验", "SYMBOL设置错误")
            return false
        end
    end
    if iniFile.BEACON then
        if utf8len(iniFile.BEACON) > 100 then
            log.error("配置校验", "BEACON长度过长，最大100个字符")
            return false
        end
    end
    if iniFile.BEACON_TEXT then
        if utf8len(iniFile.BEACON_TEXT) > 200 then
            log.error("配置校验", "BEACON_TEXT长度过长，最大200个字符")
            return false
        end
    end
    if iniFile.BEACON_INTERVAL then
        local v = tonumber(iniFile.BEACON_INTERVAL)
        if not v or ((v < 10 or v >  1*60*60) and v ~= 0) then
            log.error("配置校验", "BEACON_INTERVAL错误，正确范围为10秒-1小时")
            return false
        end
        iniFile.BEACON_INTERVAL = v
    end
    if iniFile.BEACON_STATUS_INTERVAL then
        local v = tonumber(iniFile.BEACON_STATUS_INTERVAL)
        if not v or ((v < 60 or v >  24*60*60) and v ~= 0) then
            log.error("配置校验", "BEACON_STATUS_INTERVAL错误，正确范围为60秒-24小时")
            return false
        end
        iniFile.BEACON_STATUS_INTERVAL = v
    end
    if iniFile.LOCMODE then
        if iniFile.LOCMODE < 1 or iniFile.LOCMODE > 4 then
            log.error("配置校验", "LOCMODE 错误，只能配置为 1 至 4 ")
            return false
        end
        iniFile.LOCMODE = tonumber(iniFile.LOCMODE)
    end
    if iniFile.TRACKERMODE then
        if iniFile.TRACKERMODE < 1 or iniFile.TRACKERMODE > 2 then
            log.error("配置校验", "TRACKERMODE 错误，只能配置为 1 至 2 ")
            return false
        end
        iniFile.TRACKERMODE = tonumber(iniFile.TRACKERMODE)
    end
    if iniFile.FIXLOC_LAT then
        local v = tonumber(iniFile.FIXLOC_LAT)
        if not v then
            log.error("配置校验", "FIXLOC_LAT 错误，只能是数字 ")
            return false
        end
        iniFile.FIXLOC_LAT = v
    end
    if iniFile.FIXLOC_LNG then
        local v = tonumber(iniFile.FIXLOC_LNG)
        if not v then
            log.error("配置校验", "FIXLOC_LNG 错误，只能是数字 ")
            return false
        end
        iniFile.FIXLOC_LNG = v
    end
    if iniFile.TRACCAR_HOST then 
        if iniFile.TRACCAR_HOST:len() > 100 then
            log.error("配置校验", "TRACCAR_HOST长度过长，最大100个字符")
            return false
        end
    end
    if iniFile.PLAT then
        if iniFile.PLAT < 0 or iniFile.PLAT > 2 then
            log.error("配置校验", "PLAT 错误，只能配置为 0 至 2 ")
            return false
        end
        iniFile.PLAT = tonumber(iniFile.PLAT)
    end 
    if iniFile.PLAT_SENDSELF then
        if iniFile.PLAT_SENDSELF < 0 or iniFile.PLAT_SENDSELF > 1 then
            log.error("配置校验", "PLAT_SENDSELF 错误，只能配置为 0 至 1 ")
            return false
        end
        iniFile.PLAT_SENDSELF = tonumber(iniFile.PLAT_SENDSELF)
    end 
    if iniFile.WEBCMD_HOST then 
        if iniFile.WEBCMD_HOST:len() > 100 then
            log.error("配置校验", "WEBCMD_HOST长度过长，最大100个字符")
            return false
        end
    end
    if iniFile.MAX_DECAY then
        local v = tonumber(iniFile.MAX_DECAY)
        if not v then
            log.error("配置校验", "MAX_DECAY 错误，只能是数字 ")
            return false
        end
        if v < 1 or v > 32 then
            log.error("配置校验", "MAX_DECAY 错误，只能配置为 1 至 32 ")
            return false
        end
        iniFile.MAX_DECAY = v
    end
    if iniFile.TRICK_MODE then
        if iniFile.TRICK_MODE < 0 or iniFile.TRICK_MODE > 1 then
            log.error("配置校验", "TRICK_MODE 错误，只能配置为 0 至 1 ")
            return false
        end
        iniFile.TRICK_MODE = tonumber(iniFile.TRICK_MODE)
    end 
    if iniFile.AGNSS_ENABLE then
        if iniFile.AGNSS_ENABLE < 0 or iniFile.AGNSS_ENABLE > 1 then
            log.error("配置校验", "AGNSS_ENABLE 错误，只能配置为 0 至 1 ")
            return false
        end
        iniFile.AGNSS_ENABLE = tonumber(iniFile.AGNSS_ENABLE)
    end
    if iniFile.AUDIO_ENABLE then
        if iniFile.AUDIO_ENABLE < 0 or iniFile.AUDIO_ENABLE > 1 then
            log.error("配置校验", "AUDIO_ENABLE 错误，只能配置为 0 至 1 ")
            return false
        end
        iniFile.AUDIO_ENABLE = tonumber(iniFile.AUDIO_ENABLE)
    end
    if iniFile.AUDIO_VOL then
        if iniFile.AUDIO_VOL < 1 or iniFile.AUDIO_VOL > 30 then
            log.error("配置校验", "AUDIO_VOL 错误，只能配置为 1 至 30 ")
            return false
        end
        iniFile.AUDIO_VOL = tonumber(iniFile.AUDIO_VOL)
    end
    if iniFile.AUDIO_VOICE_PROMPT then 
        if iniFile.AUDIO_VOICE_PROMPT:len() ~= AUDIO_VOICE_PROMPT_LEN then
            log.error("配置校验", "AUDIO_VOICE_PROMPT长度错误")
            return false
        end
    end
    if iniFile.POWER_SAVE_MODE then
        if iniFile.POWER_SAVE_MODE < 0 or iniFile.POWER_SAVE_MODE > 3 then
            log.error("配置校验", "POWER_SAVE_MODE 错误，只能配置为 0 至 3 ")
            return false
        end
        iniFile.POWER_SAVE_MODE = tonumber(iniFile.POWER_SAVE_MODE)
    end
    if iniFile.POWER_SAVE_MODE_TIME then
        local v = tonumber(iniFile.POWER_SAVE_MODE_TIME)
        if not v or (v < 60 or v > 1*60*60) then
            log.error("配置校验", "POWER_SAVE_MODE_TIME错误，正确范围为大于60秒-3600秒")
            return false
        end
        iniFile.POWER_SAVE_MODE_TIME = v
    end
    if iniFile.POWER_SAVE_MODE_D1TIME then
        local v = tonumber(iniFile.POWER_SAVE_MODE_D1TIME)
        if not v or (v < 60 or v > 1*60*60*24) then
            log.error("配置校验", "POWER_SAVE_MODE_D1TIME错误，正确范围为大于1分钟-1天")
            return false
        end
        iniFile.POWER_SAVE_MODE_D1TIME = v
    end
    if iniFile.POWER_SAVE_MODE_D2TIME then
        local v = tonumber(iniFile.POWER_SAVE_MODE_D2TIME)
        if not v or (v < 60*3 or v > 1*60*60*24*7) then
            log.error("配置校验", "POWER_SAVE_MODE_D2TIME错误，正确范围为大于半小时-七天")
            return false
        end
        iniFile.POWER_SAVE_MODE_D2TIME = v
    end
    if iniFile.TRAVEL_MODE then
        if iniFile.TRAVEL_MODE < 0 or iniFile.TRAVEL_MODE > 1 then
            log.error("配置校验", "TRAVEL_MODE 错误，只能配置为 0 至 1 ")
            return false
        end
        iniFile.TRAVEL_MODE = tonumber(iniFile.TRAVEL_MODE)
    end 
    if iniFile.DISPLAY_VER then
        if iniFile.DISPLAY_VER < 0 or iniFile.DISPLAY_VER > 1 then
            log.error("配置校验", "DISPLAY_VER 错误，只能配置为 0 至 1 ")
            return false
        end
        iniFile.DISPLAY_VER = tonumber(iniFile.DISPLAY_VER)
    end
    if iniFile.SMS_CAT_ENABLE then
        if iniFile.SMS_CAT_ENABLE < 0 or iniFile.SMS_CAT_ENABLE > 4 then
            log.error("配置校验", "SMS_CAT_ENABLE 错误，只能配置为 0 至 4 ")
            return false
        end
        iniFile.SMS_CAT_ENABLE = tonumber(iniFile.SMS_CAT_ENABLE)
    end
    if iniFile.SMS_CAT_MOBILE then 
        if iniFile.SMS_CAT_MOBILE:len() > 15 then
            log.error("配置校验", "SMS_CAT_MOBILE长度过长，最大15个字符")
            return false
        end
    end
    if iniFile.TOTAL_MILEAGE then
        local v = tonumber(iniFile.TOTAL_MILEAGE)
        if not v then
            log.error("配置校验", "TOTAL_MILEAGE 错误，只能是数字 ")
            return false
        end
        iniFile.TOTAL_MILEAGE = v
    end
    if iniFile.TOTAL_MILEAGE_AUTOCLEAR then
        if iniFile.TOTAL_MILEAGE_AUTOCLEAR < 0 or iniFile.TOTAL_MILEAGE_AUTOCLEAR > 1 then
            log.error("配置校验", "TOTAL_MILEAGE_AUTOCLEAR 错误，只能配置为 0 至 1 ")
            return false
        end
        iniFile.TOTAL_MILEAGE_AUTOCLEAR = tonumber(iniFile.TOTAL_MILEAGE_AUTOCLEAR)
    end
    if iniFile.SHICI_TYPE then
        if utf8len(iniFile.SHICI_TYPE) > 50 then
            log.error("配置校验", "SHICI_TYPE长度过长，最大50个字符")
            return false
        end
    end
    if iniFile.TALK_MODE then
        if iniFile.TALK_MODE < 0 or iniFile.TALK_MODE > 1 then
            log.error("配置校验", "TALK_MODE 错误，只能配置为 0 至 1 ")
            return false
        end
        iniFile.TALK_MODE = tonumber(iniFile.TALK_MODE)
    end
    if iniFile.TALK_CHANNEL then
        if utf8len(iniFile.TALK_CHANNEL) > 50 then
            log.error("配置校验", "TALK_CHANNEL长度过长，最大50个字符")
            return false
        end
    end
    if iniFile.BTN_MODE then
        if iniFile.BTN_MODE < 1 or iniFile.BTN_MODE > 2 then
            log.error("配置校验", "BTN_MODE 错误，只能配置为 1 至 2 ")
            return false
        end
        iniFile.BTN_MODE = tonumber(iniFile.BTN_MODE)
    end
    if iniFile.POWER_RESTART_TIME then
        if iniFile.POWER_RESTART_TIME < 0  then
            log.error("配置校验", "POWER_RESTART_TIME 错误，不能小于零 ")
            return false
        end
        iniFile.POWER_RESTART_TIME = tonumber(iniFile.POWER_RESTART_TIME)
    end 
    if iniFile.COORD_ENC then
        if iniFile.COORD_ENC < 0 or iniFile.COORD_ENC > 1 then
            log.error("配置校验", "COORD_ENC 错误，只能配置为 0 至 1 ")
            return false
        end
        iniFile.COORD_ENC = tonumber(iniFile.COORD_ENC)
    end
    if iniFile.PWK_MODE then
        if iniFile.PWK_MODE < 0 or iniFile.PWK_MODE > 1 then
            log.error("配置校验", "PWK_MODE 错误，只能配置为 0 至 1 ")
            return false
        end
        iniFile.PWK_MODE = tonumber(iniFile.PWK_MODE)
    end
    log.info("配置校验", "配置校验已通过")
    return true, iniFile
end

local function aprs_upload_conf(params)
    local req_headers = {}
    req_headers["Content-Type"] = "application/json"
    local body = json.encode(params)
    local code, headers, body = http.request("POST",
            aprscfg.WEBCMD_HOST.."uploadconf", 
            req_headers,
            body 
    ).wait()
    log.info("http.post.aprs_upload_conf", code, headers, body)
    return code
end

local function aprs_update_conf(imei)
    local req_headers = {}
    req_headers["Content-Type"] = "application/json"
    local body = json.encode({})
    local code, headers, body = http.request("POST",
            aprscfg.WEBCMD_HOST.."updateconf?imei="..imei, 
            req_headers,
            body 
    ).wait()
    log.info("http.post.aprs_update_conf", code, headers, body)
    return code, body
end

sys.taskInit(function()
    -- skip web config sync (disabled)
    return
end)
