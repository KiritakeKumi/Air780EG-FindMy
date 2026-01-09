--[[
    Aprs4G by BG2LBF - 设备姿态检测 - 静止省电模式
]]
local lastMotTime = 0           -- 上一次运动时间戳
local threshold = 0.05          -- 判断是否静止的阈值越小越敏感
local staticTable = {}
local i2c_id = 0
local int_pin = 20
local x = {}
local y = {}
local z = {}

local QMA7981_ADDR = 0x12 --< Slave address of the QMA7981 */
local QMA7981_WHO_AM_I_REG_ADDR = 0x00 --< Register addresses of the "who am I" register */
local QMA7981_PWR_MGMT_1_REG_ADDR = 0x11 --< Register addresses of the power managment register */

local QMA7981_DXM = 0x01  --QMA7981寄存器X轴加速度地址
local QMA7981_DYM = 0x03  --QMA7981寄存器Y轴加速度地址
local QMA7981_DZM = 0x05  --QMA7981寄存器Z轴加速度地址

local QMA7981_start_INT_EN0_cmd = 0x16  --设置中断
local QMA7981_start_INT_EN1_cmd = 0x17  --设置中断
local QMA7981_start_INT_EN2_cmd = 0x18  --设置中断
local QMA7981_start_INT_MAP0_cmd = 0x19  --设置中断
local QMA7981_start_INT_MAP1_cmd = 0x1a  --设置中断
local QMA7981_start_INT_MAP2_cmd = 0x1b  --设置中断
local QMA7981_start_INT_MAP3_cmd = 0x1c  --设置中断
local QMA7981_start_MOT_CONF0_cmd = 0x2c  --设置运动参数
local QMA7981_start_MOT_CONF2_cmd = 0x2e  --设置运动参数

local QMA7981_start_convert_cmd = 0xC0  --设置QMA7981为active模式的指令
local QMA7981_ANY_MOT_EN_cmd = 0x07  --设置QMA7981为active模式的指令
local QMA7981_INT1_ANY_MOT_cmd = 0x01  --设置运动中断
local QMA7981_ANY_MOT_DUR_cmd = 0x02  --设置运动中断条件
local QMA7981_ANY_MOT_TH_cmd = 0x10  --设置运动中断条件
local QMA7981_MAX_VALUE = 0x1FFF  --满量程读数
--读取数值
local function readAccelData(reg)
    local data = i2c.readReg(i2c_id, QMA7981_ADDR, reg, 2)
    local low = string.byte(data, 1)
    local high = string.byte(data, 2)
    --log.info("Debug:", data:toHex(),(bit.bor(bit.band(low, 0xFC), bit.lshift(high, 8))))
    return (low ~= nil and high ~= nil) and bit.bor(bit.band(low, 0xFC), bit.lshift(high, 8)) or 0.001
end
-- 初始化传感器
local function initAttitude()
    log.info("i2c initial",i2c.setup(i2c_id, i2c.FAST))
    local data = i2c.readReg(i2c_id, QMA7981_ADDR, QMA7981_WHO_AM_I_REG_ADDR, 1)
    log.info("QMA7981_WHO_AM_I_REG_ADDR", data:toHex())
    i2c.writeReg(i2c_id, QMA7981_ADDR, QMA7981_start_INT_EN2_cmd,string.char(QMA7981_ANY_MOT_EN_cmd) )
    sys.wait(100)
    i2c.writeReg(i2c_id, QMA7981_ADDR, QMA7981_start_INT_MAP1_cmd,string.char(QMA7981_INT1_ANY_MOT_cmd) )
    sys.wait(100)
    i2c.writeReg(i2c_id, QMA7981_ADDR, QMA7981_start_MOT_CONF0_cmd,string.char(QMA7981_ANY_MOT_DUR_cmd) )
    sys.wait(100)
    i2c.writeReg(i2c_id, QMA7981_ADDR, QMA7981_start_MOT_CONF2_cmd,string.char(QMA7981_ANY_MOT_TH_cmd) )
    sys.wait(100)
    i2c.writeReg(i2c_id, QMA7981_ADDR, QMA7981_PWR_MGMT_1_REG_ADDR,string.char(QMA7981_start_convert_cmd) )
