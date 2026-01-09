--[[
    Aprs4G by BG2LBF - APRS网络控制
]]
httpdns = require "httpdns"

isReady4Send = false
local toBeSentMsg = {}
local netc
local taskName = "netProcess"
local errTimes = 0
local ip = "";



-- 关闭socket
local function closeConn()
    if netc ~= nil then
        socket.close(netc)
        socket.release(netc)
        netc = nil
    end
    isReady4Send = false
    sys.publish("LOGGED_OUT")
end

-- 网络连接管理
local function netProcess()
    if  mobile.status() ~= 1 then
        log.warn("网络", "未就绪，等待网络")
        closeConn()
        return false
    else
        if isReady4Send then 
            -- 已连接 发一个心跳包
            if socket.tx(netc, "#\r\n") then
                return true
            else 
                -- 失败了
                log.warn("closeConn", "4")
                closeConn()
            end
        else
            socket.setDNS(nil, 1, "114.114.114.114")
            sys.wait(1000)
            log.info("mobile.rssi", mobile.rssi())
            log.info("mobile.rsrp", mobile.rsrp())
            log.info("mobile.rsrq", mobile.rsrq())
            local locIp, locMask, locGate = socket.localIP();
            log.info("socket.localIP", locIp)
            if mobile.rssi() == -999 and mobile.rsrp() == -999 and mobile.rsrq() == -999 then
                log.warn("ERROR-999", "-999")
                sys.wait(500)
                pm.reboot()
                return false
            elseif mobile.rssi() > -100 and locIp ~= nil and locIp:len() > 0 then
                local pingCtrl = socket.create(nil, "pingProcess")
                sys.wait(500)
                socket.connect(pingCtrl, "www.baidu.com", 443)
                sys.wait(500)
                local pingIp = socket.remoteIP(pingCtrl)
                log.info("PingRemoteIP", pingIp)
                socket.close(pingCtrl)
                socket.release(pingCtrl)
                sys.wait(200)
                if pingIp == nil then
                    log.info("pingCtrl", "网络异常")
                    if errTimes >= 3 then
                        sys.wait(500)
                        pm.reboot()
                        return false
                    else
                        errTimes = errTimes + 1
                    end
                end
            end
        end 
        socket.setDNS(nil, 1, "114.114.114.114")
        sys.wait(1000)
        netc = socket.create(nil, taskName)
        socket.config(netc)
        socket.debug(netc, false)
        local succ1, result1 = socket.connect(netc, ip, aprscfg.PORT)
        sys.wait(500)
        local ip1,ip2,ip3,ip4 = socket.remoteIP(netc)
        log.info("remoteIP", ip1)
        if not succ1 then
            log.warn("服务器", "连接服务器失败")
            closeConn()
            return false
        end
        errTimes = 0
        sys.wait(500)
        local rx_buff = zbuff.create(1024)
        while not isReady4Send do
            local succw, resultw = socket.wait(netc)
            if succw then
                local result, data_len, ip, port = socket.rx(netc, rx_buff)
                rx_buff:del()
                if result then
                    log.info("服务器", "正在登录...")
                    local dataLogin = string.format("user %s pass %d vers %s %s\r\n", aprscfg.sourceCall, aprscfg.PASSCODE, PROJECT, VERSION)
                    log.info("dataLogin",dataLogin)
                    local succtx, full, resulttx = socket.tx(netc, dataLogin)
                    if succtx then
                        sys.wait(500)
                        local succrx, data_len, ip, port = socket.rx(netc, rx_buff)
                        if succrx then 
                            local data = rx_buff:toStr(0, rx_buff:used())
                            log.info("服务器", "数据:", data)
                            if string.find(data, " verified") then
                                log.info("服务器", "登录已成功")
                                isReady4Send = true
                                sys.publish("LOGGED_IN")
                            elseif string.find(data, "unverified") then
                                    log.warn("服务器", "服务器登录验证失败，请重新确认呼号和验证码")
                                    closeConn()
                            elseif string.find(data, "full") then
                                    log.warn("服务器", "服务器已满")
                                    closeConn();
                            else
                                log.warn("服务器", "未知数据:", data)
                            end
    
                        else
                            log.warn("closeConn", "0")
                            closeConn()
                            break 
                        end
                        
                    else
                        log.warn("closeConn", "1")
                        closeConn()
                        break
                    end
                else
                    log.warn("closeConn", "2")
                    closeConn()
                    break
                end
            else
                log.warn("closeConn", "3")
                closeConn()
                break
            end
        end
    end
