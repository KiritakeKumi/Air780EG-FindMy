--[[
    Aprs4G by BG2LBF - 读取电压、温度
]]

-- 芯片温度
ADC_CPU_TEMP = "0"
-- 核心电压
ADC_CPU_VOL = "0"
-- 电源电压
ADC_POWER_VOL = "0"

local divCPU = 1
local mulPOW = 0.035
if DEV_TYPE == "air700" then
	divCPU = 1
	mulPOW = 0.035
elseif DEV_TYPE == "air780e" then
	divCPU = 1000
	mulPOW = 0
elseif DEV_TYPE == "air780eg" then
	divCPU = 1000
	mulPOW = 0
elseif DEV_TYPE == "air780eg-yed" then
	divCPU = 1000
	mulPOW = 0.081
end

-- 读取数值
local function readADC()
	local cputemp,cpuvol,powervol
	if adc.open(adc.CH_CPU) then
		cputemp = string.format("%02.0f",(adc.get(adc.CH_CPU)/divCPU))
	end
	adc.close(adc.CH_CPU)

	if adc.open(adc.CH_VBAT) then
		cpuvol = string.format("%02.1f",adc.get(adc.CH_VBAT)/1000)
	end
	adc.close(adc.CH_VBAT)

	if adc.open(1) then	
		local a = adc.get(1)
		log.info("ADC",string.format("%02.4f",a))
		powervol = string.format("%02.1f",(a*mulPOW))
	end
	adc.close(1)

	return cputemp,cpuvol,powervol
end

sys.taskInit(function()
    while true do
        local cputemp,cpuvol,powervol = readADC()
        log.info("ADC", "cputemp："..cputemp.."°C", "cpuvol："..cpuvol.."V", "powervol："..powervol.."V")
		ADC_CPU_TEMP = cputemp.."°C"
		ADC_CPU_VOL = cpuvol.."V"
		ADC_POWER_VOL = powervol.."V"
        sys.wait(60000)
    end
end)