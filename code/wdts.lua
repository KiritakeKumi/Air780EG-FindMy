--[[
    Aprs4G by BG2LBF - 看门狗 ？ 
]]
if DEV_TYPE == "air780eg-yed" then
    require 'air153C_wtd'
else

end


sys.taskInit(function()

    if DEV_TYPE == "air780eg-yed" then
        air153C_wtd.init(28)
        air153C_wtd.feed_dog(28)--模块开机第一步需要喂狗一次
        sys.wait(3000)--此处延时3s，防止1s内喂狗2次导致进入测试模式
        --喂狗
        log.info("WTD","eatdog start!")
        while 1 do
            air153C_wtd.feed_dog(28)--28为看门狗控制引脚
            log.info("main","feed dog")
            sys.wait(150000)
        end
    else
        if wdt then
            if wdt == nil then
                -- 没有就不添加
                sys.wait(1000)
                log.warn("wdt", "this app need wdt lib")
            else
                log.info("main", "添加看门狗防止程序卡死")
                --添加看门狗防止程序卡死，在支持的设备上启用这个功能
                wdt.init(9000)--初始化watchdog设置为9s
                sys.timerLoopStart(wdt.feed, 4000)--4s喂一次狗
            end
        else
            -- 没有就不添加
            sys.wait(1000)
            log.warn("wdt", "this app need wdt lib")
        end
    end
    
end)