end
-- 判断是否为静态状态
local function isStatic(x, y, z, threshold)
    local sum = 0
    local count = #x
    for i = 1, count do
        sum = sum + math.abs(x[i] - x[1]) + math.abs(y[i] - y[1]) + math.abs(z[i] - z[1])
    end
    local average = sum / (count * 3)
    local isS = average <= threshold
    log.info("isStatic:",average," - ",threshold, " - ", isS and "静止状态" or "活动状态")
    return isS
end
-- 判断近期是否静态
local function checkHasStatic()  
    local ocount = 0
    for _, value in ipairs(staticTable) do 
        if value == 1 then
            ocount = ocount + 1  
        end
    end
    if ocount == 0 then
        return 0
    elseif ocount == #staticTable then
        return 1
    else
        return 0
    end  
end

sys.taskInit(function()
    sys.waitUntil("CFGLOADED")
    if DEV_TYPE == "air700" then
        i2c_id = 1
        threshold = 0.04
    elseif DEV_TYPE == "air780e" then
        i2c_id = 0
    elseif DEV_TYPE == "air780eg" then
        i2c_id = 0
        threshold = 0.03
        int_pin = 20
    elseif DEV_TYPE == "air780eg-yed" then
        i2c_id = 0
        threshold = 0.03
        return
    end

    initAttitude()

    lastMotTime = os.time()
    gpio.setup(int_pin, function(val) 
        log.info("发生震动", val)
        if aprscfg.LOCMODE == 3 then
            -- MIX_LOC
            MIX_ResetDecay()
        end
        
        if 2 < os.time() - lastMotTime then
            lastMotTime = os.time()
        end
    end, gpio.PULLDOWN, gpio.RISING)

    while true do
        if lastMotTime ~= 0 and (os.time() - lastMotTime) > aprscfg.POWER_SAVE_MODE_TIME then
            lastMotTime = 0
            sys.publish("STATIC_STATE")
            log.info("STATIC_STATE", "近期静止状态")
        end
        sys.wait(5000)
    end
    -- while true and NO_ATTITUDE ~= true do
    --     local XA = readAccelData(QMA7981_DXM) / 4
    --     local YA = readAccelData(QMA7981_DYM) / 4
    --     local ZA = readAccelData(QMA7981_DZM) / 4
    --     local X_AXIS_A = string.format("%04.1f", (XA / QMA7981_MAX_VALUE * 2))
    --     local Y_AXIS_A = string.format("%04.1f", (YA / QMA7981_MAX_VALUE * 2))
    --     local Z_AXIS_A = string.format("%04.1f", (ZA / QMA7981_MAX_VALUE * 2))
    --     -- log.info("i2c  data ",X_AXIS_A,Y_AXIS_A,Z_AXIS_A)
    --     table.insert(x, tonumber(X_AXIS_A))
    --     table.insert(y, tonumber(Y_AXIS_A))
    --     table.insert(z, tonumber(Z_AXIS_A))
    --     sys.wait(200)
    -- end
    
end)

-- sys.taskInit(function()
--     sys.waitUntil("CFGLOADED")
--     if DEV_TYPE == "air780eg-yed" then
--         return
--     end
    -- while true and NO_ATTITUDE ~= true do
    --     if #x > 0 then
    --         local isStaticState = isStatic(x, y, z, threshold)
    --         if isStaticState then
    --             STATIC_STATE = 1
    --         else
    --             STATIC_STATE = 0
    --         end
    --         table.insert(staticTable, STATIC_STATE)
    --         x = {}
    --         y = {}
    --         z = {}
            
    --         -- log.info("staticDataSize", staticDataSize, " - ", #staticTable)
    --         -- 最近一分钟（staticDataSize次）内，是否且为静止
    --         if #staticTable >= staticDataSize then
    --             local hasStatic = checkHasStatic()
    --             if hasStatic ~= LAST1MINS_STATIC_STATE then
    --                 LAST1MINS_STATIC_STATE = hasStatic
    --                 sys.publish("LAST1MINS_STATIC_STATE")
    --             end
    --             log.info(LAST1MINS_STATIC_STATE == 1 and "近期静止状态" or "近期活动状态")
    --             if isHIB then
    --                 if aprscfg.POWER_SAVE_MODE == 2 then
    --                     if LAST1MINS_STATIC_STATE == 0 then
    --                         pm.reboot()
    --                     end 
    --                 end
    --             end
    --             table.remove(staticTable, 1)
    --         end
    --     end
        
    --     sys.wait(10000)
    -- end
-- end)