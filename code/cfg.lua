--[[
    Aprs4G by BG2LBF - 参数配置
]]
local isDebug = false
DEV_TYPE = "air780eg"                   -- 定义当前要安装的设备型号（主要是区分不同主板的引脚定义，自制主板请修改对应引脚），目前已知支持 air780e/air780eg/air700/air780eg-yed
AUDIO_VOICE_PROMPT_LEN = 0              -- 语音提示音频种类数量
-- MQTT相关信息暂不提供web配置
MQTT_HOST = ""
MQTT_PORT = 1000
MQTT_SSL = false
MQTT_USERNAME = ""
MQTT_PASSWORD = ""
-- 百度坐标转换AK，暂不提供web配置
BD_GEOCONV = ""

aprscfg = {
    ["CALLSIGN"] = "AAAAAA",            -- 呼号
    ["PASSCODE"] = 16815,               -- ARPS验证码
    ["SSID"] = "1",                     -- SSID，1-2个数字或字母。默认值 1
    ["SERVER"] = "niconiconi.us",             -- APRS服务器地址，域名或IP地址都可以。默认值 aprs.tv
    ["PORT"] = 14580,                   -- APRS服务器端口号，范围 1024-49151。默认值  14580
    ["TABLE"] = "/",                    -- 台站图标TABLE。默认值 /
    ["SYMBOL"] = ">",                   -- 台站图标SYMBOL。默认值 >
    ["BEACON"] = "ping",     -- 信标状态文本，最长62个字符。
    ["BEACON_INTERVAL"] = 60,           -- 信标发送间隔，单位秒，范围 10 - 1*60*60 ，设置为 0 时关闭信标发送功能。默认值 60
    ["BEACON_STATUS_INTERVAL"] = 600,   -- 信标状态发送间隔，单位秒   60 - 24*60*60 ，设置为 0 时关闭信标状态发送功能。默认值 600
    ["TRACKERMODE"] = 1,                -- Tracker工作模式：1表示移动台站、2表示指定坐标的固定台站（需要指定坐标）
    ["FIXLOC_LAT"] = 4311.1,            -- 固定台站指定坐标 纬度 默认值 4319.8 ddmm.mmmm 格式
    ["FIXLOC_LNG"] = 12533.3,           -- 固定台站指定坐标 经度 默认值 12533.0 ddmm.mmmm 格式
    ["LOCMODE"] = 3,                    -- 定位方式： 1表示GPS定位、2表示基站定位、3表示混合定位
    ["TRACCAR_HOST"] = "http://写你的服务器:5055/",  -- Traccar 上报地址，目前支持OsmAnd方式上报 默认值 http://traccar.aprs.tv:5055/
    ["PLAT"] = 2,                       -- 上传平台选择  0表示上传全部平台  1表示只上传aprs平台  2表示只上传Traccar平台   默认值 1
    ["WEBCMD_HOST"] = "http://1.1.1.1/aprs4g/", -- WEB平台地址
    ["MAX_DECAY"] = 32,                 -- 最大衰减倍数（数值需为衰减率2的指数倍，最大32）
    ["TRICK_MODE"] = 0,                 -- 调皮模式 默认0：关闭   ， 1：开启
    ["TRAVEL_MODE"] = 0,                -- 行进模式 默认0：驾车   ， 1：徒步（多数较慢行进）
    ["DISPLAY_VER"] = 1,                -- 是否显示版本号 默认1：显示， 0：不显示
    ["BEACON_TEXT"] = "imei:*${imei} rssi:${rssi} sat:${satuse}/${sattotal} temp:${temp} vol:${vol} mileage:${totalm}km",     -- 信标文本，最长200个字符。
    ["AGNSS_ENABLE"] = 0,               -- 是否使用agnss,可以提高定位速度，但是需要消耗一些网络流量  默认0：关闭   ， 1：开启
    ["AUDIO_ENABLE"] = 0,               -- 是否使用语音喇叭   默认0：关闭   ， 1：开启
    ["AUDIO_VOL"] = 10,                 -- 是语音喇叭的音量   默认10     允许 1-30 之间 ，数值越大  音量越大
    ["AUDIO_VOICE_PROMPT"] = "11111111",-- 每一个语音提示是否播放的开关，1为播放 0为不播放 ，顺序为 开机音频/关机音频/发射音频/讲话开始提示音频/讲话结束提示音频/定位成功音频/定位丢失音频/电量低音频  默认11111111
    ["POWER_SAVE_MODE"] = 0,            -- 是否启用省电模式   默认0：关闭， 1：静止省电， 2：定时省电， 3：静止关机
    ["POWER_SAVE_MODE_TIME"] = 600,     -- 静止省电模式下静止多久进入省电模式，单位秒。默认值600   60（一分钟）-  3600（1小时）
    ["POWER_SAVE_MODE_D1TIME"] = 300,   -- 定时省电模式下间隔多久定时关机,每次启动时间，默认300秒，单位秒。60（1分钟） -  86400（1天）
    ["POWER_SAVE_MODE_D2TIME"] = 3600,  -- 定时省电模式下间隔多久定时启动,每次休眠时间，默认值3600（一小时）单位秒。   1800（30分钟） -  604800（7天）
    ["SMS_CAT_ENABLE"] = 0,             -- 短信猫（短信转发，EC618不支持电信卡收发短信） 默认0：关闭， 1：开启-转发到手机（存在短信费） 2：开启-转发到平台（免费）3：开启-转发到APRS网络（免费，5字段特定文本，识别不到将转发到平台）4：开启-转发到APRS网络（免费，2字段特定文本，识别不到将转发到平台）
    ["SMS_CAT_MOBILE"] = "10086",       -- 短信猫 转发目标手机号码 
    ["TOTAL_MILEAGE"] = 0.0,            -- 总里程公里数 默认：0.0 （公里）
    ["TOTAL_MILEAGE_AUTOCLEAR"] = 0,    -- 总里程公里数手动关机自动清零 默认：0：不清零    1：自动清零
    ["SHICI_TYPE"] = "all",             -- 使用诗词API的主题类型   默认all  ,变量为 ${shici_content}${shici_title}${shici_author}
    ["TALK_MODE"] = 0,                  -- 是否使用网络对讲模式   默认0：关闭   ， 1：开启
    ["TALK_CHANNEL"] = "public",        -- 使用网络对讲模式时的频道名称   默认public
    ["BTN_MODE"] = 1,                   -- 按钮模式   默认1：信标自主发射   ， 2：重复最后一次对讲语音 
    ["PLAT_SENDSELF"] = 1,              -- 上传平台时是否上传自身位置  0表示不上传  1表示上传  默认值 1
    ["POWER_RESTART_TIME"] = 24,         -- 自动重启时间间隔，单位小时。默认值0 （不自动重启）   例如：24 表示开机24小时后自动重启
    ["COORD_ENC"] = 0,                  -- 上传的坐标是否使用BD09坐标系。 默认：0：不加密    1：加密成BD09坐标系
    ["PWK_MODE"] = 1                    -- 按钮长按开机。 默认：1：长按开机    0：短按开机
}
-- 计算验证码
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
-- 检查服务器地址
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
        if not v or (v < 60 or v >  1*60*60) then
            log.error("配置校验", "POWER_SAVE_MODE_TIME错误，正确范围为60秒-3600秒")
            return false
        end
        iniFile.POWER_SAVE_MODE_TIME = v
    end
    if iniFile.POWER_SAVE_MODE_D1TIME then
        local v = tonumber(iniFile.POWER_SAVE_MODE_D1TIME)
        if not v or (v < 60 or v >  1*60*60*24) then
            log.error("配置校验", "POWER_SAVE_MODE_D1TIME错误，正确范围为1分钟-1天")
            return false
        end
        iniFile.POWER_SAVE_MODE_D1TIME = v
    end
    if iniFile.POWER_SAVE_MODE_D2TIME then
        local v = tonumber(iniFile.POWER_SAVE_MODE_D2TIME)
        if not v or (v < 60*3 or v >  1*60*60*24*7) then
            log.error("配置校验", "POWER_SAVE_MODE_D2TIME错误，正确范围为半小时-7天")
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
        if iniFile.POWER_RESTART_TIME < 0 then
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



