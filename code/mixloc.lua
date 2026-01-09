--[[
    Aprs4G by BG2LBF - 混合定位管理
]]
local use_gps_time = 0
local use_lbs_time = 0

local is_first = true

local currentDecayValue = 0     -- 当前衰减值
local decayRate = 2             -- 衰减率为2
local maxDecayTimes = 32        -- 最大衰减倍数
local decayFunc

-- 间隔衰减计算，衰减率为2,最大衰减倍数32
local function calcDecay(initialValue)  
    currentDecayValue = initialValue  
    return function()  
        local oldValue = currentDecayValue  
        if currentDecayValue < initialValue * maxDecayTimes then
            currentDecayValue = currentDecayValue * decayRate              
        end
        return oldValue  
    end  
end 
-- 重置衰减值
function MIX_ResetDecay()
    currentDecayValue = 60
end

sys.taskInit(function()
    sys.waitUntil("LOC_GPS_LBS")
    sys.wait(1000)
    decayFunc = calcDecay(60)
    sys.publish("LOC_GPS")
    while true do
        if use_lbs_time == 0 and use_gps_time == 0 then
            -- 开启GPS搜星
            if is_first then
                is_first = false
            else
                sys.publish("POS_STATE_INITGPS")
            end
            use_gps_time = os.time()
            log.info("MIX_DEBUG","start with GPS", use_gps_time)
            GPS_FIXED = false
        elseif use_lbs_time == 0 and use_gps_time ~= 0 then
            -- GPS中
            if os.time() - use_gps_time > 60 and GPS_FIXED == false then
                -- 使用gps超过60s，未定位 ，则关闭GPS，切换到基站/wifi定位
                log.info("MIX_LOC", "使用gps超过60s，未定位 ，则关闭GPS，切换到基站/wifi定位")
                sys.publish("POS_STATE_CLOSEGPS")
                sys.publish("LOC_LBS")
                sys.publish("POS_STATE_INITLBS")
                use_lbs_time = os.time()
                log.info("MIX_DEBUG","switch to LBS", use_lbs_time)
                use_gps_time = 0
            end
        elseif use_lbs_time ~= 0 and use_gps_time == 0 then
            -- LBS中
            if os.time() - use_lbs_time > currentDecayValue then
                -- 使用基站超过120s，切换回GPS ，关闭基站/wifi定位
                log.info("MIX_LOC", "使用基站超过"..currentDecayValue.."s，切换回GPS ，关闭基站/wifi定位")
                decayFunc()
                sys.publish("POS_STATE_CLOSELBS")
                use_gps_time = 0
                use_lbs_time = 0
            end
        else
            -- 异常情况，重置数据
            log.error("MIX_LOC", "异常情况，重置数据")
            use_gps_time = 0
            use_lbs_time = 0
            GPS_FIXED = false
            MIX_ResetDecay()
            sys.wait(500)
            pm.reboot()
        end

        sys.wait(10000)
    end
end)

sys.subscribe("LOC_GPS_FIXED", function()
    MIX_ResetDecay()
end)

sys.subscribe("LOC_GPS_LOSE", function()
    use_gps_time = os.time()
end)
