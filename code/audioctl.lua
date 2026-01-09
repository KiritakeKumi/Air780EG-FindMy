--[[
    Aprs4G by BG2LBF - 音频管理
]]
local audioTable = {}
local audioEnable = 1
local audioPlaying = false
local audioRecing = false

local i2c_id = 0
local i2s_id = 0

-- es8311器件地址
local es8311_address = 0x18
local record_cnt = 0
-- es8311初始化寄存器配置
local es8311_reg = {
	{0x45,0x00},
	{0x01,0x30},
	{0x02,0x10},
	{0x02,0x00},
	{0x03,0x10},
	{0x16,0x24},
	{0x04,0x20},
	{0x05,0x00},
	{0x06,3},
	{0x07,0x00},
	{0x08,0xFF},
	{0x09,0x0C},
	{0x0A,0x0C},
	{0x0B,0x00},
	{0x0C,0x00},
	{0x10,0x03},
	{0x11,0x7F},
	{0x00,0x80},
	{0x0D,0x01},
	{0x01,0x3F},
	{0x14,0x1a},
	{0x12,0x28},
	{0x13,0x00},
	{0x0E,0x02},
	{0x0F,0x00},
	{0x15,0x00},
	{0x1B,0x0A},
	{0x1C,0x6A},
	{0x37,0x48},
	{0x44,(0 <<7)},
	{0x17,210},
	{0x32,200},
}

-- i2s数据接收buffer
local rx_buff = zbuff.create(3200)

-- amr数据存放buffer，尽可能地给大一些，对于MR475编码等级来说，一秒文件大小为0.6k左右，理论上录音五秒需要的空间为5 * 0.6 = 3k， 这里尽可能给大一点
local amr_buff = zbuff.create(5 * 1024)

--创建一个amr的encoder
local encoder = codec.create(codec.AMR, false)


-- 录音文件路径
local recordPath = "/record.amr"

-- i2s数据接收回调
local function record_cb(id, buff)
    if buff then
        log.info("I2S", id, "接收了", rx_buff:used())
        log.info("编码结果", codec.encode(encoder, rx_buff, amr_buff))		-- 对录音数据进行amr编码，成功的话这个接口会返回true, 默认编码等级为MR475
		record_cnt = record_cnt + 1
		if record_cnt >= 25 then	--超过5秒后停止
			log.info("I2S", "stop") 
			i2s.stop(i2s_id)
		end
    end
end
-- 上送录音文件
function uploadAudioFile()
	local boundary = "----WebKitFormBoundary"..os.time()
	local req_headers = {
		["Content-Type"] = "multipart/form-data; boundary="..boundary,
	}
	local body = {}
	table.insert(body, "--"..boundary.."\r\nContent-Disposition: form-data; name=\"file\"; filename=\"rec.amr\"\r\nContent-Type: audio/mpeg\r\n\r\n")
	table.insert(body, io.readFile(recordPath))
    table.insert(body, "\r\n")
	table.insert(body, "--"..boundary.."--\r\n")
    body = table.concat(body)
    log.info("headers: ", "\r\n" .. json.encode(req_headers), type(body))
    log.info("body: " .. body:len())
    local code, headers, body = http.request("POST", aprscfg.WEBCMD_HOST.."upload", req_headers, body ).wait()   
	log.info("http.post", code, headers, body)
	if code == 200 then
		local rs = json.decode(body)
		if rs.retCode == "0000" then
			local sData = {
				type = "audio",
				data = aprscfg.WEBCMD_HOST.."download/"..rs.body,
				from = mobile.imei() 
			}
			table.insert(sData, "\r\n")
			sys.publish("MQTT_PUBLISH_MSG", aprscfg.TALK_CHANNEL, json.encode(sData), 1)
		end

	end