sys.taskInit(function()
    sys.waitUntil("IP_READY")
    -- 检查一下当前固件是否支持fskv
    if not fskv then
        while true do
            log.error("fskv", "this app need fskv")
            sys.wait(1000)
        end
    end
    -- 初始化kv数据库
    if fskv.init() then
        log.info("fskv", "init complete")
        if isDebug then
            fskv.clear()
        end
        AUDIO_VOICE_PROMPT_LEN = aprscfg.AUDIO_VOICE_PROMPT:len()
        local used, total, kv_count = fskv.status()
        if kv_count <= 0 then
            fskv.set("CALLSIGN", aprscfg.CALLSIGN)
            fskv.set("PASSCODE", aprscfg.PASSCODE)
            fskv.set("SSID", aprscfg.SSID)
            fskv.set("SERVER", aprscfg.SERVER)
            fskv.set("PORT", aprscfg.PORT)
            fskv.set("TABLE", aprscfg.TABLE)
            fskv.set("SYMBOL", aprscfg.SYMBOL)
            fskv.set("BEACON", aprscfg.BEACON)
            fskv.set("BEACON_TEXT", aprscfg.BEACON_TEXT)
            fskv.set("BEACON_INTERVAL", aprscfg.BEACON_INTERVAL)
            fskv.set("BEACON_STATUS_INTERVAL", aprscfg.BEACON_STATUS_INTERVAL)
            fskv.set("TRACKERMODE", aprscfg.TRACKERMODE)
            fskv.set("FIXLOC_LAT", aprscfg.FIXLOC_LAT)
            fskv.set("FIXLOC_LNG", aprscfg.FIXLOC_LNG)
            fskv.set("LOCMODE", aprscfg.LOCMODE)
            fskv.set("TRACCAR_HOST", aprscfg.TRACCAR_HOST)
            fskv.set("PLAT", aprscfg.PLAT)
            fskv.set("PLAT_SENDSELF", aprscfg.PLAT_SENDSELF)
            fskv.set("WEBCMD_HOST", aprscfg.WEBCMD_HOST)
            fskv.set("MAX_DECAY", aprscfg.MAX_DECAY)
            fskv.set("TRICK_MODE", aprscfg.TRICK_MODE)
            fskv.set("TRAVEL_MODE", aprscfg.TRAVEL_MODE)
            fskv.set("DISPLAY_VER", aprscfg.DISPLAY_VER)
            fskv.set("AGNSS_ENABLE", aprscfg.AGNSS_ENABLE)
            fskv.set("AUDIO_ENABLE", aprscfg.AUDIO_ENABLE)
            fskv.set("AUDIO_VOL", aprscfg.AUDIO_VOL)
            fskv.set("AUDIO_VOICE_PROMPT", aprscfg.AUDIO_VOICE_PROMPT)
            fskv.set("POWER_SAVE_MODE", aprscfg.POWER_SAVE_MODE)
            fskv.set("POWER_SAVE_MODE_TIME", aprscfg.POWER_SAVE_MODE_TIME)
            fskv.set("POWER_SAVE_MODE_D1TIME", aprscfg.POWER_SAVE_MODE_D1TIME)
            fskv.set("POWER_SAVE_MODE_D2TIME", aprscfg.POWER_SAVE_MODE_D2TIME)
            fskv.set("SMS_CAT_ENABLE", aprscfg.SMS_CAT_ENABLE)
            fskv.set("SMS_CAT_MOBILE", aprscfg.SMS_CAT_MOBILE)
            fskv.set("TOTAL_MILEAGE", aprscfg.TOTAL_MILEAGE)
            fskv.set("TOTAL_MILEAGE_AUTOCLEAR", aprscfg.TOTAL_MILEAGE_AUTOCLEAR)
            fskv.set("SHICI_TYPE", aprscfg.SHICI_TYPE)
            fskv.set("TALK_MODE", aprscfg.TALK_MODE)
            fskv.set("TALK_CHANNEL", aprscfg.TALK_CHANNEL)
            fskv.set("BTN_MODE", aprscfg.BTN_MODE)
            fskv.set("POWER_RESTART_TIME", aprscfg.POWER_RESTART_TIME)
            fskv.set("COORD_ENC", aprscfg.COORD_ENC)
            fskv.set("PWK_MODE", aprscfg.PWK_MODE)
        end
        if fskv.get("CALLSIGN") == nil then
            fskv.set("CALLSIGN", aprscfg.CALLSIGN)
        end
        aprscfg.CALLSIGN = fskv.get("CALLSIGN")
        if fskv.get("PASSCODE") == nil then
            fskv.set("PASSCODE", aprscfg.PASSCODE)
        end
        aprscfg.PASSCODE = fskv.get("PASSCODE")
        if fskv.get("SSID") == nil then
            fskv.set("SSID", aprscfg.SSID)
        end
        aprscfg.SSID = fskv.get("SSID")
        if fskv.get("SERVER") == nil then
            fskv.set("SERVER", aprscfg.SERVER)
        end
        aprscfg.SERVER = fskv.get("SERVER")
        if fskv.get("PORT") == nil then
            fskv.set("PORT", aprscfg.PORT)
        end
        aprscfg.PORT = fskv.get("PORT")
        if fskv.get("TABLE") == nil then
            fskv.set("TABLE", aprscfg.TABLE)
        end
        aprscfg.TABLE = fskv.get("TABLE")
        if fskv.get("SYMBOL") == nil then
            fskv.set("SYMBOL", aprscfg.SYMBOL)
        end
        aprscfg.SYMBOL = fskv.get("SYMBOL")
        if fskv.get("BEACON") == nil then
            fskv.set("BEACON", aprscfg.BEACON)
        end
        aprscfg.BEACON = fskv.get("BEACON")
        if fskv.get("BEACON_TEXT") == nil then
            fskv.set("BEACON_TEXT", aprscfg.BEACON_TEXT)
        end
        aprscfg.BEACON_TEXT = fskv.get("BEACON_TEXT")
        if fskv.get("BEACON_INTERVAL") == nil then
            fskv.set("BEACON_INTERVAL", aprscfg.BEACON_INTERVAL)
        end
        aprscfg.BEACON_INTERVAL = fskv.get("BEACON_INTERVAL")
        if fskv.get("BEACON_STATUS_INTERVAL") == nil then
            fskv.set("BEACON_STATUS_INTERVAL", aprscfg.BEACON_STATUS_INTERVAL)
        end
        aprscfg.BEACON_STATUS_INTERVAL = fskv.get("BEACON_STATUS_INTERVAL")
        if fskv.get("TRACKERMODE") == nil then
            fskv.set("TRACKERMODE", aprscfg.TRACKERMODE)
        end
        aprscfg.TRACKERMODE = fskv.get("TRACKERMODE")
        if fskv.get("FIXLOC_LAT") == nil then
            fskv.set("FIXLOC_LAT", aprscfg.FIXLOC_LAT)
        end
        aprscfg.FIXLOC_LAT = fskv.get("FIXLOC_LAT")
        if fskv.get("FIXLOC_LNG") == nil then
            fskv.set("FIXLOC_LNG", aprscfg.FIXLOC_LNG)
        end
        aprscfg.FIXLOC_LNG = fskv.get("FIXLOC_LNG")
        if fskv.get("LOCMODE") == nil then
            fskv.set("LOCMODE", aprscfg.LOCMODE)
        end
        aprscfg.LOCMODE = fskv.get("LOCMODE")
        if fskv.get("TRACCAR_HOST") == nil then
            fskv.set("TRACCAR_HOST", aprscfg.TRACCAR_HOST)
        end
        aprscfg.TRACCAR_HOST = fskv.get("TRACCAR_HOST")
        if fskv.get("PLAT") == nil then
            fskv.set("PLAT", aprscfg.PLAT)
        end
        aprscfg.PLAT = fskv.get("PLAT")
        if fskv.get("PLAT_SENDSELF") == nil then
            fskv.set("PLAT_SENDSELF", aprscfg.PLAT_SENDSELF)
        end
        aprscfg.PLAT_SENDSELF = fskv.get("PLAT_SENDSELF")
        -- 强制切换web指令后台地址
        --if fskv.get("WEBCMD_HOST") == nil then
            fskv.set("WEBCMD_HOST", aprscfg.WEBCMD_HOST)
        --end
        aprscfg.WEBCMD_HOST = fskv.get("WEBCMD_HOST")
        if fskv.get("MAX_DECAY") == nil then
            fskv.set("MAX_DECAY", aprscfg.MAX_DECAY)
        end
        aprscfg.MAX_DECAY = fskv.get("MAX_DECAY")
        if fskv.get("TRICK_MODE") == nil then
            fskv.set("TRICK_MODE", aprscfg.TRICK_MODE)
        end
        aprscfg.TRICK_MODE = fskv.get("TRICK_MODE")
        if fskv.get("AGNSS_ENABLE") == nil then
            fskv.set("AGNSS_ENABLE", aprscfg.AGNSS_ENABLE)
        end
        aprscfg.AGNSS_ENABLE = fskv.get("AGNSS_ENABLE")
        if fskv.get("AUDIO_ENABLE") == nil then
            fskv.set("AUDIO_ENABLE", aprscfg.AUDIO_ENABLE)
        end
        aprscfg.AUDIO_ENABLE = fskv.get("AUDIO_ENABLE")
        if fskv.get("AUDIO_VOL") == nil then
            fskv.set("AUDIO_VOL", aprscfg.AUDIO_VOL)
        end
        aprscfg.AUDIO_VOL = fskv.get("AUDIO_VOL")
        if fskv.get("AUDIO_VOICE_PROMPT") == nil or fskv.get("AUDIO_VOICE_PROMPT"):len() ~= AUDIO_VOICE_PROMPT_LEN then
            fskv.set("AUDIO_VOICE_PROMPT", aprscfg.AUDIO_VOICE_PROMPT)
        end
        aprscfg.AUDIO_VOICE_PROMPT = fskv.get("AUDIO_VOICE_PROMPT")
        if fskv.get("POWER_SAVE_MODE") == nil then
            fskv.set("POWER_SAVE_MODE", aprscfg.POWER_SAVE_MODE)
        end
        aprscfg.POWER_SAVE_MODE = fskv.get("POWER_SAVE_MODE")
        if fskv.get("POWER_SAVE_MODE_TIME") == nil then
            fskv.set("POWER_SAVE_MODE_TIME", aprscfg.POWER_SAVE_MODE_TIME)
        end
        aprscfg.POWER_SAVE_MODE_TIME = fskv.get("POWER_SAVE_MODE_TIME")
        if fskv.get("POWER_SAVE_MODE_D1TIME") == nil then
            fskv.set("POWER_SAVE_MODE_D1TIME", aprscfg.POWER_SAVE_MODE_D1TIME)
        end
        aprscfg.POWER_SAVE_MODE_D1TIME = fskv.get("POWER_SAVE_MODE_D1TIME")
        if fskv.get("POWER_SAVE_MODE_D2TIME") == nil then
            fskv.set("POWER_SAVE_MODE_D2TIME", aprscfg.POWER_SAVE_MODE_D2TIME)
        end
        aprscfg.POWER_SAVE_MODE_D2TIME = fskv.get("POWER_SAVE_MODE_D2TIME")
        if fskv.get("TRAVEL_MODE") == nil then
            fskv.set("TRAVEL_MODE", aprscfg.TRAVEL_MODE)
        end
        aprscfg.TRAVEL_MODE = fskv.get("TRAVEL_MODE")
        if fskv.get("DISPLAY_VER") == nil then
            fskv.set("DISPLAY_VER", aprscfg.DISPLAY_VER)
        end
        aprscfg.DISPLAY_VER = fskv.get("DISPLAY_VER")
        if fskv.get("SMS_CAT_ENABLE") == nil then
            fskv.set("SMS_CAT_ENABLE", aprscfg.SMS_CAT_ENABLE)
        end
        aprscfg.SMS_CAT_ENABLE = fskv.get("SMS_CAT_ENABLE")
        if fskv.get("SMS_CAT_MOBILE") == nil then
            fskv.set("SMS_CAT_MOBILE", aprscfg.SMS_CAT_MOBILE)
        end
        aprscfg.SMS_CAT_MOBILE = fskv.get("SMS_CAT_MOBILE")
        if fskv.get("TOTAL_MILEAGE") == nil then
            fskv.set("TOTAL_MILEAGE", aprscfg.TOTAL_MILEAGE)
        end
        aprscfg.TOTAL_MILEAGE = fskv.get("TOTAL_MILEAGE")
        if fskv.get("TOTAL_MILEAGE_AUTOCLEAR") == nil then
            fskv.set("TOTAL_MILEAGE_AUTOCLEAR", aprscfg.TOTAL_MILEAGE_AUTOCLEAR)
        end
        aprscfg.TOTAL_MILEAGE_AUTOCLEAR = fskv.get("TOTAL_MILEAGE_AUTOCLEAR")
        if fskv.get("SHICI_TYPE") == nil then
            fskv.set("SHICI_TYPE", aprscfg.SHICI_TYPE)
        end
        aprscfg.SHICI_TYPE = fskv.get("SHICI_TYPE")
        if fskv.get("TALK_MODE") == nil then
            fskv.set("TALK_MODE", aprscfg.TALK_MODE)
        end
        aprscfg.TALK_MODE = fskv.get("TALK_MODE")
        if fskv.get("TALK_CHANNEL") == nil then
            fskv.set("TALK_CHANNEL", aprscfg.TALK_CHANNEL)
        end
        aprscfg.TALK_CHANNEL = fskv.get("TALK_CHANNEL")
        if fskv.get("BTN_MODE") == nil then
            fskv.set("BTN_MODE", aprscfg.BTN_MODE)
        end
        aprscfg.BTN_MODE = fskv.get("BTN_MODE")
        if fskv.get("POWER_RESTART_TIME") == nil then
            fskv.set("POWER_RESTART_TIME", aprscfg.POWER_RESTART_TIME)
        end
        aprscfg.POWER_RESTART_TIME = fskv.get("POWER_RESTART_TIME")
        if fskv.get("COORD_ENC") == nil then
            fskv.set("COORD_ENC", aprscfg.COORD_ENC)
        end
        aprscfg.COORD_ENC = fskv.get("COORD_ENC")
        if fskv.get("PWK_MODE") == nil then
            fskv.set("PWK_MODE", aprscfg.PWK_MODE)
        end
        aprscfg.PWK_MODE = fskv.get("PWK_MODE")
        if iniChk(aprscfg) then
            log.info("加载配置文件", "加载已完成")
            log.info("aprscfg", json.encode(aprscfg or {}))
            if aprscfg.SSID == '0' then
                aprscfg.sourceCall = aprscfg.CALLSIGN
            else
                aprscfg.sourceCall = aprscfg.CALLSIGN .. '-' .. aprscfg.SSID
            end
            socket.setDNS(nil, 1, "114.114.114.114")
            sys.wait(1000)
            sys.publish("CFGLOADED")
            if aprscfg.TRACKERMODE == 1 then
                if aprscfg.LOCMODE == 1 then
                    -- GPS
                    sys.publish("LOC_GPS")
                elseif aprscfg.LOCMODE == 2 then
                    -- LBS
                    sys.publish("LOC_LBS")
                else
                    -- 混合模式，优先GPS
                    sys.publish("LOC_GPS_LBS")
                end
            elseif aprscfg.TRACKERMODE == 2 then
                -- 固定台
                if tonumber(aprscfg.FIXLOC_LAT) and tonumber(aprscfg.FIXLOC_LNG) then
                    sys.publish("LOC_USER_FIXED")
                else
                    log.warn("加载配置文件", "固定台坐标错误")
                end
            end
            
        else
            log.warn("加载配置文件", "加载失败")
        end
        sys.publish("CFGFINISH")
    end
     
end)
