--[[
    Aprs4G by BG2LBF - 主文件
]]
PROJECT = "Air780EGFindMy"
VERSION = "1.0.0"
PRODUCT_KEY = ""    -- 该产品key是air700f定位器升级使用，非该型号请务必修改

log.info("main", PROJECT, VERSION, mobile.imei())


_G.sys = require("sys")
_G.sysplus = require("sysplus")
-- require "ota" -- 暂停 OTA 功能
require "cfg"
require "wdts"
require "led"
require "adcs"
require "audioctl"
require "powerctl"
require "webcmd"
require "smscmd"
require "nets"
require "traccar"
require "lbs"
require "pos"
require "posfix"
require "msg"
require "attitude"
require "timedstart"
require "shici"
require "mqtts"
require "mixloc"

-- mobile.simid(0)  -- 切换sim卡

-- 用户代码已结束---------------------------------------------
-- 结尾总是这一句
sys.run()
-- sys.run()之后后面不要加任何语句!!!!!
