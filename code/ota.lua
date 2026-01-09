--[[
    Aprs4G by BG2LBF - OTA升级配置
]]
local libfota = require("libfota")
local libnet = require("libnet")

-- ota成功后重启
function fota_cb(ret)
    log.info("fota", ret)
    if ret == 0 then
        rtos.reboot()
    end
end

-- 使用合宙iot平台进行升级
libfota.request(fota_cb)
sys.timerLoopStart(libfota.request, 3600000, fota_cb)