end
-- 录音
local function record_task()
	os.remove(recordPath)
	i2s.setup(i2s_id, 0, 8000, 16, 2, i2s.MODE_I2S)			-- 开启i2s
    i2s.on(i2s_id, record_cb) 								-- 注册i2s接收回调
    i2s.recv(i2s_id, rx_buff, 3200)
	i2c.send(i2c_id, es8311_address, {0x00, 0xc0}, 1)
    sys.wait(6000)
    i2c.send(i2c_id, es8311_address, {0x00, 0x80}, 1)			-- ES8311停止录音
    log.info("录音5秒结束")
	log.info("i2c amr_buff", amr_buff:used())
	io.writeFile(recordPath, "#!AMR\n")					-- 向文件写入amr文件标识数据
	io.writeFile(recordPath, amr_buff:query(), "a+b")	-- 向文件写入编码后的amr数据
	
	audioRecing = false
	sys.publish("AUDIO_TALK_END")
	rx_buff = zbuff.create(3200)
	amr_buff = zbuff.create(5 * 1024)
	record_cnt = 0
end

-- 音频准备
local function initAudio()
	audio.config(0, 25, 1, 6, 200)
	pm.power(pm.DAC_EN, true)
	i2c.setup(i2c_id, i2c.FAST)
	for i, v in pairs(es8311_reg) do					-- 初始化es8311
        i2c.send(i2c_id, es8311_address, v, 1)
    end
	i2s.setup(i2s_id, 0, 0, 0, 0, i2s.MODE_MSB)
	audio.vol(0, aprscfg.AUDIO_VOL)
end

local function playAudio(audioPath)
	if audioEnable == 1 then
		audioPlaying = true
		initAudio()
		audio.play(0, audioPath)
	end
end

audio.on(0, function(id, event)
	--使用play来播放文件时只有播放完成回调
	local succ,stop,file_cnt = audio.getError(0)
	if not succ then
		if stop then
			log.info("用户停止播放")
		else
			log.info("第", file_cnt, "个文件解码失败")
		end
	end
	log.info("播放完成一个音频")
	
	if audioRecing then
		-- 开始录音
		audioPlaying = false
		sys.publish("REC_AUDIO_START")
	else 
		sys.publish("AUDIO_PLAY_DONE")
	end
end)
-- 获取音频权限标志
function getCharacter(text, index)
    if index >= 1 and index <= #text then
        return text:sub(index, index)
    else
        return nil
    end
end
-- 音频播放完毕
sys.subscribe("AUDIO_PLAY_DONE", function()
	-- i2c.send(i2c_id, es8311_address, {0x0D, 0xFC}, 1)
	-- i2c.send(i2c_id, es8311_address, {0x00, 0x1F}, 1)
	i2c.send(i2c_id, es8311_address, {0x12, 0x02}, 1)
	i2c.send(i2c_id, es8311_address, {0x0E, 0xC2}, 1)
    pm.power(pm.DAC_EN, false)
	audioPlaying = false
	sys.publish("AUDIO_PLAY_NEXT")
end)
-- 开机音频
sys.subscribe("AUDIO_POWER_ON", function()
	if getCharacter(aprscfg.AUDIO_VOICE_PROMPT, 1) == "1" then
		table.insert(audioTable, "AUDIO_POWER_ON")
		sys.publish("AUDIO_PLAY_NEXT")
	end
end)
-- 关机音频
sys.subscribe("AUDIO_POWER_OFF", function()
	if getCharacter(aprscfg.AUDIO_VOICE_PROMPT, 2) == "1" then
		table.insert(audioTable, "AUDIO_POWER_OFF")
		if not audioPlaying then
			sys.publish("AUDIO_PLAY_NEXT")
		end
	end
end)
-- 发射音频
sys.subscribe("AUDIO_SEND_APRS", function()
	if getCharacter(aprscfg.AUDIO_VOICE_PROMPT, 3) == "1" then
		if not audioPlaying then
			table.insert(audioTable, "AUDIO_SEND_APRS")
			sys.publish("AUDIO_PLAY_NEXT")
		end
	end
end)
-- 讲话提示音频
sys.subscribe("AUDIO_TALK_START", function()
	if getCharacter(aprscfg.AUDIO_VOICE_PROMPT, 4) == "1" then
		if not audioPlaying then
			table.insert(audioTable, "AUDIO_TALK_START")
			sys.publish("AUDIO_PLAY_NEXT")
		end
	end
end)
-- 讲话结束提示音频
sys.subscribe("AUDIO_TALK_END", function()
	if getCharacter(aprscfg.AUDIO_VOICE_PROMPT, 5) == "1" then
		if not audioPlaying then
			table.insert(audioTable, "AUDIO_TALK_END")
			sys.publish("AUDIO_PLAY_NEXT")
		end
	end
end)
-- 定位音频
sys.subscribe("AUDIO_GPS_PIN", function()
	if getCharacter(aprscfg.AUDIO_VOICE_PROMPT, 6) == "1" then
		table.insert(audioTable, "AUDIO_GPS_PIN")
		sys.publish("AUDIO_PLAY_NEXT")
	end
end)
-- 定位丢失音频
sys.subscribe("AUDIO_GPS_UNPIN", function()
	if getCharacter(aprscfg.AUDIO_VOICE_PROMPT, 7) == "1" then
		table.insert(audioTable, "AUDIO_GPS_UNPIN")
		sys.publish("AUDIO_PLAY_NEXT")
	end
end)
-- 电量低音频
sys.subscribe("AUDIO_POWER_LOW", function()
	if getCharacter(aprscfg.AUDIO_VOICE_PROMPT, 8) == "1" then
		table.insert(audioTable, "AUDIO_POWER_LOW")
		sys.publish("AUDIO_PLAY_NEXT")
	end
end)
-- 播放语音消息
sys.subscribe("AUDIO_ONLINE_MSG", function()
    table.insert(audioTable, "AUDIO_ONLINE_MSG")
	sys.publish("AUDIO_PLAY_NEXT")
end)
-- 开始录音
sys.subscribe("REC_AUDIO_START", function()
    table.insert(audioTable, "REC_AUDIO_START")
	sys.publish("AUDIO_PLAY_NEXT")
end)

