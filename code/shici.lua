--[[
    Aprs4G by BG2LBF - 古诗词API- 定期更换古诗词
]]

SHICI_MSG_CONTENT = ""      -- 古诗词 诗句
SHICI_MSG_TITLE = ""        -- 古诗词 标题
SHICI_MSG_AUTHOR = ""       -- 古诗词 作者
local refreshTime = 3600    -- 每小时更换
local lastTime = 0

-- 查询古诗词
local function query_shici_data()
    if mobile.status() == 1 and refreshTime <= os.time() - lastTime then
        lastTime = os.time()
        local code, headers, body = http.request("GET", "https://v1.jinrishici.com/"..aprscfg.SHICI_TYPE..".json").wait()
        log.info("shici", code )
        log.info("shici", body )
        if code == 200 then
            local obj, result, err = json.decode(body)
            log.info("shici", result )
            if result == 1 then
                SHICI_MSG_CONTENT = obj.content
                SHICI_MSG_TITLE = obj.origin
                SHICI_MSG_AUTHOR = obj.author
            end
        end
    end
end

sys.taskInit(function()
    sys.waitUntil("CFGLOADED")
    local found = string.find(aprscfg.BEACON, "${shici_")
    local found2 = string.find(aprscfg.BEACON_TEXT, "${shici_")
    while found or found2 do
        query_shici_data()
        sys.wait(300*1000)
    end
end)