end

sys.taskInit(function()
    -- 当配置为 PLAT=2 时跳过 APRS 网络流程，避免无意义的搜索和建链
    if aprscfg.PLAT == 2 then
        log.info("net", "skip aprs net task (PLAT=2)")
        return
    end
    mobile.flymode(0, false)
    sys.waitUntil("CFGLOADED")
    ip = aprscfg.SERVER
    log.info("SERVER:", aprscfg.SERVER)
    local isSearchIp = true
    while isSearchIp do
        ip = httpdns.ali(aprscfg.SERVER)
        if ip ~= nil then
            log.info("aliip:", ip)
            isSearchIp = false
            break
        end
        ip = httpdns.tx(aprscfg.SERVER)
        if ip ~= nil then
            log.info("txip:", ip)
            isSearchIp = false
            break
        end
        log.info("net", "search ip ... ")
        sys.wait(1000)
    end
    errTimes = 0
    if aprscfg.PLAT == 0 or aprscfg.PLAT == 1 then
        while true do
            if not isReady4Send then
                log.info("isReady4Send", isReady4Send)
            end
            sys.wait(200)
            netProcess()
            sys.wait(8000)
        end
    end
end)

-- ??:??????? aprs.tv:80 ??????
sys.taskInit(function()
    sys.waitUntil("CFGFINISH")
    while true do
        local pingCtrl = socket.create(nil, "debugPing")
        socket.connect(pingCtrl, "aprs.tv", 80)
        sys.wait(500)
        local remoteIp = socket.remoteIP(pingCtrl)
        log.info("debugPing", "aprs.tv:80", remoteIp or "nil")
        socket.close(pingCtrl)
        socket.release(pingCtrl)
        sys.wait(60000)
    end
end)
-- 调试：输出一次移动网络基础信息
sys.taskInit(function()
    sys.waitUntil("CFGFINISH")
    log.info("imei", mobile.imei())
    log.info("imsi", mobile.imsi())
    local sn = mobile.sn()
    if sn then
        log.info("sn", sn:toHex())
    end
    log.info("muid", mobile.muid())
    log.info("iccid", mobile.iccid())
    log.info("csq", mobile.csq())
    log.info("rssi", mobile.rssi())
    log.info("rsrq", mobile.rsrq())
    log.info("rsrp", mobile.rsrp())
    log.info("snr", mobile.snr())
    log.info("simid", mobile.simid())
end)

sys.subscribe("SEND_APRS_MSG", function(msg)
    table.insert(toBeSentMsg, msg)
    if #toBeSentMsg > 2 then
        table.remove(toBeSentMsg, 1)
    end
    while #toBeSentMsg > 0 do
        if #toBeSentMsg > 2 then
            table.remove(toBeSentMsg, 1)
        end
        if isReady4Send then
            local succ, full, result = socket.tx(netc, string.format("%s\r\n", toBeSentMsg[1]))
            if succ then
                log.info("SEND_APRS_MSG", toBeSentMsg[1].." 成功")
                table.remove(toBeSentMsg, 1)
            else
                log.warn("SEND_APRS_MSG", toBeSentMsg[1].." 失败")
                table.remove(toBeSentMsg, 1)
                closeConn()
            end
        else
            table.remove(toBeSentMsg, 1)
        end
    end     
    
end)