sys.taskInit(function()

	if fskv.init() then
        log.info("fskv", "init complete")
		if fskv.get("AUDIO_ENABLE") ~= nil then
            audioEnable = fskv.get("AUDIO_ENABLE")
			log.info("audioEnable", audioEnable)
        end
	end

	

	if DEV_TYPE == "air700" then

	elseif DEV_TYPE == "air780e" then
	
	elseif DEV_TYPE == "air780eg" then
		local reason, slp_state, reset_reason = pm.lastReson()
		log.info("wakeup state", reason, slp_state, reset_reason)
		if reason == 0 and slp_state == 0 and reset_reason == 0 then
			table.insert(audioTable, "AUDIO_POWER_ON") -- 只有正常开机的情况才插入开机音
			-- table.insert(audioTable, "AUDIO_POWER_ON")
		end
		while true do
			if #audioTable > 0 then
				if audioTable[1] == "AUDIO_POWER_ON" then
					playAudio("/luadb/pin.mp3")
					sys.wait(1000) -- 首次音频音量小的无奈之举
					audioPlaying = true
					playAudio("/luadb/kj.mp3")
				elseif audioTable[1] == "AUDIO_POWER_OFF" then
					playAudio("/luadb/gj.mp3")
				elseif audioTable[1] == "AUDIO_SEND_APRS" then
					playAudio("/luadb/fs.mp3")
				elseif audioTable[1] == "AUDIO_GPS_PIN" then
					playAudio("/luadb/pin.mp3")
				elseif audioTable[1] == "AUDIO_GPS_UNPIN" then
					playAudio("/luadb/unpin.mp3")
				elseif audioTable[1] == "AUDIO_POWER_LOW" then
					playAudio("/luadb/pwlow.mp3")
				elseif audioTable[1] == "AUDIO_ONLINE_MSG" then
					playAudio("/msg.amr")
				elseif audioTable[1] == "AUDIO_TALK_START" then
					playAudio("/luadb/rec.mp3")
					audioRecing = true
				elseif audioTable[1] == "AUDIO_TALK_END" then
					playAudio("/luadb/recdone.mp3")
					uploadAudioFile()
				elseif audioTable[1] == "REC_AUDIO_START" then
					record_task()
				end
				-- table.remove(audioTable, 1)
				audioTable = {}
			end
			sys.waitUntil("AUDIO_PLAY_NEXT", 60000)
		end
	elseif DEV_TYPE == "air780eg-yed" then

	end
    
end)
