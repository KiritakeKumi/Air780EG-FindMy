--[[
    Aprs4G by BG2LBF - MQTT消息管理
]]
local mqtt_host = ""
local mqtt_port = 0
local mqtt_isssl = false
local client_id
local username = ""
local password = ""

local pub_topic = "/iot/aprs4g/msg/"
local sub_topic

local mqttc = nil

-- 下载语音消息回调
function download_msg_callback(content_len, body_len)
    if content_len == body_len then
        log.info("download_msg_callback", "已下载完成")
    end
end
-- 下载语音消息
function download_msg(url)
    local opts = {}                 -- 额外的配置项
    opts["dst"] = "/msg.amr"        -- 下载路径
    opts["timeout"] = 10000         -- 超时时长,单位ms
    opts["callback"] = download_msg_callback
    -- opts["userdata"] = http_userdata
    http.request("GET",url, {}, "", opts)
end

sys.taskInit(function()
    sys.waitUntil("CFGLOADED")

    if aprscfg.TALK_MODE ~= 1 or DEV_TYPE == "air700" then
        return
    end

    mqtt_host = MQTT_HOST
    mqtt_port = MQTT_PORT
    mqtt_isssl = MQTT_SSL
    username = MQTT_USERNAME
    password = MQTT_PASSWORD

    client_id = mobile.imei()
    sub_topic = pub_topic .. aprscfg.TALK_CHANNEL
    mqttc = mqtt.create(nil, mqtt_host, mqtt_port, mqtt_isssl)

    mqttc:auth(client_id, username, password)
    -- mqttc:keepalive(240) -- 默认值240s
    mqttc:autoreconn(true, 3000) -- 自动重连机制
    mqttc:on(function(mqtt_client, event, data, payload)
        -- log.info("mqtt", "event", event, mqtt_client, data, payload)
        if event == "conack" then
            -- 联上了
            sys.publish("mqtt_conack")
            -- mqtt_client:subscribe(sub_topic)--单主题订阅,[sub_topic_all]=1
            mqtt_client:subscribe({[sub_topic]=1})--多主题订阅
        elseif event == "recv" then
            sys.publish("MQTT_PAYLOAD_MSG", data, payload)
        elseif event == "sent" then
            -- log.info("mqtt", "sent", "pkgid", data)
        -- elseif event == "disconnect" then
            -- 非自动重连时,按需重启mqttc
            -- mqtt_client:connect()
        end
    end)
    -- mqttc自动处理重连, 除非自行关闭
    mqttc:connect()
	sys.waitUntil("mqtt_conack")
    log.info("mqtt", "mqtt 已连接")
    while true do
        local ret, topic, data, qos = sys.waitUntil("MQTT_PUBLISH_MSG", 300000)  -- 发送消息
        if ret then
            if topic == "close" then break end
            mqttc:publish(pub_topic..topic, data, qos)
        end
    end
    mqttc:close()
    mqttc = nil
end)

-- 收到消息回调
sys.subscribe("MQTT_PAYLOAD_MSG", function(topic, payload)
    local recData = json.decode(payload)
    if topic == "public" and recData.from ~= client_id then
        log.info("mqtt", "公共房间")
        if recData.type == "audio" then
            download_msg(recData.data)
        end
    elseif sub_topic == topic then
        log.info("mqtt", "私有房间消息")
        if recData.type == "audio" and recData.from ~= client_id then
            download_msg(recData.data)
        end
    end
    log.info("mqtt", "MQTT_PAYLOAD_MSG", " topic", topic, "payload", recData.data)
end)

