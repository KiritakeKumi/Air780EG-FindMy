--[[
    Aprs4G by BG2LBF - Traccar 网络控制
]]
local toBeSentMsg = {}
-- 上传traccar接口
local function traccar_upload_data(params)
    local url = aprscfg.TRACCAR_HOST .. params
    log.info("TRACCAR_REQ", url)
    local code, headers, body = http.request("GET", url).wait()
    log.info("TRACCAR_RESP", code, (body or ""):sub(1, 120))
    return code
end

sys.taskInit(function()
    sys.waitUntil("CFGLOADED")
    if aprscfg.PLAT == 0 or aprscfg.PLAT == 2 then
        if aprscfg.PLAT ~= 0 then
            sys.publish("LOGGED_IN")
        end
        
        -- 额... http需要在task中运行
        while true do 
            sys.waitUntil("READY_SEND_TRACCAR_MSG")
            if mobile.status() == 1 then
                while #toBeSentMsg > 0 do
                    log.info("SEND_TRACCAR_MSG", "pending", #toBeSentMsg)
                    local code = traccar_upload_data(toBeSentMsg[1])
                    if code == 200 then
                        log.info("SEND_TRACCAR_MSG", toBeSentMsg[1].." 成功")
                    else
                        log.warn("SEND_TRACCAR_MSG", toBeSentMsg[1].." 失败")
                    end
                    table.remove(toBeSentMsg, 1)
                    sys.wait(500)
                end 
            end
        end
    end
end)

-- 有消息来就发送
sys.subscribe("SEND_TRACCAR_MSG", function(msg)
    log.info("SEND_TRACCAR_MSG", "enqueue", #toBeSentMsg, msg)
    table.insert(toBeSentMsg, msg)
    if #toBeSentMsg > 5 then
        table.remove(toBeSentMsg, 1)
    end
    sys.publish("READY_SEND_TRACCAR_MSG")
end)
